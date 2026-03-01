import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'dart:async';
import 'dart:ui' show ImageFilter;

import '../../../../features/cart/data/cart_provider.dart';
import '../../../../widget/cart_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/global_loader.dart';
import '../../../../features/cart/data/cart_service.dart';
import '../../data/promotion_service.dart';
import '../../../../core/models/event.dart';
import '../../../../core/models/promotion.dart';
import '../../../../core/models/book.dart';
import '../../../../features/menu/presentation/pages/menu_page.dart';
import '../widgets/countdown_timer_widget.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../theme/theme_service.dart';
import '../../../../l10n/language_service.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  final PromotionService _service = PromotionService();
  final CartService _cartService = CartService();
  List<EventModel> _events = [];
  List<PromotionModel> _promotions = [];
  bool _isLoading = true;
  int _selectedCategoryIndex = 0;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startBannerTimer();
    _startPollingTimer();
    RealtimeService().addListener(_onRealtimeUpdate);
  }

  void _onRealtimeUpdate() {
    if (mounted) {
      _fetchData(isBackground: true);
    }
  }

  void _startPollingTimer() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchData(isBackground: true);
      }
    });
  }

  Future<void> _fetchData({bool isBackground = false}) async {
    if (!isBackground) setState(() => _isLoading = true);
    
    try {
      final events = await _service.getEvents();
      final promotions = (await _service.getPromotions())
          .where((p) => p.endDate == null || p.endDate!.isAfter(DateTime.now()))
          .toList();
          
      setState(() {
        _events = events;
        _promotions = promotions;
        if (!isBackground) _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (!isBackground) setState(() => _isLoading = false);
    }
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients && _events.isNotEmpty) {
        int nextItem = _currentBannerIndex + 1;
        if (nextItem >= _events.length) nextItem = 0;
        _bannerController.animateToPage(
          nextItem,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _pollingTimer?.cancel();
    RealtimeService().removeListener(_onRealtimeUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, langService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FBF6);

        final List<Book> sourceBooks = _searchQuery.isEmpty && _promotions.isNotEmpty
            ? _promotions[_selectedCategoryIndex].books.where((b) => (b.stockQty ?? 0) > 0).toList()
            : _promotions.expand((p) => p.books).where((b) => (b.stockQty ?? 0) > 0).toList();

        final filteredBooks = sourceBooks.where((book) =>
            book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (book.authorName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();

        return Scaffold(
          backgroundColor: bgColor,
          drawer: const SideMenuDrawer(),
          body: RefreshIndicator(
            onRefresh: _fetchData,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildSliverHeader(context, isDark, langService),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading) ...[
                        _buildSkeletonCarousel(isDark),
                        _buildSkeletonCategories(isDark),
                        _buildSkeletonGrid(),
                      ] else ...[
                        if (_searchQuery.isEmpty) ...[
                          _buildHeroCarousel(isDark, langService),
                          _buildFlashSaleTrophy(isDark, langService),
                          _buildPromotionCategories(isDark),
                          _buildFlashSalesHeader(isDark, langService),
                        ],
                        if (filteredBooks.isEmpty && !_isLoading)
                          _buildEmptyState(isDark, langService)
                        else
                          _buildFlashSalesGrid(filteredBooks, isDark, langService),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlashSaleTrophy(bool isDark, LanguageService langService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: AppColors.accentYellow, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    langService.translate('summer_flash_sale'),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                  Text(
                    langService.translate('limited_qty'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white38 : AppColors.primary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCarousel(bool isDark, LanguageService langService) {
    if (_events.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 220,
      margin: const EdgeInsets.only(top: 20),
      child: PageView.builder(
        controller: _bannerController,
        onPageChanged: (index) => setState(() => _currentBannerIndex = index),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          final List<Color> gradientColors = index % 3 == 0 
              ? [const Color(0xFFE53935), const Color(0xFFB71C1C)] 
              : (index % 3 == 1 
                  ? [const Color(0xFF1E88E5), const Color(0xFF0D47A1)] 
                  : [const Color(0xFF43A047), const Color(0xFF1B5E20)]);
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (event.bannerImageUrl != null)
                    CachedNetworkImage(
                      imageUrl: event.bannerImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: gradientColors[0]),
                      errorWidget: (context, url, error) => _buildFallbackBg(gradientColors),
                    )
                  else
                    _buildFallbackBg(gradientColors),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          gradientColors[0].withOpacity(0.9),
                          gradientColors[0].withOpacity(0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Text(
                            "EVENT 2026",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: HtmlWidget(
                              event.description ?? '',
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            if (event.promotions.isNotEmpty) {
                              _showPromotionDetails(context, event.promotions.first);
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      langService.translate('check_now'),
                                      style: TextStyle(
                                        color: gradientColors[0],
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: gradientColors[0]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
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

  Widget _buildFallbackBg(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, bool isDark, LanguageService langService) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [const Color(0xFF1A2410), const Color(0xFF2D3A1D)] 
                  : [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16),
                child: Row(
                  children: [
                    if (!_isSearching) ...[
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
                      const SizedBox(width: 8),
                      Text(
                        langService.translate('promotions'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      _buildHeaderAction(Icons.search, () => setState(() => _isSearching = true)),
                      const SizedBox(width: 8),
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, _) => _buildHeaderAction(
                          Icons.shopping_cart_outlined,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
                          badge: cartProvider.itemCount,
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: _buildSearchField(langService),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap, {int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(LanguageService langService) {
    return Container(
      height: 45,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: langService.translate('search_discounts'),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: () => setState(() { _isSearching = false; _searchController.clear(); _searchQuery = ''; }),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, LanguageService langService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(langService.translate('no_discounts_found'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCategories(bool isDark) {
    if (_promotions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _promotions.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedCategoryIndex == index;
            final itemBg = isDark ? (isSelected ? AppColors.primary : const Color(0xFF1E1E1E)) : (isSelected ? AppColors.primary : Colors.white);
            final itemText = isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey[600]);

            return GestureDetector(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: itemBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                  border: Border.all(color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200)),
                ),
                child: Center(
                  child: Text(
                    _promotions[index].eventName,
                    style: TextStyle(color: itemText, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlashSalesHeader(bool isDark, LanguageService langService) {
    if (_promotions.isEmpty) return const SizedBox.shrink();
    final promo = _promotions[_selectedCategoryIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(langService.translate('ongoing_discounts'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF2E3E23))),
          if (promo.endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF8A65)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CountdownTimerWidget(startDate: promo.startDate, endDate: promo.endDate!),
            ),
        ],
      ),
    );
  }

  Widget _buildFlashSalesGrid(List<Book> items, bool isDark, LanguageService langService) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) => GridView.builder(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildFlashSaleItem(items[index], cartProvider, isDark, langService),
      ),
    );
  }

  Widget _buildFlashSaleItem(Book book, CartProvider cartProvider, bool isDark, LanguageService langService) {
    final currentPrice = double.tryParse(book.price.toString()) ?? 0.0;
    final originalPrice = double.tryParse(book.oldPrice ?? '') ?? currentPrice;
    final discount = originalPrice > currentPrice ? ((originalPrice - currentPrice) / originalPrice * 100).round() : 0;
    
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: book.images?.isNotEmpty == true
                      ? CachedNetworkImage(imageUrl: book.images!.first.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      : Image.asset('assets/images/Novel.png', fit: BoxFit.cover, width: double.infinity),
                ),
                if (discount > 0)
                  Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(10)), child: Text('-$discount%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: titleColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(book.authorName ?? 'Unkown', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey), maxLines: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('\$$currentPrice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: isDark ? AppColors.accentYellow : AppColors.primary)),
                        if (discount > 0) Text('\$$originalPrice', style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.grey, decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                    _buildAddToCartBtn(book, langService),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartBtn(Book book, LanguageService langService) {
    return InkWell(
      onTap: () async {
        final error = await _cartService.addToCart(book.id);
        if (error == null && mounted) {
          Provider.of<CartProvider>(context, listen: false).fetchCartCount();
          toastification.show(
            context: context, 
            type: ToastificationType.success, 
            title: const Text('Success'), // I'll keep 'Success' or add key
            description: Text(langService.translate('added_to_cart').replaceFirst('%s', book.title)), 
            autoCloseDuration: const Duration(seconds: 3)
          );
        }
      },
      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16)),
    );
  }

  // --- Skeletons ---
  Widget _buildSkeletonCarousel(bool isDark) => Container(height: 200, margin: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(28)));
  Widget _buildSkeletonCategories(bool isDark) => Padding(padding: const EdgeInsets.all(16), child: Row(children: List.generate(4, (i) => Container(width: 80, height: 40, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(16))))));
  Widget _buildSkeletonGrid() => const Center(child: Padding(padding: EdgeInsets.all(40), child: GlobalLoader(size: 40)));

  void _showPromotionDetails(BuildContext context, PromotionModel promo) {
    // Navigate logic
  }
}
