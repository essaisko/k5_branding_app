import 'package:k5_branding_app/domain/entities/match.dart';

/// Repository interface for Match entities
///
/// This follows the dependency inversion principle:
/// High-level modules should not depend on low-level modules
/// Both should depend on abstractions
abstract class MatchRepository {
  /// Get a match by ID
  Future<Match?> getMatch(String id);

  /// Get all matches
  Future<List<Match>> getAllMatches();

  /// Save a match
  Future<void> saveMatch(Match match);

  /// Delete a match
  Future<void> deleteMatch(String id);

  /// Get current match being edited (in memory)
  Match getCurrentEditingMatch();

  /// Update current match being edited
  void updateCurrentEditingMatch(Match match);
}
