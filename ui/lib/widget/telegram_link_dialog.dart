import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'dart:ui';
import '../core/constants/app_colors.dart';

class TelegramLinkDialog extends StatefulWidget {
  final int userId;
  final String telegramBotUsername;

  const TelegramLinkDialog({
    super.key,
    required this.userId,
    this.telegramBotUsername = 'hengcode_bot',
  });

  @override
  State<TelegramLinkDialog> createState() => _TelegramLinkDialogState();
}

class _TelegramLinkDialogState extends State<TelegramLinkDialog> with SingleTickerProviderStateMixin {
  bool _dontShowAgain = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchTelegram() async {
    if (_isLaunching) return;
    
    setState(() => _isLaunching = true);
    
    final httpsUrl = Uri.parse('https://t.me/${widget.telegramBotUsername}?start=${widget.userId}');
    final tgUrl = Uri.parse('tg://resolve?domain=${widget.telegramBotUsername}&start=${widget.userId}');
    
    try {
      // 1. Try direct Telegram app link first
      if (await canLaunchUrl(tgUrl)) {
        await launchUrl(tgUrl, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.pop(context);
        return;
      }
      
      // 2. Fallback to HTTPS link (which OS handles)
      if (await canLaunchUrl(httpsUrl)) {
        await launchUrl(httpsUrl, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.pop(context);
        return;
      }

      // 3. Fallback to web link if both above fail
      await launchUrl(httpsUrl, mode: LaunchMode.platformDefault);
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('មិនអាចបើកតេឡេក្រាមបានទេ (Cannot Open Telegram)'),
          description: const Text('សូមប្រាកដថាអ្នកបានដំឡើង Telegram រួចរាល់។'),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  Future<void> _savePreference() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hide_telegram_dialog', true);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: _buildDialogContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F16).withOpacity(0.95) : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium Icon Design
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0088CC), Color(0xFF00AACC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0088CC).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.telegram_rounded,
                color: Colors.white,
                size: 60,
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // Title
          const Text(
            'ភ្ជាប់ជាមួយ Telegram Bot',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'KhmerOSBattambang',
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            'ទទួលបានវិក្កយបត្រ (Invoice) និងការជូនដំណឹងផ្សេងៗភ្លាមៗ តាមរយៈតេឡេក្រាមជំនួយការរបស់យើង។',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white60 : Colors.black54,
              fontFamily: 'KhmerOSBattambang',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Action Buttons
          GestureDetector(
            onTap: _launchTelegram,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0088CC), Color(0xFF33B6F2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0088CC).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isLaunching 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text(
                      'ភ្ជាប់ឥឡូវនេះ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        fontFamily: 'KhmerOSBattambang',
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: _savePreference,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'ទុកពេលក្រោយ',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'KhmerOSBattambang',
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Don't show again checkbox
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: _dontShowAgain,
                  activeColor: const Color(0xFF0088CC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (value) {
                    setState(() {
                      _dontShowAgain = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _dontShowAgain = !_dontShowAgain;
                  });
                },
                child: Text(
                  'កុំបង្ហាញម្តងទៀត',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                    fontFamily: 'KhmerOSBattambang',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
