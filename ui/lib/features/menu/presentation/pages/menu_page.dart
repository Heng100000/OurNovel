import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../features/auth/data/user_provider.dart';
import '../../../../theme/theme_service.dart';
import '../../../../l10n/language_service.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SideMenuDrawer(),
    );
  }
}

class SideMenuDrawer extends StatefulWidget {
  const SideMenuDrawer({super.key});

  @override
  State<SideMenuDrawer> createState() => _SideMenuDrawerState();
}

class _SideMenuDrawerState extends State<SideMenuDrawer> {
  Uint8List? _logoBytes;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/images/logo_full.png');
      if (mounted) setState(() => _logoBytes = data.buffer.asUint8List());
    } catch (_) {}
  }

  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final userProvider = Provider.of<UserProvider>(context);

    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, langService, child) {
        final isDark = themeService.isDarkMode;
        final drawerBg = isDark ? const Color(0xFF1A2410) : AppColors.primary;
        final textColor = Colors.white;
        final subTextColor = Colors.white70;

        return Drawer(
          backgroundColor: drawerBg,
          child: SafeArea(
            child: Column(
              children: [
                // Header - App Logo
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo image at full width, tinted white
                      if (_logoBytes != null)
                        Image.memory(
                          _logoBytes!,
                          height: 48,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                        )
                      else
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(Icons.menu_book_rounded, color: drawerBg, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              langService.translate('app_name'),
                              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Text(
                        langService.translate('tagline'),
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Menu Items List
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMenuItem(Icons.home_outlined, langService.translate('home'), currentRoute == '/home' || currentRoute == '/', () {
                          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                        }),
                        _buildMenuItem(Icons.notifications_none_outlined, langService.translate('notifications'), currentRoute == '/notifications', () {
                          if (currentRoute == '/notifications') {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamed(context, '/notifications');
                          }
                        }),
                        _buildMenuItem(Icons.receipt_long_outlined, langService.translate('invoice'), currentRoute == '/invoice', () {
                          if (currentRoute == '/invoice') {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamed(context, '/invoice');
                          }
                        }),
                        _buildMenuItem(Icons.menu_book_outlined, langService.translate('book_store'), currentRoute == '/book_store', () {
                          if (currentRoute == '/book_store') {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamed(context, '/book_store');
                          }
                        }),
                        _buildMenuItem(Icons.local_offer_outlined, langService.translate('promotions'), currentRoute == '/promotions', () {
                          if (currentRoute == '/promotions') {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamed(context, '/promotions');
                          }
                        }),
                        _buildMenuItem(Icons.people_outline, langService.translate('authors'), currentRoute == '/authors', () {
                          if (currentRoute == '/authors') {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamed(context, '/authors');
                          }
                        }),
                        
                        Divider(color: Colors.white.withOpacity(0.2), height: 30),
                        
                        _buildMenuItem(Icons.phone_outlined, langService.translate('contact'), false, () {}),
                        _buildMenuItem(Icons.info_outline, langService.translate('about_us'), false, () {}),
                        _buildMenuItem(Icons.settings_outlined, langService.translate('settings'), currentRoute == '/settings', () {
                          if (currentRoute == '/settings') {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamed(context, '/settings');
                          }
                        }),
                      ],
                    ),
                  ),
                ),

                // Footer - User Profile (Reactive)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                       Builder(
                        builder: (context) {
                          final avatarUrl = userProvider.effectiveAvatarUrl;
                          return CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.accentYellow,
                            backgroundImage: CachedNetworkImageProvider(avatarUrl),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProvider.name,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userProvider.email,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                           await AuthService().logout();
                           if (context.mounted) {
                             Navigator.pushAndRemoveUntil(
                               context,
                               MaterialPageRoute(builder: (context) => const LoginPage()),
                               (route) => false,
                             );
                           }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red.shade300.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                        ),
                      )
                    ],
                  ),
                ),
                
                // Bottom Logo
                 Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, color: subTextColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        langService.translate('app_name'),
                        style: TextStyle(
                          color: subTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isActive, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? AppColors.accentYellow : Colors.white),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.accentYellow : Colors.white,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }
}
