import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/global_loader.dart';
import '../../../../core/models/book.dart';
import '../../../cart/data/cart_provider.dart';
import '../../../cart/data/cart_service.dart';
import '../../../wishlist/data/wishlist_provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../widget/cart_page.dart';
import '../../../reviews/data/review_service.dart';
import '../../data/book_service.dart';

class BookDescriptionPage extends StatefulWidget {
  final Book book;

  const BookDescriptionPage({super.key, required this.book});

  @override
  State<BookDescriptionPage> createState() => _BookDescriptionPageState();
}

class _BookDescriptionPageState extends State<BookDescriptionPage> {
  bool _isExpanded = false;
  bool _isAddingToCart = false;
  final CartService _cartService = CartService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _userRating = 0;
  bool _isSubmittingReview = false;
  final ReviewService _reviewService = ReviewService();
  final BookService _bookService = BookService();

  // Current book data (can be refreshed)
  late Book _currentBook;
  bool _isLoadingBook = false;

  // Real-time rating state
  late double _currentAverageRating;
  late int _reviewCount;

  // Related books state
  List<Book> _authorBooks = [];
  List<Book> _newBooks = [];
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _currentAverageRating = _currentBook.averageRating ?? 0.0;
    _reviewCount = _currentBook.reviewCount ?? 0;
    _userRating = _currentBook.userRating ?? 0;
    _refreshBookData();
    _fetchRelatedBooks();
  }

  Future<void> _refreshBookData() async {
    setState(() => _isLoadingBook = true);
    final latestBook = await _bookService.getBookById(_currentBook.id);
    if (mounted && latestBook != null) {
      setState(() {
        _currentBook = latestBook;
        _currentAverageRating = latestBook.averageRating ?? 0.0;
        _reviewCount = latestBook.reviewCount ?? 0;
        _userRating = latestBook.userRating ?? 0;
        _isLoadingBook = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingBook = false);
    }
  }

  Future<void> _fetchRelatedBooks() async {
    final books = await _bookService.getBooks();
    if (mounted) {
      setState(() {
        // Filter for same author (excluding current book)
        if (_currentBook.authorId != null) {
          _authorBooks = books
              .where((b) => b.authorId == _currentBook.authorId && b.id != _currentBook.id)
              .take(10)
              .toList();
        }
        
        // Filter for New arrivals (excluding current book)
        _newBooks = books
            .where((b) => b.condition == 'New' && b.id != _currentBook.id)
            .take(10)
            .toList();
            
        _isLoadingRelated = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = _currentBook;
    final theme = Theme.of(context);
    
    // Use local state for real-time updates
    final displayRating = _currentAverageRating;
    final displayLanguage = book.language ?? "Khmer";
    
    int cartQty = context.watch<CartProvider>().getQuantity(book.id);
    int displayStock = (book.stockQty ?? 0) - cartQty;
    if (displayStock < 0) displayStock = 0;

    final List<BookImage> allImages = book.images ?? [];
    if (allImages.isEmpty && book.displayImage.isNotEmpty) {
      // Fallback if images list is empty but displayImage exists
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Top Background Decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                stretch: true,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF1F2937), size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      return IconButton(
                        icon: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1F2937), size: 20),
                            ),
                            if (cartProvider.itemCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
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
                                    '${cartProvider.itemCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartPage()),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              if (_isLoadingBook)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: GlobalLoader(size: 40),
                  ),
                ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Book Cover Slider
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 320,
                            width: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: allImages.isNotEmpty 
                                ? PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (int page) {
                                      setState(() {
                                        _currentPage = page;
                                      });
                                    },
                                    itemCount: allImages.length,
                                    itemBuilder: (context, index) {
                                      return CachedNetworkImage(
                                        imageUrl: allImages[index].imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(color: Colors.grey[100]),
                                        errorWidget: (context, url, error) => const Icon(Icons.book, size: 50),
                                      );
                                    },
                                  )
                                : CachedNetworkImage(
                                    imageUrl: book.displayImage,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey[100]),
                                    errorWidget: (context, url, error) => const Icon(Icons.book, size: 50),
                                  ),
                            ),
                          ),
                          if (allImages.length > 1) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(allImages.length, (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentPage == index ? 24 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _currentPage == index 
                                      ? AppColors.primary 
                                      : Colors.grey.shade300,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Content Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, -10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Price Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Hanuman',
                                        color: Color(0xFF1F2937),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_pin, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          book.authorName ?? 'Unknown Author',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "\$${book.price}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Stats Row
                          Row(
                            children: [
                              _buildModernStatItem(
                                context,
                                displayRating > 0 ? "${displayRating}" : "0.0", 
                                "Rating ($_reviewCount)",
                                Icons.star_rounded,
                                displayRating > 0 ? Colors.amber : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              _buildModernStatItem(
                                context,
                                displayLanguage,
                                "Language",
                                Icons.language_rounded,
                                Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              _buildModernStatItem(
                                context,
                                "${displayStock}",
                                "Stock",
                                Icons.inventory_2_rounded,
                                Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 35),

                          // Description
                          const Text(
                            "Description",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Hanuman',
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 15),
                          GestureDetector(
                            onTap: () => setState(() => _isExpanded = !_isExpanded),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _isExpanded 
                                          ? (book.description ?? 'No description available.')
                                          : ((book.description ?? 'No description available.').length > 150 
                                              ? '${(book.description ?? '').substring(0, 150)}... ' 
                                              : book.description),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        height: 1.7,
                                        fontFamily: 'Hanuman',
                                      ),
                                    ),
                                    if ((book.description ?? '').length > 150)
                                      TextSpan(
                                        text: _isExpanded ? " Show Less" : " Read More",
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),

                          // Rate this book
                          const Text(
                            "Rate this book",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Hanuman',
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(5, (index) {
                              return IconButton(
                                onPressed: () => _handleRate(index + 1),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  index < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: index < _userRating ? Colors.amber : Colors.grey[400],
                                  size: 32,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 35),
                          
                          // Related Books Sections
                          if (!_isLoadingRelated) ...[
                            if (_authorBooks.isNotEmpty) ...[
                              _buildSectionTitle("More from ${book.authorName ?? 'this author'}"),
                              const SizedBox(height: 15),
                              _buildRelatedBooksList(_authorBooks),
                              const SizedBox(height: 35),
                            ],
                            if (_newBooks.isNotEmpty) ...[
                              _buildSectionTitle("New Arrivals"),
                              const SizedBox(height: 15),
                              _buildRelatedBooksList(_newBooks),
                              const SizedBox(height: 35),
                            ],
                          ] else 
                            const Center(child: GlobalLoader(size: 40)),

                          const SizedBox(height: 120), // Space for bottom buttons
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. Persistent Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Wishlist Button
                  Consumer<WishlistProvider>(
                    builder: (context, wishlist, _) {
                      bool isFav = wishlist.isWishlisted(book.id);
                      return GestureDetector(
                        onTap: () => wishlist.toggleWishlist(book),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isFav ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey[600],
                            size: 26,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: displayStock > 0 ? _handleAddToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isAddingToCart)
                            const GlobalLoader(size: 20, color: Colors.white)
                          else ...[
                            Icon(displayStock > 0 ? Icons.add_shopping_cart_rounded : Icons.remove_shopping_cart_rounded, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              displayStock > 0 ? "Add To Cart" : "Out of Stock",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingBook) const GlobalLoader(isOverlay: true, message: 'Refreshing details...'),
        ],
      ),
    );
  }

  Widget _buildModernStatItem(BuildContext context, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {Color? color}) {
    // Keep this for potential backward compatibility or internal use
    return _buildModernStatItem(context, value, label, Icons.info_outline, color ?? Colors.grey);
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);
    final error = await _cartService.addToCart(_currentBook.id);
    
    if (mounted) {
      setState(() {
        _isAddingToCart = false;
      });
      
      if (error == null) {
        Provider.of<CartProvider>(context, listen: false).fetchCartCount();
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Added to Cart'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      } else {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(error),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _handleRate(int rating) async {
    if (_isSubmittingReview) return;

    // Calculate real-time average update locally
    final oldTotal = _reviewCount;
    final oldAvg = _currentAverageRating;
    
    // If the user hasn't rated before, we increment the count
    // If they have, we just update the average (assuming one rating per user)
    // For simplicity, let's assume this adds a new rating if _userRating was 0
    double newAvg;
    int newCount;

    if (_userRating == 0) {
      newCount = oldTotal + 1;
      newAvg = ((oldAvg * oldTotal) + rating) / newCount;
    } else {
      newCount = oldTotal;
      newAvg = ((oldAvg * oldTotal) - _userRating + rating) / newCount;
    }

    setState(() {
      _userRating = rating;
      _currentAverageRating = double.parse(newAvg.toStringAsFixed(1));
      _reviewCount = newCount;
      _isSubmittingReview = true;
    });

    final success = await _reviewService.submitReview(
      bookId: _currentBook.id,
      rating: rating,
    );

    if (mounted) {
      setState(() => _isSubmittingReview = false);
      if (success) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Thank you for your rating!'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      } else {
        // Rollback on failure? For now just show error
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Failed to submit rating'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Hanuman',
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildRelatedBooksList(List<Book> books) {
    return SizedBox(
      height: 280, // Height matching 2:3 aspect ratio (+ text height)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BookDescriptionPage(book: book)),
              );
            },
            child: Container(
              width: 150, // Perfect for showing exactly 2 items + peeking 3rd item
              margin: const EdgeInsets.only(right: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity, // CRITICAL: Forces container to take full width
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: book.displayImage,
                          fit: BoxFit.cover,
                          width: double.infinity, // CRITICAL: Forces image to fill the given width
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: GlobalLoader(size: 20),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.book, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Hanuman',
                            color: Color(0xFF1F2937),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\$${book.price}",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            fontFamily: 'Hanuman',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
