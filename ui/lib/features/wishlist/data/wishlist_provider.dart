import 'package:flutter/material.dart';
import '../../home/data/wishlist_service.dart';
import '../../../core/models/book.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistService _service = WishlistService();
  Set<int> _wishlistedIds = {};
  List<Book> _items = [];
  bool _isLoading = false;

  Set<int> get wishlistedIds => _wishlistedIds;
  List<Book> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> fetchWishlist() async {
    _isLoading = true;
    notifyListeners();
    try {
      final books = await _service.getWishlist();
      _items = books;
      _wishlistedIds = books.map((b) => b.id).toSet();
    } catch (e) {
      debugPrint('Error fetching wishlist in provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isWishlisted(int bookId) {
    return _wishlistedIds.contains(bookId);
  }

  Future<bool> toggleWishlist(Book book) async {
    final alreadyWishlisted = _wishlistedIds.contains(book.id);
    
    // Optimistic UI update
    if (alreadyWishlisted) {
      _wishlistedIds.remove(book.id);
      _items.removeWhere((item) => item.id == book.id);
    } else {
      _wishlistedIds.add(book.id);
      _items.add(book);
    }
    notifyListeners();

    bool success;
    if (alreadyWishlisted) {
      success = await _service.removeFromWishlist(book.id);
    } else {
      success = await _service.addToWishlist(book.id);
    }

    if (!success) {
      // Revert on failure
      if (alreadyWishlisted) {
        _wishlistedIds.add(book.id);
        _items.add(book);
      } else {
        _wishlistedIds.remove(book.id);
        _items.removeWhere((item) => item.id == book.id);
      }
      notifyListeners();
    }
    return success;
  }

  // Explicitly remove an item (useful for WishlistPage)
  Future<bool> removeItem(int bookId) async {
    final success = await _service.removeFromWishlist(bookId);
    if (success) {
      _wishlistedIds.remove(bookId);
      _items.removeWhere((item) => item.id == bookId);
      notifyListeners();
    }
    return success;
  }
}
