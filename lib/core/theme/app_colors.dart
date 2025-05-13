import 'package:flutter/material.dart';

/// Application color palette following design system principles
/// - Colors are named semantically, not by their visual appearance
/// - Primary/secondary schemes follow material design principles
/// - Consistent naming patterns for easy discovery
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF6AB7FF);
  static const Color primaryDark = Color(0xFF005CB2);

  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF64D8CB);
  static const Color secondaryDark = Color(0xFF00766C);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Neutral colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Theme specific colors
  static const Color k5LeagueRed = Color(0xFFE53935);
  static const Color k5LeagueBlue = Color(0xFF1565C0);
}
