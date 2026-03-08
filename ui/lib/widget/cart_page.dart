import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/widgets/global_loader.dart';
import 'address_edit_page.dart';
import 'map_picker_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:toastification/toastification.dart';

import '../l10n/language_service.dart';
import '../features/cart/data/cart_service.dart';
import '../features/cart/data/order_service.dart';
import '../features/payway/data/payment_service.dart';
import '../core/constants/app_colors.dart';
import '../features/payway/presentation/pages/payment_page.dart';
import '../features/cart/data/cart_item_model.dart';
import '../core/models/delivery_company.dart';
import '../core/constants/api_constants.dart';
import '../core/models/user_address.dart';
import '../features/address/data/user_address_service.dart';
import '../features/delivery/data/delivery_service.dart';
import 'package:provider/provider.dart';
import '../features/cart/data/cart_provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isSummaryExpanded =
      false; // Persistent state for order summary visibility
  List<CartItemModel> _cartItems = [];
  bool _isLoadingCart = true;

  // Delivery Methods
  int? _selectedDeliveryId;
  List<DeliveryCompany> _deliveryCompanies = [];
  bool _isLoadingDelivery = true;
  String? _deliveryError;
  String _deliveryMethod = 'delivery'; // 'delivery' or 'pickup'
  String _paymentMethod = 'bakong'; // 'bakong' or 'cash'
  // --- Replaced with dynamic data from API ---

  // Address State
  UserAddress? _userAddress;
  String _address = "Locating..."; // Fallbacks if no address saved
  String _phone = "012 345 678";
  double? _lat;
  double? _lng;
  bool _isLoadingLocation = true;

  // Coupon State
  final TextEditingController _couponController = TextEditingController();
  double _discountAmount = 0.0;
  String? _appliedCouponCode;
  bool _isApplyingCoupon = false;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
    _fetchDeliveryCompanies();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    setState(() {
      _isLoadingLocation = true;
    });
    final addresses = await UserAddressService().getAddresses();

    if (addresses.isNotEmpty) {
      if (mounted) {
        setState(() {
          _userAddress = addresses.firstWhere((a) => a.isDefault,
              orElse: () => addresses.first);
          _address = _userAddress!.address;
          _phone = _userAddress!.phone;
          // _lat & _lng would come from the API if present, ignoring for now
          _isLoadingLocation = false;
        });
      }
    } else {
      _determinePosition(); // Fallback to GPS
    }
  }

  Future<void> _fetchDeliveryCompanies() async {
    setState(() {
      _isLoadingDelivery = true;
      _deliveryError = null;
    });

    try {
      final companies = await DeliveryService().getDeliveryCompanies(forceRefresh: true);
      if (mounted) {
        setState(() {
          _deliveryCompanies = companies;
          if (companies.isNotEmpty) {
            _selectedDeliveryId = companies.first.id;
          }
          _isLoadingDelivery = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deliveryError = e.toString();
          _isLoadingDelivery = false;
        });
      }
    }
  }

  Future<void> _fetchCartItems() async {
    setState(() {
      _isLoadingCart = true;
    });

    final items = await CartService().getCartItems();

    if (mounted) {
      setState(() {
        _cartItems = items;
        _isLoadingCart = false;
      });
      Provider.of<CartProvider>(context, listen: false).updateCartLocally(items);
    }
  }
  
  Future<void> _handleRefresh() async {
    await Future.wait([
      _fetchCartItems(),
      _fetchDeliveryCompanies(),
      _loadUserAddress(),
    ]);
  }

  Future<void> _updateQuantity(CartItemModel item, int newQuantity) async {
    if (newQuantity < 1) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Optimistic UI update
    setState(() {
      item.quantity = newQuantity;
    });
    cartProvider.updateCartLocally(_cartItems);

    final errorMessage =
        await CartService().updateCartItemQuantity(item.id, newQuantity);
    if (errorMessage != null) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Error'),
          description: Text(errorMessage),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
        _fetchCartItems(); // Re-fetch to get correct state
      } else {
        cartProvider.fetchCartCount(); // Revert if unmounted
      }
    }
  }

  Future<void> _removeItem(int index, CartItemModel item) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Optimistic UI update
    setState(() {
      _cartItems.removeAt(index);
    });
    cartProvider.updateCartLocally(_cartItems);

    final success = await CartService().removeCartItem(item.id);
    if (!success) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Error'),
          description: const Text('Failed to remove item'),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
        _fetchCartItems(); // Re-fetch to get correct state
      } else {
        cartProvider.fetchCartCount(); // Revert
      }
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultAddress();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDefaultAddress();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultAddress();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Check if location is inside Cambodia
      if (position.latitude < 9.9 ||
          position.latitude > 14.7 ||
          position.longitude < 102.3 ||
          position.longitude > 107.8) {
        _setDefaultAddress();
        // Silently fail to default address for better UX
      } else {
        _getAddressFromLatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      _setDefaultAddress();
    }
  }

  void _setDefaultAddress() {
    if (!mounted) return;
    setState(() {
      _address =
          "ផ្ទះលេខ ១២៣, ផ្លូវ ៤៥៦, រាជធានីភ្នំពេញ"; // Default Phnom Penh address
      _lat = 11.5564;
      _lng = 104.9282;
      _isLoadingLocation = false;
    });
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _address =
                "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
            _lat = lat;
            _lng = lng;
            _isLoadingLocation = false;
          });
        }
      } else {
        _setDefaultAddress();
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
      _setDefaultAddress();
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
    });

    try {
      final result = await CartService().applyCoupon(code, _subtotal);
      if (mounted) {
        if (result != null && result.containsKey('discount_amount')) {
          setState(() {
            _discountAmount = (result['discount_amount'] as num).toDouble();
            _appliedCouponCode = code;
            _isApplyingCoupon = false;
          });
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Coupon Applied'),
            description: Text('You saved \$${_discountAmount.toStringAsFixed(2)}'),
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else {
          setState(() {
            _isApplyingCoupon = false;
          });
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('Invalid Coupon'),
            description: Text(result?['message'] ?? 'Failed to apply coupon'),
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApplyingCoupon = false;
        });
      }
    }
  }

  // ... (existing getters)

  // ... (existing builds)

  Widget _buildDeliveryHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddressEditPage(
                initialUserAddress: _userAddress,
                initialAddress: _address,
                initialPhone: _phone,
              ),
            ),
          );

          if (result != null && result is Map<String, dynamic>) {
            // Usually if it's new, we re-fetch all to get the right id and defaults
            _loadUserAddress();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF5a7335).withOpacity(0.12) : const Color(0xFF5a7335).withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF5a7335).withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              if (!isDark)
              BoxShadow(
                color: const Color(0xFF5a7335).withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Color(0xFF5a7335)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageService().translate('delivery_to'),
                          style: const TextStyle(
                            fontFamily: 'Hanuman',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _isLoadingLocation
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: GlobalLoader(size: 18),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Hanuman',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  if (_lat != null && _lng != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        "Lat: ${_lat!.toStringAsFixed(6)}, Lng: ${_lng!.toStringAsFixed(6)}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_rounded, color: Colors.grey, size: 20),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MapPickerPage()),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _address = result['address'];
                      if (result['latitude'] != null &&
                          result['longitude'] != null) {
                        _lat = result['latitude'];
                        _lng = result['longitude'];
                      }
                    });
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined,
                        color: Color(0xFF5a7335), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      LanguageService().translate('choose_on_map'),
                      style: const TextStyle(
                        fontFamily: 'Hanuman',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5a7335),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF5a7335), size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _subtotal {
    return _cartItems.fold(
        0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  double get _deliveryFee {
    if (_deliveryMethod == 'pickup') return 0.0;
    if (_deliveryCompanies.isEmpty || _selectedDeliveryId == null) return 0.0;

    final selectedCompany = _deliveryCompanies.firstWhere(
      (c) => c.id == _selectedDeliveryId,
      orElse: () => _deliveryCompanies.first,
    );

    // Simplification: just take the first shipping rate for now,
    // or further refine this by checking `locationName` against `_address` if multiple
    if (selectedCompany.shippingRates.isNotEmpty) {
      return selectedCompany.shippingRates.first.fee;
    }

    return 0.0;
  }

  double get _totalPrice => (_subtotal - _discountAmount) + _deliveryFee;

  Future<void> _handleCheckout() async {
    // 1. Validation
    if (_deliveryMethod == 'delivery') {
      if (_userAddress == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Please select or add a delivery address.")),
          );
        }
        return;
      }

      if (_selectedDeliveryId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a delivery method.")),
          );
        }
        return;
      }
    }

    // 2. Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GlobalLoader(isOverlay: true, message: 'Processing order...'),
    );

    try {
      // 3. Place Order
      final orderService = OrderService();
      final order = await orderService.placeOrder(
        deliveryMethod: _deliveryMethod,
        addressId: _deliveryMethod == 'delivery' ? _userAddress!.id : null,
        deliveryCompanyId: _deliveryMethod == 'delivery' ? _selectedDeliveryId! : null,
        couponCode: _appliedCouponCode,
      );

      // 4. Create Payment
      final paymentService = PaymentService();
      final payment = await paymentService.createPayment(
        orderId: order!.id,
        method: _paymentMethod, 
      );

      if (payment != null) {
        // Close loading dialog before moving
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (_paymentMethod == 'cash') {
           // Cash is immediately successful
           if (mounted) {
             setState(() { _cartItems.clear(); });
             Provider.of<CartProvider>(context, listen: false).updateCartLocally([]);
             Provider.of<CartProvider>(context, listen: false).fetchCartCount();
             
             toastification.show(
                context: context,
                title: const Text("ការបញ្ជាទិញបានជោគជ័យ! (Order Successful)"),
                type: ToastificationType.success,
                style: ToastificationStyle.flat,
                autoCloseDuration: const Duration(seconds: 4),
             );
           }
        } else {
            // 5. Navigate to Payment Page (bakong)
            if (mounted) {
              final success = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentPage(payment: payment),
                ),
              );

              if (success == true && mounted) {
                // Success!
                setState(() { _cartItems.clear(); });
                Provider.of<CartProvider>(context, listen: false).updateCartLocally([]);
                Provider.of<CartProvider>(context, listen: false).fetchCartCount();
              }
            }
        }
      } else {
        throw Exception("Failed to generate payment details");
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if it's still open
        Navigator.of(context, rootNavigator: true).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Checkout Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          LanguageService().translate('cart_title'),
          style: TextStyle(
            fontFamily: 'Hanuman',
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),

          // New Delivery Method Selector (Delivery vs Pick Up)
          _buildDeliveryTypeSelector(),
          const SizedBox(height: 5),

          if (_deliveryMethod == 'delivery') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSectionTitle("ជ្រើសរើសការដឹកជញ្ជូន (Delivery Method)"),
            ),
            _buildDeliverySelector(),
            const SizedBox(height: 5),
            // 1. New "Friendly" Delivery Header
            _buildDeliveryHeader(),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: _isLoadingCart
                ? const Center(child: GlobalLoader(size: 40))
                : _cartItems.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                            left: 20, right: 20, top: 10, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cart Items List
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _cartItems.length,
                              itemBuilder: (context, index) {
                                final item = _cartItems[index];
                                return _buildCartItem(item, index);
                              },
                            ),

                            const SizedBox(height: 32),
                            

                            const SizedBox(height: 32),
                            

                            const SizedBox(height: 120), // Space for bottom bar
                          ],
                        ),
                      ),
            ),
          ),

          // Pinned Checkout Bar
          _buildCheckoutBar(),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _removeItem(index, item),
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: _buildCartItemCard(item, index, theme, isDark),
    );
  }

  Widget _buildDeliveryTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_deliveryMethod != 'delivery') {
                    setState(() => _deliveryMethod = 'delivery');
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: _deliveryMethod == 'delivery' 
                        ? const LinearGradient(colors: [Color(0xFF5a7335), Color(0xFF718F42)])
                        : null,
                    color: _deliveryMethod == 'delivery' ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _deliveryMethod == 'delivery' ? [
                      BoxShadow(
                        color: const Color(0xFF5a7335).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ] : [],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined, 
                        size: 18,
                        color: _deliveryMethod == 'delivery' ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LanguageService().translate("delivery") ?? "ដឹកជញ្ជូន",
                        style: TextStyle(
                          fontFamily: 'Hanuman',
                          color: _deliveryMethod == 'delivery' ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_deliveryMethod != 'pickup') {
                    setState(() => _deliveryMethod = 'pickup');
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: _deliveryMethod == 'pickup' 
                        ? const LinearGradient(colors: [Color(0xFF5a7335), Color(0xFF718F42)])
                        : null,
                    color: _deliveryMethod == 'pickup' ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _deliveryMethod == 'pickup' ? [
                      BoxShadow(
                        color: const Color(0xFF5a7335).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ] : [],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_outlined, 
                        size: 18,
                        color: _deliveryMethod == 'pickup' ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LanguageService().translate("pickup") ?? "មកយកផ្ទាល់",
                        style: TextStyle(
                          fontFamily: 'Hanuman',
                          color: _deliveryMethod == 'pickup' ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_paymentMethod != 'bakong') {
                  setState(() => _paymentMethod = 'bakong');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: _paymentMethod == 'bakong' 
                      ? const LinearGradient(colors: [Color(0xFF5a7335), Color(0xFF718F42)])
                      : null,
                  color: _paymentMethod == 'bakong' ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _paymentMethod == 'bakong' ? [
                    BoxShadow(
                      color: const Color(0xFF5a7335).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ] : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner, 
                      size: 18,
                      color: _paymentMethod == 'bakong' ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LanguageService().translate("pay_khqr") ?? "ស្កេន KHQR",
                      style: TextStyle(
                        fontFamily: 'Hanuman',
                        color: _paymentMethod == 'bakong' ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_paymentMethod != 'cash') {
                  setState(() => _paymentMethod = 'cash');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: _paymentMethod == 'cash' 
                      ? const LinearGradient(colors: [Color(0xFF5a7335), Color(0xFF718F42)])
                      : null,
                  color: _paymentMethod == 'cash' ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _paymentMethod == 'cash' ? [
                    BoxShadow(
                      color: const Color(0xFF5a7335).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ] : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payments_outlined, 
                      size: 18,
                      color: _paymentMethod == 'cash' ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LanguageService().translate("pay_cash") ?? "សាច់ប្រាក់",
                      style: TextStyle(
                        fontFamily: 'Hanuman',
                        color: _paymentMethod == 'cash' ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Hanuman',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5a7335),
        ),
      ),
    );
  }

  Widget _buildDeliverySelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoadingDelivery) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(child: GlobalLoader(size: 30)),
      );
    }

    // Show error state with retry
    if (_deliveryError != null || _deliveryCompanies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_deliveryError != null)
              Text(
                'Error: $_deliveryError',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              )
            else
              Text(
                'No delivery options available.',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchDeliveryCompanies,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5a7335),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _deliveryCompanies.map((company) {
          final isSelected = _selectedDeliveryId == company.id;

          // Fallbacks if no shipping rates exist
          final String duration = company.shippingRates.isNotEmpty &&
                  company.shippingRates.first.estimatedDays != null
              ? "${company.shippingRates.first.estimatedDays} Days"
              : "N/A";
          final double price = company.shippingRates.isNotEmpty
              ? company.shippingRates.first.fee
              : 0.0;

          // Calculate active logo path
          final logoUrl = company.logoPath.isNotEmpty &&
                  company.logoPath != 'null'
              ? company.logoPath
              : null;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDeliveryId = company.id;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? const Color(0xFF5a7335).withOpacity(0.3)
                        : const Color(0xFF5a7335).withOpacity(0.1))
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(20), // More rounded pill
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF5a7335) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                          image: logoUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(logoUrl),
                                  fit: BoxFit.contain,
                                )
                              : null,
                    ),
                    child: logoUrl == null
                        ? const Icon(Icons.local_shipping_outlined,
                            color: Colors.grey, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        company.name,
                        style: TextStyle(
                          fontFamily: 'Hanuman',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected
                              ? const Color(0xFF5a7335)
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            duration,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "\$${price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF5a7335),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCartItemCard(
      CartItemModel item, int index, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover
                Hero(
                  tag: 'cart_book_${item.bookId}',
                  child: Container(
                    width: 82,
                    height: 125,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ],
                      image: (item.bookImage != null && item.bookImage!.isNotEmpty)
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(item.bookImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (item.bookImage == null || item.bookImage!.isEmpty)
                        ? const Center(
                            child: Icon(Icons.book_rounded,
                                size: 32, color: Colors.grey))
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // Right side details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Padding for delete button
                      const SizedBox(height: 4),

                      // Title
                      Text(
                        item.bookTitle ?? 'Unknown Book',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.3,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Author name row
                      if (item.bookAuthor != null && item.bookAuthor!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 13, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.bookAuthor!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 14),

                      // Bottom row: Price + Quantity
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${item.unitPrice.toStringAsFixed(2)} / pc',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF5a7335), Color(0xFF7aad45)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Quantity Control
                          _buildQuantityControl(item, index),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Delete button (top-right corner)
          Positioned(
            top: 8,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _removeItem(index, item),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(CartItemModel item, int index) {
    final theme = Theme.of(context);
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          _buildQuantityBtn(Icons.remove, () {
            if (item.quantity > 1) {
              _updateQuantity(item, item.quantity - 1);
            }
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            child: Text(
              "${item.quantity}",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          _buildQuantityBtn(Icons.add, () {
            _updateQuantity(item, item.quantity + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildQuantityBtn(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 32,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value,
      {bool isDiscount = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.grey[600], fontFamily: 'Hanuman', fontSize: 14),
        ),
        Text(
          "${isDiscount ? '-' : ''}\$${value.abs().toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.green : theme.textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Promo Code Section
            _buildPromoCodeSection(),
            const SizedBox(height: 16),
            
            // Payment Method Selector
            _buildPaymentTypeSelector(),
            const SizedBox(height: 15),

            // Order Summary toggle
            InkWell(
              onTap: () {
                setState(() {
                  _isSummaryExpanded = !_isSummaryExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LanguageService().translate('order_summary'),
                    style: TextStyle(
                      fontFamily: 'Hanuman',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Icon(
                    _isSummaryExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: const Color(0xFF5a7335),
                  ),
                ],
              ),
            ),
            
            // Collapsible Summary
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                height: _isSummaryExpanded ? null : 0,
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    _buildSummaryRow(LanguageService().translate('subtotal'), _subtotal),
                    if (_discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                          LanguageService().translate('discount') ?? 'Discount',
                          _discountAmount,
                          isDiscount: true),
                    ],
                    const SizedBox(height: 8),
                    _buildSummaryRow(LanguageService().translate('delivery_fee'), _deliveryFee),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                  ],
                ),
              ),
            ),

            // Total and Checkout Button
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService().translate('total') ?? "សរុប",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Hanuman'),
                    ),
                    Text(
                      "\$${_totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF5E7D32)),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _cartItems.isEmpty 
                            ? [Colors.grey.shade400, Colors.grey.shade500]
                            : [const Color(0xFF5a7335), const Color(0xFF7aad45)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _cartItems.isEmpty ? [] : [
                        BoxShadow(
                          color: const Color(0xFF5a7335).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _cartItems.isEmpty ? null : _handleCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            LanguageService().translate('checkout') ?? "ទូទាត់ប្រាក់",
                            style: const TextStyle(fontFamily: 'Hanuman', fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              LanguageService().translate('empty_cart'),
              style: const TextStyle(
                fontFamily: 'Hanuman',
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _appliedCouponCode != null 
                  ? Colors.green.withOpacity(0.5) 
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                _appliedCouponCode != null ? Icons.verified_rounded : Icons.confirmation_num_outlined,
                size: 20,
                color: _appliedCouponCode != null ? Colors.green : Colors.grey[600],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _couponController,
                  enabled: _appliedCouponCode == null,
                  decoration: InputDecoration(
                    hintText: LanguageService().translate('enter_code') ?? 'Promo Code',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13, fontFamily: 'Hanuman'),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Hanuman',
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (_appliedCouponCode == null)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5a7335),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _isApplyingCoupon ? null : _applyCoupon,
                      icon: _isApplyingCoupon 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: () {
                    setState(() {
                      _appliedCouponCode = null;
                      _discountAmount = 0.0;
                      _couponController.clear();
                    });
                  },
                  icon: const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                ),
              const SizedBox(width: 6),
            ],
          ),
        ),
        if (_appliedCouponCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Saved \$${_discountAmount.toStringAsFixed(2)} with "$_appliedCouponCode"',
                  style: const TextStyle(
                    color: Colors.green, 
                    fontSize: 12, 
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Hanuman'
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
