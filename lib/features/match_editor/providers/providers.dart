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
export 'theme_color_provider.dart';

// Core match editor provider
export 'match_editor_provider.dart';

// Feature-specific providers that depend on match_editor_provider and focus_manager_provider
export 'scorers_provider.dart';
export 'team_info_provider.dart';
export 'match_details_provider.dart';
