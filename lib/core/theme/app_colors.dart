import 'package:flutter/material.dart';

/// 축신 앱 색상 팔레트 - 하늘색 테마 디자인 시스템
/// - 앱 아이콘의 하늘색을 기본으로 한 색상 체계
/// - 의미론적 색상 명명 규칙 적용
/// - Material Design 원칙 준수
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // 브랜드 색상 - 하늘색 테마 (앱 아이콘과 일치)
  static const Color primary = Color(0xFF1E88E5); // 하늘색 (앱 아이콘 색상)
  static const Color primaryLight = Color(0xFF6AB7FF);
  static const Color primaryDark = Color(0xFF005CB2);

  static const Color secondary = Color(0xFF2E7D32); // 축구 필드 그린
  static const Color secondaryLight = Color(0xFF60AD5E);
  static const Color secondaryDark = Color(0xFF005005);

  // 의미론적 색상
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // 중성 색상
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // 텍스트 색상
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // 테두리 색상
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // 축신 특화 색상
  static const Color skyBlue = Color(0xFF1E88E5); // 앱 아이콘 하늘색
  static const Color footballGreen = Color(0xFF2E7D32); // 축구 필드 그린
  static const Color footballWhite = Color(0xFFFFFFFF); // 축구공 화이트
  static const Color goalpostYellow = Color(0xFFFFC107); // 골대 옐로우
  static const Color refereeBlack = Color(0xFF212121); // 심판복 블랙
}
