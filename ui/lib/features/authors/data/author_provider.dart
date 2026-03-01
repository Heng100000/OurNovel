import 'package:flutter/material.dart';
import '../../home/data/author_service.dart';
import '../../../core/models/author.dart';

class AuthorProvider extends ChangeNotifier {
  final AuthorService _authorService = AuthorService();
  
  List<Author> _authors = [];
  List<Author> get authors => _authors;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _error = '';
  String get error => _error;

  Future<void> fetchAuthors() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _authors = await _authorService.getAllAuthors();
    } catch (e) {
      _error = 'Failed to fetch authors. Please try again.';
      debugPrint('Error fetching authors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
