import 'package:flutter/material.dart';
import 'cart_service.dart';
import 'cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  int _itemCount = 0;
  List<CartItemModel> _items = [];

  int get itemCount => _itemCount;
  List<CartItemModel> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchCartCount() async {
    _isLoading = true;
    notifyListeners();

    try {
      final items = await _cartService.getCartItems();
      _items = items;
      _itemCount = items.fold(0, (sum, item) => sum + item.quantity);
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int getQuantity(int bookId) {
    try {
      final item = _items.firstWhere((item) => item.bookId == bookId);
      return item.quantity;
    } catch (e) {
      return 0; // Not in cart
    }
  }

  void updateCount(int newCount) {
    _itemCount = newCount;
    notifyListeners();
  }

  void updateCartLocally(List<CartItemModel> newItems) {
    _items = List.from(newItems);
    _itemCount = _items.fold(0, (sum, item) => sum + item.quantity);
    notifyListeners();
  }
}
