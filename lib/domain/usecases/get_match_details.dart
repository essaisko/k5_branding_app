import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/domain/repositories/match_repository.dart';

/// GetMatchDetails use case following the Clean Architecture pattern
///
/// Represents a specific business action - retrieving match details
/// Isolates business logic from external dependencies
class GetMatchDetails {
  final MatchRepository repository;

  GetMatchDetails(this.repository);

  /// Get a match by ID
  Future<Match?> call(String id) async {
    return repository.getMatch(id);
  }

  /// Get the current match being edited
  Match getCurrentEditingMatch() {
    return repository.getCurrentEditingMatch();
  }
}
