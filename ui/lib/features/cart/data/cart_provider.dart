import 'package:flutter/material.dart';
import 'cart_service.dart';
import 'cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  int _itemCount = 0;
  int get itemCount => _itemCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchCartCount() async {
    _isLoading = true;
    notifyListeners();

    try {
      final items = await _cartService.getCartItems();
      _itemCount = items.fold(0, (sum, item) => sum + item.quantity);
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateCount(int newCount) {
    _itemCount = newCount;
    notifyListeners();
  }
}
