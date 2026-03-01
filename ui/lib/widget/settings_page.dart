import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'address_edit_page.dart';
import '../features/menu/presentation/pages/menu_page.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/data/user_provider.dart';
import '../l10n/language_service.dart';
import '../theme/theme_service.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/api_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  int _selectedAvatarIndex = 0;
  File? _pickedImage;
  bool _isSaving = false;

  final List<String> _avatarOptions = [
    "https://i.pravatar.cc/150?img=12",
    "https://i.pravatar.cc/150?img=33",
    "https://i.pravatar.cc/150?img=5",
    "https://i.pravatar.cc/150?img=68",
    "https://i.pravatar.cc/150?img=20",
    "https://i.pravatar.cc/150?img=1",
  ];

  String _get(String key) => LanguageService().translate(key);

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(_get('select_photo'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceItem(Icons.photo_library_rounded, _get('gallery'), ImageSource.gallery),
                _buildSourceItem(Icons.camera_alt_rounded, _get('camera'), ImageSource.camera),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          imageQuality: 70, // Optimize for web upload
        );
        if (image != null) {
          setState(() => _pickedImage = File(image.path));
          _showEditProfileDialog();
        }
      },
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _showAvatarSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _get('select_photo'),
              style: const TextStyle(fontFamily: 'Hanuman', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
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
                    setState(() => _selectedAvatarIndex = index);
                    Navigator.pop(context);
                    // For stock avatars, we'd need a way to send them too, 
                    // but usually, users want their own photo.
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedAvatarIndex == index ? AppColors.primary : Colors.transparent,
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
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text(_get('gallery'), style: const TextStyle(fontFamily: 'Hanuman')),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              tileColor: AppColors.primary.withOpacity(0.05),
            )
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final nameController = TextEditingController(text: userProvider.name);
    final emailController = TextEditingController(text: userProvider.email);
    final bioController = TextEditingController(text: userProvider.bio ?? "");

    showDialog(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(_get('edit_profile'), style: const TextStyle(fontFamily: 'Hanuman', fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_pickedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: FileImage(_pickedImage!),
                        ),
                      ),
                    _buildDialogField(nameController, _get('name'), Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildDialogField(emailController, _get('email'), Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildDialogField(
                      bioController, 
                      _get('bio') ?? "Bio", 
                      Icons.info_outline,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: Text(_get('cancel'), style: const TextStyle(color: Colors.grey, fontFamily: 'Hanuman')),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  debugPrint("Attempting to save profile: name=${nameController.text}, email=${emailController.text}, hasImage=${_pickedImage != null}");
                  setDialogState(() => _isSaving = true);
                  setState(() => _isSaving = true);
                  
                  try {
                    final result = await AuthService().updateProfile(
                      name: nameController.text,
                      email: emailController.text,
                      bio: bioController.text,
                      avatar: _pickedImage,
                    );
                    
                    debugPrint("Profile update result: success=${result['success']}");

                    if (result['success']) {
                      if (result['user'] != null) {
                        userProvider.setUser(result['user']);
                        // Clear the local pick so we show the server version
                        setState(() => _pickedImage = null);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_get('profile_updated')), backgroundColor: Colors.green),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? "Error"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint("Error updating profile: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("An unexpected error occurred"), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    setDialogState(() => _isSaving = false);
                    setState(() => _isSaving = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_get('save'), style: const TextStyle(fontFamily: 'Hanuman', color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);

    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().currentLanguage,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
          drawer: const SideMenuDrawer(),
          appBar: AppBar(
            title: Text(_get('settings'), style: const TextStyle(fontFamily: 'Hanuman', fontWeight: FontWeight.bold, color: AppColors.primary)),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: AppColors.primary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildProfileHeader(isDark, userProvider),
                const SizedBox(height: 30),
                
                _buildSection(
                  title: _get('general'),
                  items: [
                    _buildSettingItem(
                      icon: Icons.language_rounded,
                      title: _get('language'),
                      value: language == 'km' ? "ខ្មែរ" : "English",
                      onTap: _showLanguageSelection,
                      isFirst: true,
                    ),
                    _buildThemeToggle(),
                    _buildSettingItem(
                      icon: Icons.notifications_active_outlined,
                      title: _get('notifications'),
                      trailing: _buildSwitch(_notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
                      isLast: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                _buildSection(
                  title: _get('account'),
                  items: [
                    _buildSettingItem(
                      icon: Icons.person_pin_outlined,
                      title: _get('personal_info'),
                      onTap: _showEditProfileDialog,
                      isFirst: true,
                    ),
                    _buildSettingItem(
                      icon: Icons.location_on_outlined,
                      title: _get('addresses'),
                      onTap: () => Navigator.pushNamed(context, '/address_edit'),
                      isLast: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                _buildSection(
                  title: _get('support'),
                  items: [
                    _buildSettingItem(
                      icon: Icons.info_outline_rounded,
                      title: _get('about_us'),
                      onTap: () => _showInfoDialog(_get('about_us'), _get('about_msg')),
                      isFirst: true,
                      isLast: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                _buildLogoutButton(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(bool isDark, UserProvider userProvider) {
    ImageProvider avatarImage;
    final avatarUrl = userProvider.effectiveAvatarUrl;
    debugPrint("SettingsPage Header Avatar URL: $avatarUrl");

    if (_pickedImage != null) {
      avatarImage = FileImage(_pickedImage!);
    } else {
      avatarImage = CachedNetworkImageProvider(avatarUrl);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _showAvatarSelection,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                    image: DecorationImage(
                      image: avatarImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.accentYellow, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProvider.name,
                  style: const TextStyle(fontFamily: 'Hanuman', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  userProvider.email,
                  style: TextStyle(fontFamily: 'Hanuman', fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
                if (userProvider.bio != null && userProvider.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      userProvider.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Hanuman', fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 12),
          child: Text(
            title,
            style: TextStyle(fontFamily: 'Hanuman', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(24) : Radius.zero,
          bottom: isLast ? const Radius.circular(24) : Radius.zero,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontFamily: 'Hanuman', fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  if (value != null)
                    Text(value, style: TextStyle(fontFamily: 'Hanuman', color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(width: 8),
                  trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                ],
              ),
            ),
            if (!isLast) Divider(height: 1, indent: 64, color: Colors.grey.withOpacity(0.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) => _buildSettingItem(
        icon: Icons.dark_mode_outlined,
        title: _get('dark_mode'),
        trailing: _buildSwitch(themeService.isDarkMode, (v) {
          themeService.toggleTheme();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(v ? _get('dark_mode_on') : _get('dark_mode_off')),
            duration: const Duration(milliseconds: 500),
          ));
        }),
      ),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      activeTrackColor: AppColors.primary.withOpacity(0.3),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: TextButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
        label: Text(
          _get('logout'),
          style: const TextStyle(fontFamily: 'Hanuman', color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  void _showLanguageSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Consumer<LanguageService>(
          builder: (context, langService, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(_get('choose_language'), style: const TextStyle(fontSize: 18, fontFamily: 'Hanuman', fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildLangTile("🇰🇭", _get('khmer'), 'km', langService),
              const SizedBox(height: 8),
              _buildLangTile("🇺🇸", _get('english'), 'en', langService),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangTile(String flag, String title, String code, LanguageService langService) {
    final isSelected = langService.currentLanguageCode == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(title, style: const TextStyle(fontFamily: 'Hanuman', fontWeight: FontWeight.bold)),
      onTap: () {
        langService.switchLanguage(code);
        Navigator.pop(context);
      },
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      tileColor: isSelected ? AppColors.primary.withOpacity(0.05) : null,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_get('logout'), style: const TextStyle(fontFamily: 'Hanuman', fontWeight: FontWeight.bold)),
        content: Text(_get('logout_confirm'), style: const TextStyle(fontFamily: 'Hanuman')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_get('cancel'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(_get('logout'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontFamily: 'Hanuman', fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontFamily: 'Hanuman')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_get('close'), style: const TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }
}
