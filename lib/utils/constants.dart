import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFFE2C55);
  static const secondary = Color(0xFF20C5D2);
  static const background = Color(0xFF121212);
  static const cardBackground = Color(0xFF1E1E1E);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFAAAAAA);
  static const error = Color(0xFFFF5252);
  static const success = Color(0xFF4CAF50);
}

class AppTextStyles {
  static const headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const bodyText1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const bodyText2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}

class AppDimensions {
  static const padding = 16.0;
  static const paddingSmall = 8.0;
  static const borderRadius = 12.0;
  static const buttonHeight = 50.0;
}
