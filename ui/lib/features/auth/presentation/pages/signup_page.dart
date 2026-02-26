import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/auth_service.dart';
import '../../../../widget/home_screen.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isObscured = true;
  bool _isConfirmObscured = true;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();

  // Animation Controllers
  late AnimationController _animationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _fieldsFadeAnimation;

  // Error State
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuart),
    ));

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutQuart),
    ));

    _fieldsFadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool isValid = true;
    if (_nameController.text.isEmpty) {
      _nameError = 'Name is required';
      isValid = false;
    }
    if (_emailController.text.isEmpty) {
      _emailError = 'Email is required';
      isValid = false;
    }
    if (_passwordController.text.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    } else if (_passwordController.text.length < 8) {
      _passwordError = 'Password must be at least 8 characters';
      isValid = false;
    }
    if (_confirmPasswordController.text != _passwordController.text) {
      _confirmPasswordError = 'Passwords do not match';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    // Fetch FCM Token
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
    }

    // Detect if input is email or phone
    final String contactInput = _emailController.text.trim();
    String? email;
    String? phone;

    if (contactInput.contains('@')) {
      email = contactInput;
    } else {
      phone = contactInput;
    }

    try {
      final result = await _authService.register(
        name: _nameController.text.trim(),
        email: email, // This will be null if phone is used
        password: _passwordController.text,
        phone: phone,
        fcmToken: fcmToken,
        deviceType: Theme.of(context).platform == TargetPlatform.android ? 'android' : 'ios',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          final message = result['message'];
          final errors = result['errors'] as Map<String, dynamic>?;

          if (errors != null) {
            if (errors.containsKey('name')) _nameError = (errors['name'] as List).first;
            if (errors.containsKey('email')) _emailError = (errors['email'] as List).first;
            if (errors.containsKey('phone')) _emailError = (errors['phone'] as List).first; // Map phone error to same field
            if (errors.containsKey('password')) _passwordError = (errors['password'] as List).first;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message ?? 'Registration failed')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10140B),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                const Color(0xFF10140B),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.only(top: 60, left: 30, right: 30),
                child: SlideTransition(
                  position: _headerSlideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/auth_landing'),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Join Us!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          letterSpacing: -1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover a world of stories today.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Form Section (White Card)
              Expanded(
                child: SlideTransition(
                  position: _formSlideAnimation,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: FadeTransition(
                      opacity: _fieldsFadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 25),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const Text(
                            'Registration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2614),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildCustomField(
                            label: 'Full Name',
                            controller: _nameController,
                            hint: 'Full Name',
                            prefixIcon: Icons.person_outline_rounded,
                            errorText: _nameError,
                          ),
                          const SizedBox(height: 16),

                          _buildCustomField(
                            label: 'Phone or Gmail',
                            controller: _emailController,
                            hint: 'example@gmail.com',
                            prefixIcon: Icons.alternate_email_rounded,
                            errorText: _emailError,
                          ),
                          const SizedBox(height: 16),

                          _buildCustomField(
                            label: 'Password',
                            controller: _passwordController,
                            hint: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 20,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: () => setState(() => _isObscured = !_isObscured),
                            ),
                            errorText: _passwordError,
                          ),
                          const SizedBox(height: 16),

                          _buildCustomField(
                            label: 'Confirm Password',
                            controller: _confirmPasswordController,
                            hint: 'Confirm Password',
                            prefixIcon: Icons.lock_reset_rounded,
                            isPassword: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 20,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: () => setState(() => _isConfirmObscured = !_isConfirmObscured),
                            ),
                            errorText: _confirmPasswordError,
                          ),

                          const SizedBox(height: 40),

                          GestureDetector(
                            onTap: _isLoading ? null : _handleSignup,
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    const Color(0xFF1D2614),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text(
                                        'SIGN UP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Already have account?",
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => const LoginPage()),
                                        );
                                      },
                                      child: const Text(
                                        'Sign in',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool isPassword = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword && (label.contains('Confirm') ? _isConfirmObscured : _isObscured),
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(prefixIcon, color: AppColors.primary.withOpacity(0.7), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            isDense: true,
            contentPadding: const EdgeInsets.all(18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
