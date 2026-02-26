import '../../../core/models/author.dart';
import '../../../core/models/category.dart';
import '../../../core/models/book.dart';

class DataCache {
  static final DataCache _instance = DataCache._internal();
  factory DataCache() => _instance;
  DataCache._internal();

  List<Author>? _authors;
  List<Category>? _categories;
  List<Book>? _allBooks;
  DateTime? _lastFetch;

  List<Author>? get authors => _authors;
  List<Category>? get categories => _categories;
  List<Book>? get allBooks => _allBooks;

  bool get hasAuthors => _authors != null && _authors!.isNotEmpty;
  bool get hasCategories => _categories != null && _categories!.isNotEmpty;
  bool get hasAllBooks => _allBooks != null && _allBooks!.isNotEmpty;

  void setAuthors(List<Author> authors) {
    _authors = authors;
    _lastFetch = DateTime.now();
  }

  void setCategories(List<Category> categories) {
    _categories = categories;
    _lastFetch = DateTime.now();
  }

  void setAllBooks(List<Book> books) {
    _allBooks = books;
    _lastFetch = DateTime.now();
  }

  void clear() {
    _authors = null;
    _categories = null;
    _allBooks = null;
    _lastFetch = null;
  }

  bool isCacheExpired() {
    if (_lastFetch == null) return true;
    // Cache for 5 minutes
    return DateTime.now().difference(_lastFetch!) > const Duration(minutes: 5);
  }
}
