import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// Template type enumeration
/// - Clean, semantic naming for different template types
/// - Organized in a type-safe way
enum TemplateType {
  /// Match result template (경기 결과)
  matchResult,

  /// Match schedule template (경기 일정)
  matchSchedule,

  /// Team lineup template (라인업)
  lineup,
}

/// Sample template styles enumeration
/// - Different visual styles for the same template type
enum SampleTemplateStyle {
  /// 기본 스타일들
  basic1,
  basic2,
  basic3,

  /// 팀별 스타일들
  fcSeoulStyle,
  jeonbukStyle,

  /// 디자인 컨셉별 스타일들
  cleanStyle1,
  elegantStyle1,
  colorfulStyle1,
}

/// Sample template configuration class
class SampleTemplateConfig {
  final SampleTemplateStyle style;
  final String displayName;
  final Color primaryColor;
  final Color accentColor;
  final String patternType;
  final double patternOpacity;
  final String description;

  const SampleTemplateConfig({
    required this.style,
    required this.displayName,
    required this.primaryColor,
    required this.accentColor,
    required this.patternType,
    required this.patternOpacity,
    required this.description,
  });
}

/// Predefined sample template configurations
class SampleTemplateConfigs {
  static const Map<SampleTemplateStyle, SampleTemplateConfig> configs = {
    SampleTemplateStyle.basic1: SampleTemplateConfig(
      style: SampleTemplateStyle.basic1,
      displayName: '기본1',
      primaryColor: Color(0xFF1976D2),
      accentColor: Color(0xFF64B5F6),
      patternType: 'none',
      patternOpacity: 0.0,
      description: '깔끔한 파란색 기본 템플릿',
    ),
    SampleTemplateStyle.basic2: SampleTemplateConfig(
      style: SampleTemplateStyle.basic2,
      displayName: '기본2',
      primaryColor: Color(0xFF388E3C),
      accentColor: Color(0xFF81C784),
      patternType: 'diagonal',
      patternOpacity: 0.1,
      description: '자연스러운 녹색 템플릿',
    ),
    SampleTemplateStyle.basic3: SampleTemplateConfig(
      style: SampleTemplateStyle.basic3,
      displayName: '기본3',
      primaryColor: Color(0xFF7B1FA2),
      accentColor: Color(0xFFBA68C8),
      patternType: 'dots',
      patternOpacity: 0.15,
      description: '모던한 보라색 템플릿',
    ),
    SampleTemplateStyle.fcSeoulStyle: SampleTemplateConfig(
      style: SampleTemplateStyle.fcSeoulStyle,
      displayName: 'FC서울 스타일',
      primaryColor: Color(0xFFE53935),
      accentColor: Color(0xFFEF5350),
      patternType: 'diagonal',
      patternOpacity: 0.2,
      description: 'FC서울 팀 컬러 기반 템플릿',
    ),
    SampleTemplateStyle.jeonbukStyle: SampleTemplateConfig(
      style: SampleTemplateStyle.jeonbukStyle,
      displayName: '전북 현대 스타일',
      primaryColor: Color(0xFF2E7D32),
      accentColor: Color(0xFF4CAF50),
      patternType: 'dots',
      patternOpacity: 0.25,
      description: '전북 현대 팀 컬러 기반 템플릿',
    ),
    SampleTemplateStyle.cleanStyle1: SampleTemplateConfig(
      style: SampleTemplateStyle.cleanStyle1,
      displayName: '깔끔한 스타일1',
      primaryColor: Color(0xFF37474F),
      accentColor: Color(0xFF78909C),
      patternType: 'none',
      patternOpacity: 0.0,
      description: '미니멀한 그레이 톤 템플릿',
    ),
    SampleTemplateStyle.elegantStyle1: SampleTemplateConfig(
      style: SampleTemplateStyle.elegantStyle1,
      displayName: '세련된 스타일1',
      primaryColor: Color(0xFF424242),
      accentColor: Color(0xFF9E9E9E),
      patternType: 'diagonal',
      patternOpacity: 0.08,
      description: '세련된 다크 톤 템플릿',
    ),
    SampleTemplateStyle.colorfulStyle1: SampleTemplateConfig(
      style: SampleTemplateStyle.colorfulStyle1,
      displayName: '화려한 스타일1',
      primaryColor: Color(0xFFFF5722),
      accentColor: Color(0xFFFFAB40),
      patternType: 'dots',
      patternOpacity: 0.3,
      description: '생동감 넘치는 오렌지 템플릿',
    ),
  };

  static SampleTemplateConfig getConfig(SampleTemplateStyle style) {
    return configs[style] ?? configs[SampleTemplateStyle.basic1]!;
  }

  static List<SampleTemplateConfig> getAllConfigs() {
    return configs.values.toList();
  }
}

/// Extension on TemplateType for localized display names
extension TemplateTypeExtension on TemplateType {
  /// Get the Korean display name for template types
  String get displayName {
    switch (this) {
      case TemplateType.matchResult:
        return '경기 결과';
      case TemplateType.matchSchedule:
        return '경기 일정';
      case TemplateType.lineup:
        return '라인업';
    }
  }

  /// Get template-specific icon data
  String get iconAsset {
    switch (this) {
      case TemplateType.matchResult:
        return 'assets/icons/match_result.png';
      case TemplateType.matchSchedule:
        return 'assets/icons/schedule.png';
      case TemplateType.lineup:
        return 'assets/icons/lineup.png';
    }
  }
}

/// Provider for the currently selected template
final templateProvider = StateProvider<TemplateType>((ref) {
  return TemplateType.matchResult; // Default template
});

/// Provider for the currently selected sample template style
final sampleTemplateProvider = StateProvider<SampleTemplateStyle>((ref) {
  return SampleTemplateStyle.basic1; // Default sample template
});
