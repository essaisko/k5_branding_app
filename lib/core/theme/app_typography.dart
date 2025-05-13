import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography system with consistent text styles
/// - follows type scale for harmony and rhythm
/// - semantic naming for use-cases rather than sizes
/// - maintains consistent line heights and letter spacing
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // Base font families
  static const String _baseFont = 'Pretendard';
  static const String _headingFont = 'Pretendard';

  // Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: _headingFont,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: _headingFont,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: _headingFont,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _baseFont,
    fontSize: 18,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _baseFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _baseFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Button and Label Styles
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: _baseFont,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: _baseFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Caption and overline
  static const TextStyle caption = TextStyle(
    fontFamily: _baseFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _baseFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.3,
    color: AppColors.textSecondary,
  );
}
