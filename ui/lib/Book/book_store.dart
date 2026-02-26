import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../widget/home_screen.dart';
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

class BookStorePage extends StatefulWidget {
  const BookStorePage({super.key});

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
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openScanner() {
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
                  content: Text('Found: ${matchedBook.title} by ${matchedBook.authorName ?? "Unknown"}'),
                  backgroundColor: AppColors.primary,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Scanned ISBN: $code (No match found)')),
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
          
          // Default to first author if none selected and authors available
          if (_selectedAuthorId == null && _authors.isNotEmpty) {
            _selectedAuthorId = _authors[0].id;
          }
          
          _isLoading = false;
        });

        // Debug SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${_allBooks.length} books. Selected Author: $_selectedAuthorId'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        print('Loaded ${_allBooks.length} books, ${_authors.length} authors, ${_categories.length} categories');
      }
    } catch (e) {
      print('Error in _loadData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load data')),
        );
      }
    }
  }

  // Get author by ID
  Author? get _selectedAuthor {
    if (_selectedAuthorId == null || _authors.isEmpty) return null;
    try {
      return _authors.firstWhere((a) => a.id == _selectedAuthorId);
    } catch (_) {
      return null;
    }
  }

  // Show all categories as requested
  List<Category> get _filteredCategories => _categories;

  List<model.Book> get _filteredBooks {
    if (_selectedAuthorId == null) return [];
    
    // 1. Filter by selected author
    final filteredByAuthor = _allBooks.where((book) => book.authorId == _selectedAuthorId).toList();
    
    // 2. Filter by category if one is selected (index 0 is "All")
    if (_selectedCategoryIndex == 0) return filteredByAuthor;
    
    final currentFilteredCategories = _filteredCategories;
    if (_selectedCategoryIndex > currentFilteredCategories.length) {
      return filteredByAuthor;
    }
    
    final categoryId = currentFilteredCategories[_selectedCategoryIndex - 1].id;
    final filteredByCategory = filteredByAuthor.where((book) => book.categoryId == categoryId).toList();

    // 3. Filter by search query (Title, Author, or ISBN)
    if (_searchQuery.isEmpty) return filteredByCategory;

    final query = _searchQuery.toLowerCase();
    return filteredByCategory.where((book) {
      final titleMatch = book.title.toLowerCase().contains(query);
      final authorMatch = book.authorName?.toLowerCase().contains(query) ?? false;
      final isbnMatch = book.isbn?.toLowerCase().contains(query) ?? false;
      return titleMatch || authorMatch || isbnMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: const SideMenuDrawer(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Sticky AppBar (Pinned)
                _buildSliverHeader(context),
                
                // 2. Author Scroll (Scrolls away)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildAuthorScroll(),
                      const SizedBox(height: 5), // Reduced margin
                    ],
                  ),
                ),
                
                // 3. Selected Author Banner (Scrolls away)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSelectedAuthorSection(),
                      const SizedBox(height: 25), // Margin before category tabs
                    ],
                  ),
                ),

                // 5. Sticky Category Tabs (Pinned)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryHeaderDelegate(
                    child: Container(
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildCategoryTabs(),
                    ),
                  ),
                ),
                
                // 6. Book List Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle("បញ្ជីសៀវភៅ", horizontalPadding: 0),
                        Text(
                          "${_filteredBooks.length} / ${_allBooks.length} titles",
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 7. Book Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: _filteredBooks.isEmpty 
                    ? SliverToBoxAdapter(child: _buildEmptyState())
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildBookCard(_filteredBooks[index]),
                          childCount: _filteredBooks.length,
                        ),
                      ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
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
        background: _buildPremiumHeaderContent(context),
      ),
    );
  }

  Widget _buildPremiumHeaderContent(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF4A5D2B)],
        ),
        borderRadius: BorderRadius.only(
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
                const Text(
                  "សៀវភៅក្នុងហាង",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Hanuman',
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "ស្វែងរកសៀវភៅ ឬអ្នកនិពន្ធ...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.barcode_reader, color: AppColors.primary),
                    onPressed: _openScanner,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60, bottom: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_book_rounded, size: 70, color: Colors.grey[300]),
            ),
            const SizedBox(height: 25),
            const Text(
              "មិនមានសៀវភៅនៅឡើយទេ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Hanuman',
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "អ្នកនិពន្ធនេះមិនទាន់មានសៀវភៅនៅក្នុងប្រភេទនេះនៅឡើយទេ។ សូមរង់ចាំការ Update ឆាប់ៗ!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title, {double horizontalPadding = 20}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          fontFamily: 'Hanuman',
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildAuthorScroll() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _authors.length,
        itemBuilder: (context, index) {
          return _buildAuthorItem(_authors[index], _authors[index].name);
        },
      ),
    );
  }

  Widget _buildAuthorItem(Author author, String name) {
    bool isSelected = _selectedAuthorId == author.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAuthorId = author.id;
          _selectedCategoryIndex = 0; // Reset category filter when author changes
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
                    color: Colors.black.withOpacity(0.05),
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
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
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
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAuthorSection() {
    final author = _selectedAuthor;
    if (author == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Square Image
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    author.bio ?? "អ្នកនិពន្ធល្បីប្រចាំហាង សៀវភៅមានគុណភាព និងចំណេះដឹង។",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "អ្នកនិពន្ធឆ្នើម",
                      style: TextStyle(
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

  Widget _buildCategoryTabs() {
    final filteredCats = _filteredCategories;
    
    return SizedBox(
      height: 42,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filteredCats.length + 1,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategoryIndex == index;
          String name = index == 0 ? "All" : filteredCats[index - 1].name;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
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


  Widget _buildBookCard(model.Book book) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: book.displayImage,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.book, color: Colors.grey, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlist, _) {
                        bool isFav = wishlist.isWishlisted(book.id);
                        return GestureDetector(
                          onTap: () => wishlist.toggleWishlist(book),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.grey,
                              size: 12,
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
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "\$${book.price}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          if (book.oldPrice != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              "\$${book.oldPrice}",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[400],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _addToCart(book),
                        child: _addingToCartStatus[book.id] == true
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                Icons.add_shopping_cart,
                                color: AppColors.primary.withOpacity(0.8),
                                size: 14,
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

  Future<void> _addToCart(model.Book book) async {
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
        // Update global cart count
        if (mounted) {
          Provider.of<CartProvider>(context, listen: false).fetchCartCount();
        }
        
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          title: const Text('ជោគជ័យ (Success)'),
          description: Text('បានបន្ថែម "${book.title}" ទៅក្នុងកន្ត្រក'),
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.topRight,
        );
      } else {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('កំហុស (Error)'),
          description: Text(error),
          autoCloseDuration: const Duration(seconds: 4),
          alignment: Alignment.topRight,
        );
      }
    }
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
