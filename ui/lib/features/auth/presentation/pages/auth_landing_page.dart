import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import 'login_page.dart';
import 'signup_page.dart';
import '../../data/auth_service.dart';
import '../../../../widget/home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:toastification/toastification.dart';

class AuthLandingPage extends StatefulWidget {
  const AuthLandingPage({super.key});

  @override
  State<AuthLandingPage> createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends State<AuthLandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AuthService _authService = AuthService();
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  
  // Animations
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _welcomeSlideAnimation;
  late Animation<Offset> _button1SlideAnimation;
  late Animation<Offset> _button2SlideAnimation;
  late Animation<double> _socialFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _titleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
    );

    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
    ));

    _button1SlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOutQuart),
    ));

    _button2SlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.9, curve: Curves.easeOutQuart),
    ));

    _socialFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // Fetch FCM Token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error fetching FCM token: $e');
      }

      final result = await _authService.loginWithGoogle(
        fcmToken: fcmToken,
        deviceType: Theme.of(context).platform == TargetPlatform.android ? 'android' : 'ios',
      );

      if (mounted) {
        if (result['success']) {
          toastification.show(
            context: context,
            title: const Text('Login Successful'),
            description: const Text('Welcome to Our Novel!'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 3),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else if (result['message'] != 'Google Sign-In cancelled') {
          toastification.show(
            context: context,
            title: const Text('Login Failed'),
            description: Text(result['message'] ?? 'Unable to sign in with Google'),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: Text(e.toString()),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isFacebookLoading = true;
    });

    try {
      // Fetch FCM Token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error fetching FCM token: $e');
      }

      final result = await _authService.loginWithFacebook(
        fcmToken: fcmToken,
        deviceType: Theme.of(context).platform == TargetPlatform.android ? 'android' : 'ios',
      );

      if (mounted) {
        if (result['success']) {
          toastification.show(
            context: context,
            title: const Text('Login Successful'),
            description: const Text('Welcome to Our Novel!'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 3),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else if (result['message'] != 'Facebook Sign-In cancelled') {
          toastification.show(
            context: context,
            title: const Text('Login Failed'),
            description: Text(result['message'] ?? 'Unable to sign in with Facebook'),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: Text(e.toString()),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFacebookLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              const Color(0xFF10140B), // Very dark shade for depth
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: [
                const SizedBox(height: 80),
                
                // Logo Section
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: SlideTransition(
                    position: _logoSlideAnimation,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _titleFadeAnimation,
                          child: const Column(
                            children: [
                              Text(
                                'OUR NOVEL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              Text(
                                'ហាងលក់សៀវភៅ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Welcome Text
                SlideTransition(
                  position: _welcomeSlideAnimation,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
                    ),
                    child: const Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Sign In Button (Outlined)
                SlideTransition(
                  position: _button1SlideAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'SIGN IN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign Up Button (Filled)
                SlideTransition(
                  position: _button2SlideAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Social Media Section
                FadeTransition(
                  opacity: _socialFadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_isGoogleLoading || _isFacebookLoading) ? null : _handleGoogleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                            ),
                          ),
                          child: _isGoogleLoading 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                    height: 24,
                                    width: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'CONTINUE WITH GOOGLE',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Facebook Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_isGoogleLoading || _isFacebookLoading) ? null : _handleFacebookSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2), // Facebook Blue
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isFacebookLoading 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.facebook_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'CONTINUE WITH FACEBOOK',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
