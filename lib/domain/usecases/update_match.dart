import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/domain/repositories/match_repository.dart';

/// UpdateMatch use case following the Clean Architecture pattern
///
/// Represents a specific business action - updating match information
/// Isolates business logic from external dependencies
class UpdateMatch {
  final MatchRepository repository;

  UpdateMatch(this.repository);

  /// Save match to persistent storage
  Future<void> save(Match match) async {
    return repository.saveMatch(match);
  }

  /// Update the current match being edited (in memory only)
  void updateCurrentEditingMatch(Match match) {
    repository.updateCurrentEditingMatch(match);
  }

  /// Update only the home team name
  void updateHomeTeamName(String name) {
    final match = repository.getCurrentEditingMatch();
    repository.updateCurrentEditingMatch(match.copyWith(homeTeamName: name));
  }

  /// Update only the away team name
  void updateAwayTeamName(String name) {
    final match = repository.getCurrentEditingMatch();
    repository.updateCurrentEditingMatch(match.copyWith(awayTeamName: name));
  }

  /// Update only the home logo path
  void updateHomeLogo(String path) {
    final match = repository.getCurrentEditingMatch();
    repository.updateCurrentEditingMatch(match.copyWith(homeLogoPath: path));
  }

  /// Update only the away logo path
  void updateAwayLogo(String path) {
    final match = repository.getCurrentEditingMatch();
    repository.updateCurrentEditingMatch(match.copyWith(awayLogoPath: path));
  }

  /// Update only the home score
  void updateHomeScore(int? score) {
    final match = repository.getCurrentEditingMatch();
    repository.updateCurrentEditingMatch(
      match.copyWith(homeScore: score, clearHomeScore: score == null),
    );
  }

  /// Update only the away score
  void updateAwayScore(int? score) {
    final match = repository.getCurrentEditingMatch();
    repository.updateCurrentEditingMatch(
      match.copyWith(awayScore: score, clearAwayScore: score == null),
    );
  }

  /// Update scorers list
  void updateScorers(List<ScorerInfo> scorers) {
    final match = repository.getCurrentEditingMatch();
    repository.updateCurrentEditingMatch(match.copyWith(scorers: scorers));
  }

  /// Add a new scorer
  void addScorer(ScorerInfo scorer) {
    final match = repository.getCurrentEditingMatch();
    final newScorers = List<ScorerInfo>.from(match.scorers)..add(scorer);
    repository.updateCurrentEditingMatch(match.copyWith(scorers: newScorers));
  }

  /// Remove a scorer by ID
  void removeScorer(String id) {
    final match = repository.getCurrentEditingMatch();
    final newScorers = match.scorers.where((s) => s.id != id).toList();
    repository.updateCurrentEditingMatch(match.copyWith(scorers: newScorers));
  }

  /// Update a specific scorer's information
  void updateScorer(ScorerInfo updatedScorer) {
    final match = repository.getCurrentEditingMatch();
    final newScorers =
        match.scorers.map((scorer) {
          if (scorer.id == updatedScorer.id) {
            return updatedScorer;
          }
          return scorer;
        }).toList();

    repository.updateCurrentEditingMatch(match.copyWith(scorers: newScorers));
  }
}
