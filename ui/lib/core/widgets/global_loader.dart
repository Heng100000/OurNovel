import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlobalLoader extends StatefulWidget {
  final bool isOverlay;
  final double size;
  final String? message;
  final Color? color;

  const GlobalLoader({
    super.key,
    this.isOverlay = false,
    this.size = 60,
    this.message,
    this.color,
  });

  @override
  State<GlobalLoader> createState() => _GlobalLoaderState();
}

class _GlobalLoaderState extends State<GlobalLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? AppColors.primary;
    final secondaryColor = widget.color?.withOpacity(0.3) ?? AppColors.primaryLight;
    final iconSize = widget.size * 0.4;
    final paddingSize = widget.size * 0.2;

    Widget loader = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Rotating Ring
              SizedBox(
                width: widget.size * 1.25,
                height: widget.size * 1.25,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                ),
              ),
              // Main Circular Progress
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: widget.size * 0.06,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              // Pulsing Book Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Container(
                    padding: EdgeInsets.all(paddingSize),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: widget.size * 0.25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: primaryColor,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.isOverlay) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Glassmorphism background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            loader,
          ],
        ),
      );
    }

    return loader;
  }
}
