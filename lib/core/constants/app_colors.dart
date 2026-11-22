import 'package:flutter/material.dart';

class AppColors {
  // Brand & Eco Palette
  static const Color primary = Color(0xFF2E7D32); // Forest Green
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);
  static const Color secondary = Color(0xFFFF8F00); // Warm Amber
  static const Color background = Color(0xFFF9FBF9);
  static const Color surface = Colors.white;

  // Real-Time Urgency Color Codes
  static const Color urgencyCritical = Color(0xFFE53935); // < 1 hr (Red)
  static const Color urgencyWarning = Color(0xFFFB8C00);  // 1-3 hrs (Orange)
  static const Color urgencySafe = Color(0xFF43A047);     // > 3 hrs (Green)
  static const Color urgencyExpired = Color(0xFF757575);  // Expired (Grey)

  // Status Badges
  static const Color statusAvailable = Color(0xFF2E7D32);
  static const Color statusReserved = Color(0xFF1976D2);
  static const Color statusPickedUp = Color(0xFF5E35B1);
  static const Color statusExpired = Color(0xFF757575);

  // Category Badges
  static const Color veg = Color(0xFF2E7D32);
  static const Color nonVeg = Color(0xFFC62828);
  static const Color vegan = Color(0xFF00897B);
  static const Color bakery = Color(0xFF8D6E63);

  // Neutral tones
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF616161);
  static const Color border = Color(0xFFE0E0E0);
}
