class ApiConstants {
  // Static toggle to switch between Local IP and ngrok
  // Set this to true if you are using ngrok for testing
  static const bool useNgrok = false;

  // Use your computer's IP address (from ipconfig)
  static const String localIp = '192.168.18.4'; // <--- Change this to your PC's IP

  // Change this to the URL you get from running 'ngrok http 127.0.0.1:8001'
  static const String ngrokUrl = 'https://YOUR-URL.ngrok-free.app';

  // Reverb / WebSocket Settings
  static const String pusherKey = 'pore5j1hjthluaf70rhh';
  static const int reverbPort = 8080;

  static const String baseUrl = useNgrok
      ? '$ngrokUrl/api'
      : 'http://$localIp:8001/api';

  static const String baseImageUrl = useNgrok
      ? '$ngrokUrl/storage'
      : 'http://$localIp:8001/storage';

  // WebSocket URL (Reverb)
  static const String wsUrl = useNgrok
      ? 'wss://$ngrokUrl/app/$pusherKey?protocol=7&client=js&version=8.4.0&flash=false'
      : 'ws://$localIp:$reverbPort/app/$pusherKey?protocol=7&client=js&version=8.4.0&flash=false';

  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout = '$baseUrl/logout';
  static const String googleLogin = '$baseUrl/auth/google/login';
  static const String facebookLogin = '$baseUrl/auth/facebook/login';
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
  // Banner Endpoints
  static const String banners = '$baseUrl/banners';
  // News Endpoints
  static const String newsAnnouncements = '$baseUrl/news-announcements';
  // Event & Promotion Endpoints
  static const String events = '$baseUrl/events';
  static const String promotions = '$baseUrl/promotions';
  // Delivery Endpoints
  static const String deliveryCompanies = '$baseUrl/delivery-companies';
  static const String userProfile = '$baseUrl/user/profile';
  // Device Endpoints
  static const String devices = '$baseUrl/devices';
}
