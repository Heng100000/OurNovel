import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/widgets/global_loader.dart';
import '../core/models/book.dart' as model;
import '../core/models/author.dart';
import '../core/models/category.dart';
import '../features/home/data/book_service.dart';
import '../features/home/data/author_service.dart';
import '../features/home/data/category_service.dart';
import '../features/wishlist/data/wishlist_provider.dart';
import '../features/menu/presentation/pages/menu_page.dart';
import '../features/cart/data/cart_service.dart';
import '../features/cart/data/cart_provider.dart';
import '../widget/cart_page.dart';
import '../features/home/presentation/pages/book_description_page.dart';
import '../core/constants/app_colors.dart';
import '../features/scanner/modern_scanner_page.dart';
import 'package:toastification/toastification.dart';
import '../core/services/realtime_service.dart';
import '../theme/theme_service.dart';
import '../l10n/language_service.dart';

class BookStorePage extends StatefulWidget {
  final int? initialAuthorId;
  const BookStorePage({super.key, this.initialAuthorId});

  @override
  State<BookStorePage> createState() => _BookStorePageState();
}

class _BookStorePageState extends State<BookStorePage> {
  final BookService _bookService = BookService();
  final AuthorService _authorService = AuthorService();
  final CategoryService _categoryService = CategoryService();
  final CartService _cartService = CartService();

  List<model.Book> _allBooks = [];
  List<Author> _authors = [];
  List<Category> _categories = [];
  
