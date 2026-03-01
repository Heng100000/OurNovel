import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/auth_landing_page.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'l10n/language_service.dart';
import 'theme/theme_service.dart';
import 'theme/app_theme.dart';
import 'widget/home_screen.dart';
import 'widget/cart_page.dart';
import 'widget/address_edit_page.dart';
import 'widget/map_picker_page.dart';
import 'widget/settings_page.dart';
import 'widget/wishlist_page.dart';
import 'Book/book_store.dart';
import 'features/promotions/presentation/pages/promotions_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/invoice/presentation/pages/invoice_page.dart';
import 'features/notifications/data/notification_provider.dart';
import 'features/wishlist/data/wishlist_provider.dart';
import 'features/cart/data/cart_provider.dart';
import 'features/authors/data/author_provider.dart';
import 'features/authors/presentation/pages/authors_page.dart';
import 'features/auth/data/user_provider.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/realtime_service.dart';

// Global RouteObserver for detecting navigation events (e.g., returning to a page)
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize services with persistence
  await ThemeService().init();
  await LanguageService().init();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize WebSockets locally
  await RealtimeService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => LanguageService()), // Add LanguageService as ChangeNotifier
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthorProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, languageService, _) {
        return ToastificationWrapper(
          child: MaterialApp(
            title: 'Our Novel',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeService.themeMode,
            home: const SplashScreen(),
            navigatorObservers: [routeObserver],
            routes: {
              '/auth_landing': (context) => const AuthLandingPage(),
              '/login': (context) => const LoginPage(),
              '/home': (context) => const HomeScreen(),
              '/cart': (context) => const CartPage(),
              '/address_edit': (context) => const AddressEditPage(),
              '/map_picker': (context) => const MapPickerPage(),
              '/settings': (context) => const SettingsPage(),
              '/wishlist': (context) => const WishlistPage(),
              '/notifications': (context) => const NotificationsPage(),
              '/promotions': (context) => const PromotionsPage(),
              '/book_store': (context) => const BookStorePage(),
              '/invoice': (context) => const InvoicePage(),
              '/authors': (context) => const AuthorsPage(),
            },
          ),
        );
      },
    );
  }
}

