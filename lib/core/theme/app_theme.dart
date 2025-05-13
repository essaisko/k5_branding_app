import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Centralized theme configuration following Steve Jobs' design principles:
/// - Consistency: Same visual language throughout the app
/// - Intentionality: Every design decision has a purpose
/// - Focus: Elements are simplified to remove distraction
/// - Elegance: Clean, beautiful, and functional
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme for the application
  static ThemeData get lightTheme {
    return ThemeData(
      // Color scheme
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),

      // Scaffolds and backgrounds
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,
      dividerColor: AppColors.divider,

      // Elevated buttons theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          textStyle: AppTypography.buttonMedium,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Text theme using our typography system
      textTheme: TextTheme(
        displayLarge: AppTypography.heading1,
        displayMedium: AppTypography.heading2,
        displaySmall: AppTypography.heading3,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.buttonLarge,
        labelMedium: AppTypography.buttonMedium,
        labelSmall: AppTypography.caption,
      ),

      // Input decoration for text fields
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.heading3.copyWith(
          color: AppColors.textOnPrimary,
        ),
      ),

      // Visual density for all widgets
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Dark theme for the application
  static ThemeData get darkTheme {
    // Implement dark theme when needed
    return lightTheme;
  }
}
