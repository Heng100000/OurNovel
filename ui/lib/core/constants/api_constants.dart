class ApiConstants {
  // Base URL for Android Emulator to access localhost (Laravel Serve)
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Auth Endpoints
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout = '$baseUrl/logout';
  // Notification Endpoints
  static const String notifications = '$baseUrl/notifications';
  // Author Endpoints
  static const String authors = '$baseUrl/authors';
  // Category Endpoints
  static const String categories = '$baseUrl/categories';
  // Book Endpoints
  static const String books = '$baseUrl/books';
  // Cart Endpoints
  static const String cart = '$baseUrl/cart';
  // Review Endpoints
  static const String reviews = '$baseUrl/reviews';
  // Order Endpoints
  static const String orders = '$baseUrl/orders';
  // Payment Endpoints
  static const String payments = '$baseUrl/payments';
  // Invoice Endpoints
  static const String invoices = '$baseUrl/invoices';
  // Wishlist Endpoints
  static const String wishlist = '$baseUrl/wishlist';
}
