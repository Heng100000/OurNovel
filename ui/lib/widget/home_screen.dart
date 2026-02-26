import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../features/menu/presentation/pages/menu_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/home/presentation/pages/book_description_page.dart';

import 'dart:async';
import 'wishlist_page.dart';
import 'cart_page.dart';
import 'package:toastification/toastification.dart';

import '../l10n/language_service.dart';

import '../theme/theme_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../features/notifications/data/notification_provider.dart';
import '../features/cart/data/cart_provider.dart';
import '../core/services/fcm_handler.dart';
import '../features/notifications/presentation/widgets/notification_bottom_sheet.dart';
import '../core/models/author.dart';
import '../features/home/data/author_service.dart';
import '../core/models/category.dart';
import '../features/home/data/category_service.dart';
import '../core/models/book.dart' as model;
import '../features/home/data/book_service.dart';
import '../features/cart/data/cart_service.dart';
import '../features/reviews/data/review_service.dart';
import '../core/services/location_service.dart';
import '../features/home/data/wishlist_service.dart';
import '../features/wishlist/data/wishlist_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Import to access routeObserver

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  final TextEditingController _searchController = TextEditingController();
  List<Author> _authors = [];
  bool _isLoadingAuthors = true;
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  List<model.Book> _newBooks = [];
  bool _isLoadingNewBooks = true;
  List<model.Book> _popularBooksApi = [];
  bool _isLoadingPopularBooksApi = true;
  StreamSubscription<void>? _bookUpdateSub;
  String _currentLocation = 'Phnom Penh, Cambodia';
  bool _isLoadingLocation = true;

  // Initialize services
  final CategoryService _categoryService = CategoryService();
  final BookService _bookService = BookService();
  final CartService _cartService = CartService();
  final ReviewService _reviewService = ReviewService();
  final LocationService _locationService = LocationService();
  final WishlistService _wishlistService = WishlistService();

  void _showNotificationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationBottomSheet(),
    );
  }

  // Initial Data
  final List<model.Book> _allBooks = [];

  List<model.Book> _displayedBooks = [];

  @override
  void initState() {
    super.initState();
    _displayedBooks = List.from(_allBooks);
    _startAutoSlide();

    // Initialize Notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmHandler.initialize(context);
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchUnreadCount();
      _fetchCategories();
      _fetchNewBooks();
      _fetchPopularBooksApi();
      _fetchLocation();
      _fetchWishlist();
      Provider.of<CartProvider>(context, listen: false).fetchCartCount();
    });

    _bookUpdateSub = FcmHandler.onBookUpdate.listen((_) {
      if (mounted) {
        debugPrint('Real-time book update triggered on HomeScreen.');
        _fetchNewBooks();
        _fetchPopularBooksApi();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer to know when we navigate back to this screen
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _bookUpdateSub?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    // This is called when the user navigates back to the HomeScreen
    debugPrint('HomeScreen: Navigated back, refreshing data...');
    _refreshAllData();
  }

  void _refreshAllData() {
    _fetchCategories();
    _fetchNewBooks();
    _fetchPopularBooksApi();
    Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
    Provider.of<CartProvider>(context, listen: false).fetchCartCount();
  }

  Future<void> _fetchAuthors() async {
    final authors = await AuthorService().getAllAuthors();
    if (mounted) {
      setState(() {
        _authors = authors;
        _isLoadingAuthors = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    final categories = await _categoryService.getAllCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchNewBooks() async {
    final books = await BookService().getNewBooks();
    if (mounted) {
      setState(() {
        _newBooks = books;
        _isLoadingNewBooks = false;
      });
    }
  }

  Future<void> _fetchPopularBooksApi() async {
    final books = await BookService().getPopularBooks();
    if (mounted) {
      setState(() {
        _popularBooksApi = books;
        _isLoadingPopularBooksApi = false;
      });
    }
  }

  Future<void> _fetchLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentLocation = location;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _fetchWishlist() async {
    Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
  }

  Future<void> _toggleWishlist(model.Book book) async {
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
      return;
    }

    final success = await wishlistProvider.toggleWishlist(book);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update wishlist')),
      );
    }
  }


  Future<void> _handleRefresh() async {
    setState(() {
      _isLoadingAuthors = true;
      _isLoadingCategories = true;
      _isLoadingNewBooks = true;
      _isLoadingPopularBooksApi = true;
      _isLoadingLocation = true;
    });

    await Future.wait([
      _fetchAuthors(),
      _fetchCategories(),
      _fetchNewBooks(),
      _fetchPopularBooksApi(),
      Provider.of<CartProvider>(context, listen: false).fetchCartCount(),
      _fetchLocation(),
      _fetchWishlist(),
    ]);
  }

  void _filterBooks(String query) {
    setState(() {
      if (query.isEmpty) {
        _displayedBooks = List.from(_allBooks);
      } else {
        _displayedBooks = _allBooks.where((book) {
          final titleLower = book.title.toLowerCase();
          final authorLower = (book.authorName ?? "").toLowerCase();
          final searchLower = query.toLowerCase();
          return titleLower.contains(searchLower) ||
              authorLower.contains(searchLower);
        }).toList();
      }
    });
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.primary,
      drawer: const SideMenuDrawer(), // Integrating the side menu
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, color: Colors.white),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              notificationProvider.unreadCount.toString(),
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
                onPressed: () => _showNotificationBottomSheet(context),
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white),
                      if (cartProvider.itemCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite_border, color: Colors.white),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/wishlist');
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Header Section (Location & Search)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService().translate('location'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _currentLocation,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white, size: 16),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _filterBooks,
                                decoration: InputDecoration(
                                  hintText:
                                      LanguageService().translate('search'),
                                  hintStyle:
                                      const TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // White Body Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? theme.scaffoldBackgroundColor
                    : const Color(0xFFF5F9F0), // Adaptable BG
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Flash Sale Banner Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "#SpecialForYou",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            "See All",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Slider Banner
                      SizedBox(
                        height: 140,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          children: [
                            _buildBannerItem(
                              "FLASH SALE",
                              "01 : 34 : 46",
                              [const Color(0xFF3E5830), AppColors.primary],
                              Icons.eco,
                            ),
                            _buildBannerItem(
                              "NEW ARRIVALS",
                              "Check out now!",
                              [Colors.orange.shade800, Colors.orange.shade400],
                              Icons.new_releases,
                            ),
                            _buildBannerItem(
                              "BEST SELLERS",
                              "Top 10 Books",
                              [Colors.blue.shade800, Colors.blue.shade400],
                              Icons.star,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Slide Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3,
                            (index) => _buildIndicator(index == _currentPage)),
                      ),

                      const SizedBox(height: 20),

                      // Categories
                      Text(
                        "Category",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : _categories.isEmpty
                              ? const Text("No categories found")
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _categories
                                      .map((cat) => _buildCategoryChip(
                                          cat.name, cat.icon))
                                      .toList(),
                                ),

                      const SizedBox(height: 25),

                      // Popular Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Popular",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            "See All",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _isLoadingPopularBooksApi
                          ? const Center(child: CircularProgressIndicator())
                          : _popularBooksApi.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      "No data",
                                      style: TextStyle(
                                          color: Colors.grey.shade500),
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _popularBooksApi
                                        .map((book) => _buildBookCard(
                                              book,
                                              Colors.grey.shade100,
                                            ))
                                        .toList(),
                                  ),
                                ),

                      const SizedBox(height: 25),

                      // New Book Section (Dynamic from API)
                      Text(
                        "New Book",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _isLoadingNewBooks
                          ? const Center(child: CircularProgressIndicator())
                          : _newBooks.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 30.0),
                                    child: Text(
                                      "No data",
                                      style: TextStyle(
                                          color: Colors.grey.shade500),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _newBooks
                                      .map((book) => _buildNewBookItem(book))
                                      .toList(),
                                ),

                      const SizedBox(height: 25),

                      // Top Author Section
                      Text(
                        "Top Author",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _isLoadingAuthors
                            ? const Center(child: CircularProgressIndicator())
                            : Row(
                                children: _authors.isEmpty
                                    ? [const Text("No authors found")]
                                    : _authors
                                        .map((author) => _buildTopAuthorItem(
                                              author.name,
                                              author.profileImageUrl ?? "",
                                            ))
                                        .toList(),
                              ),
                      ),
                      const SizedBox(height: 30), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildBannerItem(
      String title, String subtitle, List<Color> colors, IconData icon) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.symmetric(horizontal: 5), // Spacing between slides
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.book, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.cardColor
            : const Color(0xFFE8F0E0), // Light green tint in light mode
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 18, color: const Color(0xFF5A7336)), // Darker green icon
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color:
                  theme.textTheme.bodyMedium?.color ?? const Color(0xFF333333),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveStars(model.Book book, {double size = 14}) {
    // Determine the rating to display
    // 1. User's rating (highest priority)
    // 2. Average rating (if no user rating)
    // 3. 0 (if no ratings at all)
    final double ratingToDisplay = (book.userRating != null)
        ? book.userRating!.toDouble()
        : (book.averageRating ?? 0.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < ratingToDisplay;

        return GestureDetector(
          onTap: () async {
            final newRating = index + 1;

            // Optimistic UI update
            setState(() {
              if (_newBooks.contains(book)) {
                final bookIndex = _newBooks.indexOf(book);
                _newBooks[bookIndex] = model.Book(
                  id: book.id,
                  title: book.title,
                  isbn: book.isbn,
                  description: book.description,
                  price: book.price,
                  oldPrice: book.oldPrice,
                  discountedPrice: book.discountedPrice,
                  condition: book.condition,
                  stockQty: book.stockQty,
                  status: book.status,
                  authorName: book.authorName,
                  images: book.images,
                  color: book.color,
                  isPopular: book.isPopular,
                  isNew: book.isNew,
                  averageRating: book.averageRating,
                  reviewCount: book.reviewCount,
                  userRating: newRating,
                );
              }
              final popularKeys = _popularBooksApi.toList();
              for (var i = 0; i < popularKeys.length; i++) {
                final b = popularKeys[i];
                if (b.id == book.id) {
                  _popularBooksApi[i] = model.Book(
                    id: book.id,
                    title: book.title,
                    isbn: book.isbn,
                    description: book.description,
                    price: book.price,
                    oldPrice: book.oldPrice,
                    discountedPrice: book.discountedPrice,
                    condition: book.condition,
                    stockQty: book.stockQty,
                    status: book.status,
                    authorName: book.authorName,
                    images: book.images,
                    color: book.color,
                    isPopular: book.isPopular,
                    isNew: book.isNew,
                    averageRating: book.averageRating,
                    reviewCount: book.reviewCount,
                    userRating: newRating,
                  );
                }
              }
            });

            // Make API Call
            final success = await _reviewService.submitReview(
                bookId: book.id, rating: newRating);

            if (!success && mounted) {
              // Revert on failure (simplified for brevity, usually you'd store old state)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to save rating')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: isFilled ? Colors.amber : Colors.grey.shade400,
              size: size,
            ),
          ),
        );
      }),
    );
  }

  Color _getConditionColor(String? condition) {
    if (condition == null) return Colors.transparent;
    switch (condition.toLowerCase()) {
      case 'new':
        return const Color(0xFF2E7D32); // Dark Green
      case 'like new':
        return Colors.teal;
      case 'very good':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'acceptable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBookCard(model.Book book, Color color) {
    final title = book.title;
    final author = book.authorName ?? "";
    final imageUrl = book.displayImage;
    final price = "\$${book.price}";
    final oldPrice = book.oldPrice != null ? "\$${book.oldPrice}" : null;
    final condition = book.condition;

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
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: color,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.white.withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white70),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child:
                                  Icon(Icons.error_outline, color: Colors.white54),
                            ),
                          )
                        : null,
                  ),
                  if (imageUrl.isEmpty)
                    Center(
                        child: Container(
                      width: 50,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Center(
                          child: Icon(Icons.bookmark,
                              color: Colors.white, size: 30)),
                    )),
                  if (condition != null && condition.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getConditionColor(condition),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
  
                  // Heart Icon for Popular Books
                  if (book.isPopular || (condition?.toLowerCase() == 'popular'))
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Consumer<WishlistProvider>(
                        builder: (context, wishlistProvider, child) {
                          final isWishlisted = wishlistProvider.isWishlisted(book.id);
                          return GestureDetector(
                            onTap: () => _toggleWishlist(book),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isWishlisted ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isWishlisted ? Colors.red : Colors.grey,
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2E7D32), // Dark Green for title
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              author,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _buildInteractiveStars(book),
            if (price != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A7336),
                          fontSize: 14,
                        ),
                      ),
                      if (oldPrice != null && oldPrice.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          oldPrice,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
  
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('token');
  
                      if (token == null) {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                          );
                        }
                        return;
                      }
  
                      final errorMessage =
                          await _cartService.addToCart(book.id, quantity: 1);
                      if (mounted) {
                        if (errorMessage == null) {
                          toastification.show(
                            context: context,
                            type: ToastificationType.success,
                            style: ToastificationStyle.flatColored,
                            title: const Text('Success'),
                            description:
                                const Text('Item added to cart successfully!'),
                            alignment: Alignment.topRight,
                            autoCloseDuration: const Duration(seconds: 3),
                          );
                          Provider.of<CartProvider>(context, listen: false)
                              .fetchCartCount();
                        } else {
                          toastification.show(
                            context: context,
                            type: ToastificationType.error,
                            style: ToastificationStyle.flatColored,
                            title: const Text('Error'),
                            description: Text(errorMessage),
                            alignment: Alignment.topRight,
                            autoCloseDuration: const Duration(seconds: 3),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewBookItem(model.Book book) {
    final title = book.title;
    final author = book.authorName ?? "";
    final imageUrl = book.displayImage;
    final price = "\$${book.price}";
    final oldPrice = book.oldPrice != null ? "\$${book.oldPrice}" : "";
    final condition = book.condition;
    final bookId = book.id;

    final theme = Theme.of(context);
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
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error_outline, color: Colors.grey),
                              )
                            : null,
                      ),
                      if (imageUrl.isEmpty)
                        const Center(
                          child: Icon(Icons.book, size: 40, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (condition != null && condition.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getConditionColor(condition),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        condition,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 15),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.favorite_border,
                          color: Color(0xFF2E7D32), size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildInteractiveStars(book),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (oldPrice.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              oldPrice,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () async {
                            // Show loading snackbar or just proceed
  
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('token');
  
                            if (token == null) {
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginPage()),
                                );
                              }
                              return;
                            }
  
                            final errorMessage = await CartService()
                                .addToCart(bookId, quantity: 1);
                            if (mounted) {
                              if (errorMessage == null) {
                                toastification.show(
                                  context: context,
                                  type: ToastificationType.success,
                                  style: ToastificationStyle.flatColored,
                                  title: const Text('Success'),
                                  description: const Text(
                                      'Item added to cart successfully!'),
                                  alignment: Alignment.topRight,
                                  autoCloseDuration: const Duration(seconds: 3),
                                );
                                Provider.of<CartProvider>(context, listen: false)
                                    .fetchCartCount();
                              } else {
                                toastification.show(
                                  context: context,
                                  type: ToastificationType.error,
                                  style: ToastificationStyle.flatColored,
                                  title: const Text('Error'),
                                  description: Text(errorMessage),
                                  alignment: Alignment.topRight,
                                  autoCloseDuration: const Duration(seconds: 3),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text(
                            "Add To Cart",
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
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

  Widget _buildTopAuthorItem(String name, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 35, color: Colors.white),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 35, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
