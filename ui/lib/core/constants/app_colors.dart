import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF42542B);
  static const Color primaryLight = Color(0xFF6B804E);
  static const Color primaryVariant = Color(0xFF2D3A1D);
  static const Color accentYellow = Color(0xFFF2C94C);

  // Background/Surface colors
  static const Color background = Color(0xFFF8F9FA); // Off-white for clarity
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);

  // Gradient support
  static const List<Color> primaryGradient = [
    primary,
    primaryLight,
  ];

  // Text colors
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackground = Color(0xFF212529);
  static const Color onSurface = Color(0xFF212529);
  static const Color onError = Colors.white;
}
