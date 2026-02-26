import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  // --- Replaced with dynamic data from API ---

  // Address State
  UserAddress? _userAddress;
  String _address = "Locating..."; // Fallbacks if no address saved
  String _phone = "012 345 678";
  double? _lat;
  double? _lng;
  bool _isLoadingLocation = true;

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
    });

    final companies = await DeliveryService().getDeliveryCompanies();

    if (mounted) {
      setState(() {
        _deliveryCompanies = companies;
        if (companies.isNotEmpty) {
          _selectedDeliveryId = companies.first.id;
        }
        _isLoadingDelivery = false;
      });
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
    }
  }

  Future<void> _updateQuantity(CartItemModel item, int newQuantity) async {
    if (newQuantity < 1) return;

    // Optimistic UI update
    setState(() {
      item.quantity = newQuantity;
    });

    final errorMessage =
        await CartService().updateCartItemQuantity(item.id, newQuantity);
    if (errorMessage != null && mounted) {
      // Revert if failed
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
    } else if (mounted) {
      final newTotalCount = _cartItems.fold(0, (sum, item) => sum + item.quantity);
      Provider.of<CartProvider>(context, listen: false).updateCount(newTotalCount);
    }
  }

  Future<void> _removeItem(int index, CartItemModel item) async {
    // Optimistic UI update
    setState(() {
      _cartItems.removeAt(index);
    });

    final success = await CartService().removeCartItem(item.id);
    if (!success && mounted) {
      // Revert if failed
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
    } else if (mounted) {
      final newTotalCount = _cartItems.fold(0, (sum, item) => sum + item.quantity);
      Provider.of<CartProvider>(context, listen: false).updateCount(newTotalCount);
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                const Color(0xFF5a7335).withOpacity(0.08), // Light green tint
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF5a7335).withOpacity(0.2)),
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
                            ? SizedBox(
                                height: 15,
                                width: 15,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.textTheme.bodyLarge?.color))
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

  double get _totalPrice => _subtotal + _deliveryFee;

  Future<void> _handleCheckout() async {
    // 1. Validation
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

    // 2. Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF5a7335))),
    );

    try {
      // 3. Place Order
      final orderService = OrderService();
      final order = await orderService.placeOrder(
        addressId: _userAddress!.id,
        deliveryCompanyId: _selectedDeliveryId!,
      );

      // 4. Create Payment
      final paymentService = PaymentService();
      final payment = await paymentService.createPayment(
        orderId: order!.id,
        method: 'bakong', // Default to bakong for KHQR
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (payment != null) {
        // 5. Navigate to Payment Page
        if (mounted) {
          final success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPage(payment: payment),
            ),
          );

          if (success == true && mounted) {
            setState(() {
              _cartItems.clear();
              _fetchCartItems(); // Re-fetch to be sure
              // Update global cart count
              if (mounted) {
                Provider.of<CartProvider>(context, listen: false)
                    .fetchCartCount();
              }
            });
          }
        }
      } else {
        throw Exception("Failed to generate payment details");
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger already handles showing errors in createPayment/placeOrder usually
        // but let's be explicit here if they return null without printing
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSectionTitle("ជ្រើសរើសការដឹកជញ្ជូន (Delivery Method)"),
          ),
          _buildDeliverySelector(),
          const SizedBox(height: 5),

          // 1. New "Friendly" Delivery Header
          _buildDeliveryHeader(),

          Expanded(
            child: _isLoadingCart
                ? const Center(child: CircularProgressIndicator())
                : _cartItems.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
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

                            const SizedBox(height: 20),

                            const SizedBox(height: 100), // Space for bottom bar
                          ],
                        ),
                      ),
          ),

          // Pinned Checkout Bar with Order Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Order Summary inside Bottom Sheet
                  // Collapsible Header
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

                  // Collapsible Content
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      height: _isSummaryExpanded ? null : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          _buildSummaryRow(
                              LanguageService().translate('subtotal'),
                              _subtotal),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                              LanguageService().translate('delivery_fee'),
                              _deliveryFee),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                LanguageService().translate('total'),
                                style: TextStyle(
                                  fontFamily: 'Hanuman',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                "\$${_totalPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5a7335),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _cartItems.isEmpty ? null : _handleCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5a7335),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            LanguageService().translate('checkout'),
                            style: const TextStyle(
                              fontFamily: 'Hanuman',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_deliveryCompanies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          "No delivery options available.",
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
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
              ? "${ApiConstants.baseUrl.replaceAll('/api', '')}/storage/${company.logoPath}"
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 70,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
              image: (item.bookImage != null && item.bookImage!.isNotEmpty)
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(item.bookImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (item.bookImage == null || item.bookImage!.isEmpty)
                ? const Center(
                    child: Icon(Icons.book, size: 30, color: Colors.grey))
                : null,
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.bookTitle ?? 'Unknown Book',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "\$${item.unitPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF5a7335), // Green Price
                  ),
                ),
              ],
            ),
          ),

          // Quantity
          _buildQuantityControl(item, index),
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

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "សង្ខេបការបញ្ជាទិញ (Summary)",
            style: TextStyle(
              fontFamily: 'Hanuman',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow("សរុប (Subtotal)", _subtotal),
          const SizedBox(height: 12),
          _buildSummaryRow("ដឹកជញ្ជូន (Delivery)", _deliveryFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ទឹកប្រាក់សរុប", // Total
                style: TextStyle(
                  fontFamily: 'Hanuman',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "\$${_totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5a7335),
                ),
              ),
            ],
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _cartItems.isEmpty ? null : _handleCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5a7335),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  LanguageService().translate('checkout'),
                  style: const TextStyle(
                    fontFamily: 'Hanuman',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
    );
  }
}
