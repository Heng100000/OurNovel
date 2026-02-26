import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'address_edit_page.dart';
import '../features/menu/presentation/pages/menu_page.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/pages/login_page.dart';

import '../l10n/language_service.dart';
import '../theme/theme_service.dart'; // Import ThemeService

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  int _selectedAvatarIndex = 0;
  File? _pickedImage;
  
  // User Info State
  String _userName = "Linh Sokheng";
  String _userEmail = "heng@gmail.com";

  // Helper to access global translations
  String _get(String key) {
    return LanguageService().translate(key);
  }

  final List<String> _avatarOptions = [
    "https://i.pravatar.cc/150?img=12", // Default
    "https://i.pravatar.cc/150?img=33",
    "https://i.pravatar.cc/150?img=5",
    "https://i.pravatar.cc/150?img=68",
    "https://i.pravatar.cc/150?img=20",
    "https://i.pravatar.cc/150?img=1",
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  // --- Logic Methods ---

  void _showAvatarSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                _get('select_photo'),
                style: const TextStyle(
                  fontFamily: 'Hanuman',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // ... GridView logic
             GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _avatarOptions.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatarIndex = index;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedAvatarIndex == index 
                              ? const Color(0xFF5a7335) 
                              : Colors.transparent,
                          width: 3,
                        ),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(_avatarOptions[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
               ListTile(
                 leading: const Icon(Icons.photo_library, color: Color(0xFF5a7335)),
                 title: Text(_get('gallery'), style: const TextStyle(fontFamily: 'Hanuman')),
                 onTap: () {
                   Navigator.pop(context);
                   _pickImage();
                 },
               )
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_get('edit_profile'), style: const TextStyle(fontFamily: 'Hanuman')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: _get('name'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: _get('email'), border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_get('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = nameController.text;
                _userEmail = emailController.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(_get('profile_updated'))),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5a7335)),
            child: Text(_get('save')),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(_get('choose_language'), style: const TextStyle(fontSize: 18, fontFamily: 'Hanuman', fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text("🇰🇭", style: TextStyle(fontSize: 24)),
              title: Text(_get('khmer'), style: const TextStyle(fontFamily: 'Hanuman')),
              onTap: () {
                LanguageService().switchLanguage('km');
                Navigator.pop(context);
              },
              trailing: LanguageService().currentLanguage.value == 'km' ? const Icon(Icons.check, color: Color(0xFF5a7335)) : null,
            ),
            ListTile(
              leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
              title: Text(_get('english'), style: const TextStyle(fontFamily: 'Hanuman')),
              onTap: () {
                LanguageService().switchLanguage('en');
                Navigator.pop(context);
              },
               trailing: LanguageService().currentLanguage.value == 'en' ? const Icon(Icons.check, color: Color(0xFF5a7335)) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_get('logout'), style: const TextStyle(fontFamily: 'Hanuman')),
        content: Text(_get('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_get('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Call Logout API and clear local storage
              await AuthService().logout();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_get('logged_out'))),
                );
                
                // Redirect to Login Page
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(_get('logout')),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: 'Hanuman')),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_get('close'), style: const TextStyle(color: Color(0xFF5a7335))),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().currentLanguage,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          drawer: const SideMenuDrawer(),
          appBar: AppBar(
            title: Text(
              _get('settings'), // Settings
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
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: theme.iconTheme.color),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor, // Use cardColor
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showAvatarSelection,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            image: DecorationImage(
                              image: _pickedImage != null 
                                  ? FileImage(_pickedImage!) as ImageProvider
                                  : CachedNetworkImageProvider(_avatarOptions[_selectedAvatarIndex]),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: const Color(0xFF5a7335), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              _userName,
                              style: TextStyle(
                                fontFamily: 'Hanuman',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userEmail,
                              style: const TextStyle(
                                fontFamily: 'Hanuman',
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showEditProfileDialog,
                        icon: const Icon(Icons.edit_rounded, color: Color(0xFF5a7335)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // General Settings
                _buildSectionHeader(_get('general')),
                _buildSettingTile(
                  icon: Icons.language,
                  title: _get('language'),
                  subtitle: language == 'km' ? "ខ្មែរ" : "English",
                  onTap: _showLanguageSelection,
                ),
                _buildSettingTile(
                  icon: Icons.dark_mode_outlined,
                  title: _get('dark_mode'),
                  trailing: Consumer<ThemeService>(
                    builder: (context, themeService, _) {
                      return Switch(
                        value: themeService.isDarkMode,
                        activeColor: const Color(0xFF5a7335),
                        onChanged: (value) {
                          themeService.toggleTheme();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? _get('dark_mode_on') : _get('dark_mode_off')),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.notifications_outlined,
                  title: _get('notifications'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeColor: const Color(0xFF5a7335),
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // Account Settings
                _buildSectionHeader(_get('account')),
                _buildSettingTile(
                  icon: Icons.person_outline,
                  title: _get('personal_info'),
                  onTap: _showEditProfileDialog,
                ),
                _buildSettingTile(
                  icon: Icons.location_on_outlined,
                  title: _get('addresses'),
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddressEditPage()),
                    );
                  },
                ),
                 _buildSettingTile(
                  icon: Icons.lock_outline,
                  title: _get('security'),
                  onTap: () => _showInfoDialog(_get('security'), _get('change_password')),
                ),

                const SizedBox(height: 25),

                // Support
                 _buildSectionHeader(_get('support')),
                _buildSettingTile(
                  icon: Icons.help_outline,
                  title: _get('help_center'),
                  onTap: () => _showInfoDialog(_get('help_center'), _get('contact_support')),
                ),
                 _buildSettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: _get('privacy_policy'),
                  onTap: () => _showInfoDialog(_get('privacy_policy'), _get('privacy_msg')),
                ),
                 _buildSettingTile(
                  icon: Icons.info_outline,
                  title: _get('about_us'),
                  onTap: () => _showInfoDialog(_get('about_us'), _get('about_msg')),
                ),

                const SizedBox(height: 40),
                
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _showLogoutDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _get('logout'),
                      style: const TextStyle(
                        fontFamily: 'Hanuman',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Hanuman',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon, 
    required String title, 
    String? subtitle, 
    Widget? trailing, 
    VoidCallback? onTap
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor, // Use cardColor
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF5a7335).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF5a7335), size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Hanuman',
            fontWeight: FontWeight.bold,
            fontSize: 15, // Slightly larger font
            color: theme.textTheme.bodyLarge?.color, // Dynamic color
          ),
        ),
        subtitle: subtitle != null 
          ? Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Hanuman',
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ) 
          : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }


}
