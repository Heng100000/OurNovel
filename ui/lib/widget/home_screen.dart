import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'telegram_link_dialog.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/global_loader.dart';
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
import '../core/models/banner.dart';
import '../features/home/data/banner_service.dart';
import '../core/models/news_announcement.dart';
import '../features/home/data/news_service.dart';
import '../core/services/realtime_service.dart';

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
  List<BannerModel> _banners = [];
  bool _isLoadingBanners = true;
  List<NewsAnnouncement> _newsAnnouncements = [];
  bool _isLoadingNews = true;

  // Initialize services
  final CategoryService _categoryService = CategoryService();
  final BookService _bookService = BookService();
  final CartService _cartService = CartService();
  final ReviewService _reviewService = ReviewService();
  final LocationService _locationService = LocationService();
  final WishlistService _wishlistService = WishlistService();
  final BannerService _bannerService = BannerService();
  final NewsService _newsService = NewsService();

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
      _fetchAuthors();
      _fetchCategories();
      _fetchNewBooks();
      _fetchPopularBooksApi();
      _fetchLocation();
      _fetchWishlist();
      _fetchBanners();
      _fetchNews();
      Provider.of<CartProvider>(context, listen: false).fetchCartCount();
      
      // Delay Telegram check to not compete with FCM request
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) _checkTelegramLinking();
      });
    });

    _bookUpdateSub = FcmHandler.onBookUpdate.listen((_) {
      if (mounted) {
        debugPrint('Real-time book update triggered on HomeScreen.');
        _fetchNewBooks();
        _fetchPopularBooksApi();
      }
    });

    RealtimeService().addListener(_onRealtimeUpdate);
  }

  void _onRealtimeUpdate() {
    if (mounted) {
      _refreshAllData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _bookUpdateSub?.cancel();
    RealtimeService().removeListener(_onRealtimeUpdate);
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint('HomeScreen: Navigated back, refreshing data...');
    _refreshAllData();
  }

  void _refreshAllData() {
    _fetchAuthors();
    _fetchCategories();
    _fetchNewBooks();
    _fetchPopularBooksApi();
    _fetchBanners();
    _fetchNews();
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

  Future<void> _fetchBanners() async {
    final banners = await _bannerService.getBanners();
    if (mounted) {
      setState(() {
        _banners = banners;
        _isLoadingBanners = false;
      });
    }
  }

  Future<void> _fetchNews() async {
    final news = await _newsService.getNewsAnnouncements();
    if (mounted) {
      setState(() {
        _newsAnnouncements = news;
        _isLoadingNews = false;
      });
    }
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
      _fetchBanners(),
      _fetchNews(),
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
      if (_currentPage < (_banners.isEmpty ? 2 : _banners.length - 1)) {
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

  Future<void> _checkTelegramLinking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check if the user already opted out
      final bool hideDialog = prefs.getBool('hide_telegram_dialog') ?? false;
      if (hideDialog) return;

      // 2. Check if the user is logged in
      final String? userDataStr = prefs.getString('user_data');
      if (userDataStr == null) return;

      final Map<String, dynamic> userData = json.decode(userDataStr);
      
      // 3. Check if telegram_chat_id is already set
      if (userData['telegram_chat_id'] != null) return;

      // 4. Show the dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TelegramLinkDialog(userId: userData['id']),
        );
      }
    } catch (e) {
      debugPrint('Error checking telegram linking: $e');
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, langService, child) {
        final isDark = themeService.isDarkMode;
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: AppColors.primary,
          drawer: const SideMenuDrawer(),
          body: Column(
            children: [
              // ── Modern Header with gradient ──
              _buildModernHeader(context, langService),

              // ── White curved body ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.scaffoldBackgroundColor
                        : const Color(0xFFF5F9F0),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Flash Sale Banner Header
                            _buildSectionHeader(
                              context,
                              langService.translate('special_for_you'),
                              langService,
                              showSeeAll: true,
                            ),
                            const SizedBox(height: 14),

                            // Slider Banner
                            SizedBox(
                              height: 160,
                              child: _isLoadingBanners
                                  ? const Center(
                                      child: GlobalLoader(size: 40),
                                    )
                                  : _banners.isEmpty
                                      ? PageView(
                                          controller: _pageController,
                                          onPageChanged: (index) {
                                            setState(() => _currentPage = index);
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
                                        )
                                      : PageView.builder(
                                          controller: _pageController,
                                          onPageChanged: (index) {
                                            setState(() => _currentPage = index);
                                          },
                                          itemCount: _banners.length,
                                          itemBuilder: (context, index) {
                                            return _buildDynamicBannerItem(_banners[index]);
                                          },
                                        ),
                            ),

                            const SizedBox(height: 12),

                            // Slide Indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _banners.isEmpty ? 3 : _banners.length,
                                (index) => _buildIndicator(index == _currentPage),
                              ),
                            ),

                            const SizedBox(height: 26),

                            // Categories
                            _buildSectionHeader(context, langService.translate('category'), langService, showSeeAll: false),
                            const SizedBox(height: 14),
                            _isLoadingCategories
                                ? const Center(
                                    child: GlobalLoader(size: 40),
                                  )
                                : _categories.isEmpty
                                    ? Text(langService.translate('no_categories'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500]))
                                    : Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: _categories
                                            .map((cat) => _buildCategoryChip(cat.name, cat.icon))
                                            .toList(),
                                      ),

                            const SizedBox(height: 26),

                            // Popular Section
                            _buildSectionHeader(context, langService.translate('popular'), langService, showSeeAll: true),
                            const SizedBox(height: 14),
                            _isLoadingPopularBooksApi
                                ? const Center(
                                    child: GlobalLoader(size: 40),
                                  )
                                : _popularBooksApi.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Text(
                                            langService.translate('no_data'),
                                            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500),
                                          ),
                                        ),
                                      )
                                    : SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: Row(
                                          children: _popularBooksApi
                                              .map((book) => _buildBookCard(book, isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100))
                                              .toList(),
                                        ),
                                      ),

                            const SizedBox(height: 26),

                            // New Book Section
                            _buildSectionHeader(context, langService.translate('new_book'), langService, showSeeAll: false),
                            const SizedBox(height: 14),
                            _isLoadingNewBooks
                                ? const Center(
                                    child: GlobalLoader(size: 40),
                                  )
                                : _newBooks.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 30),
                                          child: Text(
                                            langService.translate('no_data'),
                                            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500),
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: _newBooks
                                            .map((book) => _buildNewBookItem(book))
                                            .toList(),
                                      ),

                            const SizedBox(height: 26),

                            // Top Author Section
                            _buildSectionHeader(context, langService.translate('top_author'), langService, showSeeAll: false),
                            const SizedBox(height: 14),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: _isLoadingAuthors
                                  ? const Center(
                                      child: GlobalLoader(size: 40),
                                    )
                                  : Row(
                                      children: _authors.isEmpty
                                          ? [Text(langService.translate('no_data'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))]
                                          : _authors
                                              .map((author) => _buildTopAuthorItem(
                                                    author.name,
                                                    author.profileImageUrl ?? "",
                                                  ))
                                              .toList(),
                                    ),
                            ),
                            const SizedBox(height: 30),
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
      },
    );
  }

  // ─── Modern Header ─────────────────────────────────────────────────────────

  Widget _buildModernHeader(BuildContext context, LanguageService langService) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryVariant, AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: menu + actions
          Row(
            children: [
              // Menu button
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langService.translate('location'),
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _currentLocation,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              Consumer<NotificationProvider>(
                builder: (context, notifProvider, _) {
                  return _buildHeaderAction(
                    icon: Icons.notifications_outlined,
                    badgeCount: notifProvider.unreadCount,
                    onTap: () => _showNotificationBottomSheet(context),
                  );
                },
              ),
              const SizedBox(width: 8),
              Consumer<CartProvider>(
                builder: (context, cartProvider, _) {
                  return _buildHeaderAction(
                    icon: Icons.shopping_cart_outlined,
                    badgeCount: cartProvider.itemCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartPage()),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildHeaderAction(
                icon: Icons.favorite_border_rounded,
                onTap: () => Navigator.pushNamed(context, '/wishlist'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Search bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterBooks,
                          decoration: InputDecoration(
                            hintText: langService.translate('search'),
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: AppColors.accentYellow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentYellow.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFF1A1A00), size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title, LanguageService langService, {bool showSeeAll = true}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: theme.textTheme.bodyLarge?.color,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (showSeeAll)
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/promotions'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                langService.translate('see_all'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Indicators ─────────────────────────────────────────────────────────────

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  // ─── Banners ────────────────────────────────────────────────────────────────

  Widget _buildBannerItem(
      String title, String subtitle, List<Color> colors, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 160,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          // Dot accent
          Positioned(
            top: 16,
            right: 20,
            child: Column(
              children: List.generate(3, (row) {
                return Row(
                  children: List.generate(3, (col) {
                    return Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Shop Now →',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicBannerItem(BannerModel banner) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: CachedNetworkImageProvider(banner.imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.65),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              banner.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category Chip ──────────────────────────────────────────────────────────

  Widget _buildCategoryChip(String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color ?? const Color(0xFF333333),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Interactive Stars ──────────────────────────────────────────────────────

  Widget _buildInteractiveStars(model.Book book, {double size = 14}) {
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

            final success = await _reviewService.submitReview(
                bookId: book.id, rating: newRating);

            if (!success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to save rating')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFilled ? Colors.amber : Colors.grey.shade300,
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
        return const Color(0xFF2E7D32);
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

  // ─── Popular Book Card ──────────────────────────────────────────────────────

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
        width: 148,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 185,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: color,
                              child: const Center(
                                child: GlobalLoader(size: 20),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: color,
                              child: const Center(
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                            ),
                          )
                        : Container(
                            color: color,
                            child: const Center(
                              child: Icon(Icons.book,
                                  color: Colors.grey, size: 40),
                            ),
                          ),
                  ),
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
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
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
                                isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 16,
                                color: isWishlisted ? Colors.red : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF2E7D32),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    author,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  _buildInteractiveStars(book),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5A7336),
                              fontSize: 14,
                            ),
                          ),
                          if (oldPrice != null && oldPrice.isNotEmpty)
                            Text(
                              oldPrice,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
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
                                description: const Text('Item added to cart successfully!'),
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
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
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

  // ─── New Book Row ───────────────────────────────────────────────────────────

  Widget _buildNewBookItem(model.Book book) {
    final title = book.title;
    final author = book.authorName ?? "";
    final imageUrl = book.displayImage;
    final price = "\$${book.price}";
    final oldPrice = book.oldPrice != null ? "\$${book.oldPrice}" : "";
    final condition = book.condition;
    final bookId = book.id;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              Stack(
                children: [
                  Container(
                    width: 82,
                    height: 125,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: GlobalLoader(size: 20),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error_outline, color: Colors.grey),
                            )
                          : const Center(
                              child: Icon(Icons.book, size: 40, color: Colors.grey),
                            ),
                    ),
                  ),
                  if (condition != null && condition.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getConditionColor(condition),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E7D32),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite_border_rounded,
                            color: Color(0xFF2E7D32), size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    _buildInteractiveStars(book),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              price,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (oldPrice.isNotEmpty)
                              Text(
                                oldPrice,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        // Add to cart
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
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
                                await CartService().addToCart(bookId, quantity: 1);
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Add to Cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
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
      ),
    );
  }

  // ─── Top Author ─────────────────────────────────────────────────────────────

  Widget _buildTopAuthorItem(String name, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          // Gradient ring avatar
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.accentYellow, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.5),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: GlobalLoader(size: 20),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 35, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 35, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 76,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
