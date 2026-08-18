import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF00E5FF); // Cyber Cyan (Neon Cyan/Blue for brand accent)
  static const Color primaryBlue = Color(0xFF0052FF);  // Electric Brand Royal Blue
  static const Color cyanCyber = Color(0xFF0088FF);    // Cyber Light Blue
  static const Color primaryPurple = Color(0xFF8B5CF6); // Purple for Education
  
  // Dark Mode Palette - Deep Premium Obsidian
  static const Color darkBackground = Color(0xFF030305);
  static const Color darkSurface = Color(0xFF0D0D12);
  static const Color darkSurfaceLight = Color(0xFF16161F);
  
  // Light Mode Palette - Clean Modern Snow
  static const Color lightBackground = Color(0xFFF9FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF0F3FF);
  
  // Semantic
  static const Color errorRed = Color(0xFFFF453A);
  static const Color warningOrange = Color(0xFFFF9F0A);
  
  // Text Colors
  static const Color textPremium = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0A0A0B);
  static const Color textDimmed = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  
  // Helpers
  static Color background(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;
      
  static Color surface(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;

  static Color text(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? textPremium : textDark;

  static Color glassBorder = Colors.white.withValues(alpha: 0.1);
}
