import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../l10n/language_service.dart';
import '../core/models/book.dart' as model;
import '../features/home/data/wishlist_service.dart';
import '../features/cart/data/cart_service.dart';
import '../features/notifications/data/notification_provider.dart';
import '../features/wishlist/data/wishlist_provider.dart';
import '../features/notifications/presentation/widgets/notification_bottom_sheet.dart';
import 'cart_page.dart';
import 'package:toastification/toastification.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final WishlistService _wishlistService = WishlistService();
  final CartService _cartService = CartService();
  
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
    _fetchCartItemCount();
  }

  Future<void> _fetchCartItemCount() async {
    final items = await _cartService.getCartItems();
    if (mounted) {
      setState(() {
        _cartItemCount = items.fold(0, (sum, item) => sum + item.quantity);
      });
    }
  }

  void _showNotificationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationBottomSheet(),
    );
  }

  Future<void> _fetchWishlist() async {
    Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _fetchWishlist(),
      _fetchCartItemCount(),
    ]);
  }

  Future<void> _removeItem(int bookId) async {
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    // Confirmation Dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Item', style: TextStyle(fontFamily: 'Hanuman', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this book from your wishlist?', style: TextStyle(fontFamily: 'Hanuman')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await wishlistProvider.removeItem(bookId);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to remove item. Please try again.")),
      );
    } else if (mounted) {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        title: const Text('Wishlist Updated'),
        description: const Text('Item removed from wishlist'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _addToCart(model.Book book) async {
    final errorMessage = await _cartService.addToCart(book.id, quantity: 1);
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
        _fetchCartItemCount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Premium Header Section with Custom Height
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 25),
            decoration: BoxDecoration(
              color: AppColors.primary,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withRed(AppColors.primary.red + 20).withGreen(AppColors.primary.green + 10).withBlue(AppColors.primary.blue + 5),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Custom AppBar Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        LanguageService().translate('wishlist_title') ?? 'Wishlist',
                        style: const TextStyle(
                          fontFamily: 'Hanuman',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 22,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, child) {
                              return IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                                      if (notificationProvider.unreadCount > 0)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                            child: Text(
                                              notificationProvider.unreadCount.toString(),
                                              style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
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
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                                  if (_cartItemCount > 0)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                        child: Text(
                                          _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
                                          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
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
                              ).then((_) => _fetchCartItemCount());
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Subtitle or Summary inside header
                Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    if (wishlistProvider.isLoading || wishlistProvider.items.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${wishlistProvider.items.length} items in your list',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              displacement: 20,
              child: Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, child) {
                  if (wishlistProvider.isLoading && wishlistProvider.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (wishlistProvider.items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: _buildEmptyState(),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    itemCount: wishlistProvider.items.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = wishlistProvider.items[index];
                      return _buildWishlistItem(item);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            LanguageService().translate('empty_wishlist') ?? 'Your wishlist is empty',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Hanuman',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LanguageService().translate('empty_wishlist_desc') ?? 'Start adding your favorite books!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Hanuman',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Go Shopping",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(model.Book book) {
    final theme = Theme.of(context);
    final imageUrl = book.displayImage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Book Image
          SizedBox(
            width: 85,
            height: 110,
            child: Container(
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
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade100,
                          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.book, size: 30, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.book, size: 30, color: Colors.grey),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _removeItem(book.id),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  book.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFamily: 'Hanuman',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  book.authorName ?? "Unknown Author",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${book.price}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.primary,
                        fontFamily: 'Hanuman',
                      ),
                    ),
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        onTap: () => _addToCart(book),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Add to Cart",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Hanuman',
                                ),
                              ),
                            ],
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
    );
  }
}
