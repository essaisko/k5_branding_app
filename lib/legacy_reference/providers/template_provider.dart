import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define the different template types
enum TemplateType {
  matchResult,
  matchSchedule,
  lineup,
  // Add other templates as needed
}

// Simple provider to hold the currently selected template type
final templateProvider = StateProvider<TemplateType>((ref) {
  // Default to Match Result template
  return TemplateType.matchResult;
});