  bool _isLoading = true;
  final Map<int, bool> _addingToCartStatus = {}; // bookId -> isLoading
  int _selectedCategoryIndex = 0; // 0 for "All"
  int? _selectedAuthorId;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedAuthorId = widget.initialAuthorId;
    _loadData();
    RealtimeService().addListener(_onRealtimeUpdate);
  }

  void _onRealtimeUpdate() {
    if (mounted) {
      _bookService.getBooks().then((books) {
        if (mounted) setState(() => _allBooks = books);
      });
      _authorService.getAllAuthors().then((authors) {
        if (mounted) setState(() => _authors = authors);
      });
      _categoryService.getAllCategories().then((categories) {
        if (mounted) setState(() => _categories = categories);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    RealtimeService().removeListener(_onRealtimeUpdate);
    super.dispose();
  }

  void _openScanner(LanguageService langService) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernScannerPage(
          onScan: (code) {
            // Find the book globally
            final matchedBook = _allBooks.where(
              (b) => b.isbn?.toLowerCase() == code.toLowerCase(),
            ).firstOrNull;

            setState(() {
              _searchQuery = code;
              _searchController.text = code;
              
              if (matchedBook != null) {
                // Auto-switch to matched author
                if (matchedBook.authorId != null) {
                  _selectedAuthorId = matchedBook.authorId;
                }
                
                // Auto-switch to matched category
                if (matchedBook.categoryId != null) {
                  final catIndex = _categories.indexWhere((c) => c.id == matchedBook.categoryId);
                  if (catIndex != -1) {
                    _selectedCategoryIndex = catIndex + 1; // +1 because 0 is "All"
                  } else {
                    _selectedCategoryIndex = 0; // Fallback to "All" if category not in list
                  }
                }
              }
            });
            
            if (matchedBook != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(langService.translate('found_book')
                      .replaceFirst('%s', matchedBook.title)
                      .replaceFirst('%s', matchedBook.authorName ?? "Unknown")),
                  backgroundColor: AppColors.primary,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(langService.translate('scanned_isbn_no_match').replaceFirst('%s', code))),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _bookService.getBooks(),
        _authorService.getAllAuthors(),
        _categoryService.getAllCategories(),
      ]);
      
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).fetchCartCount();
      }

      if (mounted) {
        final List<model.Book> books = results[0] as List<model.Book>;
        final List<Author> authorsList = results[1] as List<Author>;
        final List<Category> categoriesList = results[2] as List<Category>;
        
        setState(() {
          _allBooks = books;
          _authors = authorsList;
          _categories = categoriesList;
          
          if (_selectedAuthorId == null && _authors.isNotEmpty) {
            _selectedAuthorId = _authors[0].id;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _loadData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Author? get _selectedAuthor {
    if (_selectedAuthorId == null || _authors.isEmpty) return null;
    try {
      return _authors.firstWhere((a) => a.id == _selectedAuthorId);
    } catch (_) {
      return null;
    }
  }

  List<Category> get _filteredCategories => _categories;

  List<model.Book> get _filteredBooks {
    // When user is searching, search across ALL books regardless of selected author
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.trim();
      final queryLower = query.toLowerCase();

      bool matchText(String? text) {
        if (text == null || text.isEmpty) return false;
        // Direct contains check (works for Khmer Unicode)
        if (text.contains(query)) return true;
        // Case-insensitive for Latin/ASCII text
        return text.toLowerCase().contains(queryLower);
      }

      return _allBooks.where((book) {
        return matchText(book.title) ||
            matchText(book.authorName) ||
            matchText(book.isbn);
      }).toList();
    }

    // No search query — filter by selected author and category as before
    if (_selectedAuthorId == null) return [];

    final filteredByAuthor = _allBooks.where((book) => book.authorId == _selectedAuthorId).toList();

    List<model.Book> result;
    if (_selectedCategoryIndex == 0) {
      result = filteredByAuthor;
    } else {
      final currentFilteredCategories = _filteredCategories;
      if (_selectedCategoryIndex > currentFilteredCategories.length) {
        result = filteredByAuthor;
      } else {
        final categoryId = currentFilteredCategories[_selectedCategoryIndex - 1].id;
        result = filteredByAuthor.where((book) => book.categoryId == categoryId).toList();
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, langService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);

        return Scaffold(
          backgroundColor: bgColor,
          drawer: const SideMenuDrawer(),
          body: _isLoading 
            ? const Center(child: GlobalLoader(size: 80))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _buildSliverHeader(context, isDark, langService),
                    
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildAuthorScroll(isDark),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                    
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildSelectedAuthorSection(isDark, langService),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),

                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CategoryHeaderDelegate(
                        child: Container(
                          color: bgColor,
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildCategoryTabs(isDark, langService),
                        ),
                      ),
                    ),
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle(langService.translate('book_list'), isDark, horizontalPadding: 0),
                            Text(
                              langService.translate('total_titles')
                                  .replaceFirst('%s', _filteredBooks.length.toString())
                                  .replaceFirst('%s', _allBooks.length.toString()),
                              style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: _filteredBooks.isEmpty 
                        ? SliverToBoxAdapter(child: _buildEmptyState(isDark, langService))
                        : SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.52, // Increased again to further reduce image height
                        crossAxisSpacing: 8,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildBookCard(_filteredBooks[index], isDark, langService),
                              childCount: _filteredBooks.length,
                            ),
                          ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildSliverHeader(BuildContext context, bool isDark, LanguageService langService) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildPremiumHeaderContent(context, isDark, langService),
      ),
    );
  }

  Widget _buildPremiumHeaderContent(BuildContext context, bool isDark, LanguageService langService) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [const Color(0xFF1A2410), const Color(0xFF2D3A1D)] 
              : [AppColors.primary, const Color(0xFF4A5D2B)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu, color: Colors.white, size: 22),
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                Text(
                  langService.translate('book_store_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CartPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                color: Colors.white, size: 22),
                            if (cartProvider.itemCount > 0)
                              Positioned(
                                right: -5,
                                top: -5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    cartProvider.itemCount > 99
                                        ? '99+'
                                        : cartProvider.itemCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: langService.translate('search_books_authors'),
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: isDark ? AppColors.primary : AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.barcode_reader, color: isDark ? AppColors.primary : AppColors.primary),
                    onPressed: () => _openScanner(langService),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, LanguageService langService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60, bottom: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_book_rounded, size: 70, color: isDark ? Colors.white10 : Colors.grey[300]),
            ),
            const SizedBox(height: 25),
            Text(
              langService.translate('no_books_yet'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                langService.translate('author_no_books_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark, {double horizontalPadding = 20}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildAuthorScroll(bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _authors.length,
        itemBuilder: (context, index) {
          return _buildAuthorItem(_authors[index], _authors[index].name, isDark);
        },
      ),
    );
  }

  Widget _buildAuthorItem(Author author, String name, bool isDark) {
    bool isSelected = _selectedAuthorId == author.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAuthorId = author.id;
          _selectedCategoryIndex = 0;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: author.profileImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: author.profileImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                        child: const Center(child: GlobalLoader(size: 20)),
                      ),
                      errorWidget: (context, url, error) => _buildDefaultAvatar(name),
                    )
                  : _buildDefaultAvatar(name),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAuthorSection(bool isDark, LanguageService langService) {
    final author = _selectedAuthor;
    if (author == null) return const SizedBox.shrink();

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: author.profileImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: author.profileImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                        child: const Center(child: GlobalLoader(size: 20)),
                      ),
                      errorWidget: (context, url, error) => _buildDefaultAvatar(author.name),
                    )
                  : _buildDefaultAvatar(author.name),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    author.bio ?? (langService.currentLanguage == 'kh' ? "អ្នកនិពន្ធល្បីប្រចាំហាង សៀវភៅមានគុណភាព និងចំណេះដឹង។" : "Famous author of our store, providing quality books and knowledge."),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      langService.translate('featured_author'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : "?",
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDark, LanguageService langService) {
    final filteredCats = _filteredCategories;
    
    return SizedBox(
      height: 42,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filteredCats.length + 1,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategoryIndex == index;
          String name = index == 0 ? langService.translate('all') : filteredCats[index - 1].name;
          
          final itemBg = isDark ? (isSelected ? AppColors.primary : const Color(0xFF1A1A1A)) : (isSelected ? AppColors.primary : Colors.white);
          final itemText = isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey[600]);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
                border: Border.all(
                  color: isSelected ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                ),
              ),
              child: Center(
                child: Text(
                  name,
                  style: TextStyle(
                    color: itemText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildBookCard(model.Book book, bool isDark, LanguageService langService) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDescriptionPage(book: book),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: CachedNetworkImage(
                      imageUrl: book.displayImage,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                        child: const Center(child: GlobalLoader(size: 20)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                        child: Icon(Icons.book, color: isDark ? Colors.white10 : Colors.grey, size: 20),
                      ),
                    ),
                  ),
                  if (book.condition != null && book.condition!.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getConditionColor(book.condition!),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          book.condition!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (book.isPopular || (book.condition?.toLowerCase() == 'popular'))
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Consumer<WishlistProvider>(
                        builder: (context, wishlist, _) {
                          bool isFav = wishlist.isWishlisted(book.id);
                          return GestureDetector(
                            onTap: () => wishlist.toggleWishlist(book),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? Colors.red : Colors.grey,
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF2E7D32),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.authorName ?? 'Unknown Author',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  _buildStaticStars(book),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "\$${book.price}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Color(0xFF5A7336),
                            ),
                          ),
                          if (book.oldPrice != null) 
                            Text(
                              "\$${book.oldPrice}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _addToCart(book, langService),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryLight, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: _addingToCartStatus[book.id] == true
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(model.Book book, LanguageService langService) async {
    if (_addingToCartStatus[book.id] == true) return;

    setState(() {
      _addingToCartStatus[book.id] = true;
    });

    final error = await _cartService.addToCart(book.id);

    if (mounted) {
      setState(() {
        _addingToCartStatus[book.id] = false;
      });

      if (error == null) {
        if (mounted) {
          Provider.of<CartProvider>(context, listen: false).fetchCartCount();
        }
        
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          title: Text(langService.translate('success')),
          description: Text(langService.translate('added_to_cart').replaceFirst('%s', book.title)),
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.topRight,
        );
      } else {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Error'),
          description: Text(error),
          autoCloseDuration: const Duration(seconds: 4),
          alignment: Alignment.topRight,
        );
      }
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'popular':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStaticStars(model.Book book, {double size = 12}) {
    final double ratingToDisplay = (book.userRating != null)
        ? book.userRating!.toDouble()
        : (book.averageRating ?? 0.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < ratingToDisplay;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            isFilled ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFilled ? Colors.amber : Colors.grey.shade300,
            size: size,
          ),
        );
      }),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 52;

  @override
  double get minExtent => 52;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
