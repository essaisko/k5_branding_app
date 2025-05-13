import 'package:flutter_riverpod/flutter_riverpod.dart';

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
