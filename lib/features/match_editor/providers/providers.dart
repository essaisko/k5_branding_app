// Central provider exports for match editor feature
//
// USAGE: Instead of importing individual provider files, import this file:
// import 'package:k5_branding_app/features/match_editor/providers/providers.dart';
//
// IMPORTANT: The order of exports is critical to prevent circular dependencies.
// Providers with no dependencies on other providers should be exported first.

// Base providers with no dependencies on other providers
export 'focus_manager_provider.dart';
export 'design_pattern_provider.dart';
export 'template_provider.dart';
export 'sample_data_provider.dart';

// Core match editor provider
export 'match_editor_provider.dart';

// Feature-specific providers that depend on other providers
export 'theme_color_provider.dart';
export 'goal_scorers_provider.dart';
export 'team_details_provider.dart';
export 'scorers_provider.dart';
export 'team_info_provider.dart';
export 'match_details_provider.dart';

// 모든 프로바이더를 한 곳에서 export하는 파일
// 이 파일을 통해 다른 파일에서 필요한 프로바이더들을 쉽게 import할 수 있습니다.
//
// USAGE: Instead of importing individual provider files, import this file:
// import 'package:chukshin_app/features/match_editor/providers/providers.dart';
//
// IMPORTANT: The order of exports is critical to prevent circular dependencies.
// Providers with no dependencies on other providers should be exported first.

// import 'package:chukshin_app/features/match_editor/providers/providers.dart';

export 'match_editor_provider.dart';
export 'template_provider.dart';
export 'design_pattern_provider.dart';
export 'theme_color_provider.dart';
export 'sample_data_provider.dart';
export 'goal_scorers_provider.dart';
export 'team_details_provider.dart';
export 'focus_manager_provider.dart';
export 'team_info_provider.dart';
export 'match_details_provider.dart';
