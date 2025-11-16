import 'package:flutter/material.dart';

/// Professional Color Scheme for Quizzax App
/// All colors are centralized here for consistency
class AppColors {
  // Primary Colors
  static const Color primaryTeal = Color(0xFF015055); // Dark teal - Main brand color
  static const Color primaryTealLight = Color(0xFF017A7F); // Lighter teal variant
  static const Color primaryTealDark = Color(0xFF014A4F); // Darker teal variant
  
  // Accent Colors
  static const Color accentYellowGreen = Color(0xFFE2F299); // Light yellow-green - Primary accent
  static const Color accentYellowGreenLight = Color(0xFFEEF9C0); // Lighter yellow-green
  static const Color accentYellowGreenDark = Color(0xFFD4E87A); // Darker yellow-green
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFFFFFFF); // White background
  static const Color backgroundLight = const Color.fromARGB(255, 253, 253, 253); // Light grey background
  static const Color backgroundDark = Color(0xFFF0F0F0); // Slightly darker grey
  
  // Text Colors
  static const Color textPrimary = Color(0xFF015055); // Primary text (teal)
  static const Color textSecondary = Color(0xFF666666); // Secondary text (grey)
  static const Color textLight = Color(0xFF999999); // Light text
  static const Color textWhite = Color(0xFFFFFFFF); // White text
  static const Color textBlack = Color(0xFF000000); // Black text
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green for success
  static const Color successLight = Color(0xFFE8F5E9); // Light green background
  static const Color error = Color(0xFFE53935); // Red for errors
  static const Color errorLight = Color(0xFFFFEBEE); // Light red background
  static const Color warning = Color(0xFFFF9800); // Orange for warnings
  static const Color warningLight = Color(0xFFFFF3E0); // Light orange background
  static const Color info = Color(0xFF2196F3); // Blue for info
  static const Color infoLight = Color(0xFFE3F2FD); // Light blue background
  
  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0); // Light border
  static const Color borderMedium = Color(0xFFBDBDBD); // Medium border
  static const Color borderDark = Color(0xFF9E9E9E); // Dark border
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000); // Light shadow (10% opacity)
  static const Color shadowMedium = Color(0x33000000); // Medium shadow (20% opacity)
  static const Color shadowDark = Color(0x4D000000); // Dark shadow (30% opacity)
  
  // Card Colors
  static const Color cardBackground = Color(0xFFFFFFFF); // White card
  static const Color cardBackgroundLight = Color(0xFFFAFAFA); // Light card
  
  // Divider Colors
  static const Color divider = Color(0xFFE0E0E0); // Divider color
  
  // Overlay Colors
  static const Color overlay = Color(0x80000000); // Semi-transparent overlay (50% opacity)
  static const Color overlayLight = Color(0x40000000); // Light overlay (25% opacity)
}
