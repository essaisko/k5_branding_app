import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// A utility class for working with colors and image processing
class ColorUtils {
  // Private constructor to prevent instantiation
  ColorUtils._();

  /// Reference colors for K5 league teams - 각 팀의 대표 컬러 매핑
  static const Map<String, Color> teamBaseColors = {
    'yangsan_united': Color.fromRGBO(205, 163, 3, 1), // 양산유나이티드 - 퍼플
    'pluzz_fc': Color.fromRGBO(236, 183, 34, 1), // 플러즈FC - 블루
    'kimhae_jaemics_fc': Color.fromRGBO(237, 28, 36, 1), // 재믹스축구클럽 - 레드
    'one_touch_fc': Color.fromRGBO(0, 101, 163, 1), // 원터치FC - 네이비
    'jinjudaesung': Color.fromRGBO(255, 0, 0, 1), // 진주대성축구클럽 - 레드
  };

  /// 팀 키를 기준으로 기본 색상 가져오기
  static Color getTeamColor(String teamKey) {
    // 기본 색상 반환
    return teamBaseColors[teamKey] ?? Colors.blue;
  }

  /// 이미지 경로에서 팀 키 추출
  static String? getTeamKeyFromImagePath(String path) {
    final filename = path.split('/').last;
    final fileWithoutExtension = filename.split('.').first;

    // 이미지 경로에서 팀 키 추출 (예: 'assets/images/yangsan_united_logo.png' -> 'yangsan_united')
    for (final key in teamBaseColors.keys) {
      if (fileWithoutExtension.contains(key)) {
        return key;
      }
    }

    return null;
  }

  /// 이미지 경로에서 팀 색상 가져오기
  static Color getColorFromTeamLogo(String logoPath) {
    final teamKey = getTeamKeyFromImagePath(logoPath);
    if (teamKey != null) {
      return getTeamColor(teamKey);
    }

    // 없으면 기본 색상 반환
    return Colors.blue;
  }
}
