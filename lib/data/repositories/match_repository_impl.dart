import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/domain/repositories/match_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Repository implementation for Match entities
///
/// This class integrates with local data sources (SharedPreferences)
/// to persist match data
class MatchRepositoryImpl implements MatchRepository {
  final SharedPreferences _prefs;
  Match _currentEditingMatch;
  static const _matchKeyPrefix = 'match_';
  static const _matchListKey = 'match_list';
  static const _uuid = Uuid();

  MatchRepositoryImpl(this._prefs)
      : _currentEditingMatch = Match(
          id: _uuid.v4(),
          leagueName: '리그명 입력',
        );

  @override
  Future<Match?> getMatch(String id) async {
    final matchJson = _prefs.getString('$_matchKeyPrefix$id');
    if (matchJson == null) return null;

    try {
      return _matchFromJson(jsonDecode(matchJson));
    } catch (e) {
      print('Error parsing match data: $e');
      return null;
    }
  }

  @override
  Future<List<Match>> getAllMatches() async {
    final matchIds = _prefs.getStringList(_matchListKey) ?? [];
    final matches = <Match>[];

    for (final id in matchIds) {
      final match = await getMatch(id);
      if (match != null) {
        matches.add(match);
      }
    }

    return matches;
  }

  @override
  Future<void> saveMatch(Match match) async {
    // Store match data
    final matchJson = jsonEncode(_matchToJson(match));
    await _prefs.setString('$_matchKeyPrefix${match.id}', matchJson);

    // Update match list
    final matchIds = _prefs.getStringList(_matchListKey) ?? [];
    if (!matchIds.contains(match.id)) {
      matchIds.add(match.id);
      await _prefs.setStringList(_matchListKey, matchIds);
    }
  }

  @override
  Future<void> deleteMatch(String id) async {
    // Remove match data
    await _prefs.remove('$_matchKeyPrefix$id');

    // Update match list
    final matchIds = _prefs.getStringList(_matchListKey) ?? [];
    matchIds.remove(id);
    await _prefs.setStringList(_matchListKey, matchIds);
  }

  @override
  Match getCurrentEditingMatch() {
    return _currentEditingMatch;
  }

  @override
  void updateCurrentEditingMatch(Match match) {
    _currentEditingMatch = match;
  }

  // Serialization helpers

  Match _matchFromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      homeTeamName: json['homeTeamName'] as String? ?? '',
      awayTeamName: json['awayTeamName'] as String? ?? '',
      homeLogoPath: json['homeLogoPath'] as String? ?? '',
      awayLogoPath: json['awayLogoPath'] as String? ?? '',
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      scorers: (json['scorers'] as List?)
              ?.map((e) => _scorerFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      matchDateTime: json['matchDateTime'] != null
          ? DateTime.parse(json['matchDateTime'] as String)
          : null,
      venueLocation: json['venueLocation'] as String?,
      roundInfo: json['roundInfo'] as String?,
      goalScorers: json['goalScorers'] as String?,
      leagueName: json['leagueName'] as String? ?? '리그명 입력',
    );
  }

  Map<String, dynamic> _matchToJson(Match match) {
    return {
      'id': match.id,
      'homeTeamName': match.homeTeamName,
      'awayTeamName': match.awayTeamName,
      'homeLogoPath': match.homeLogoPath,
      'awayLogoPath': match.awayLogoPath,
      'homeScore': match.homeScore,
      'awayScore': match.awayScore,
      'scorers': match.scorers.map(_scorerToJson).toList(),
      'matchDateTime': match.matchDateTime?.toIso8601String(),
      'venueLocation': match.venueLocation,
      'roundInfo': match.roundInfo,
      'goalScorers': match.goalScorers,
      'leagueName': match.leagueName,
    };
  }

  ScorerInfo _scorerFromJson(Map<String, dynamic> json) {
    return ScorerInfo(
      id: json['id'] as String,
      isHomeTeam: json['isHomeTeam'] as bool,
      time: json['time'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isOwnGoal: json['isOwnGoal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _scorerToJson(ScorerInfo scorer) {
    return {
      'id': scorer.id,
      'isHomeTeam': scorer.isHomeTeam,
      'time': scorer.time,
      'name': scorer.name,
      'isOwnGoal': scorer.isOwnGoal,
    };
  }
}

/// Provider for match repository
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  throw UnimplementedError(
    'Repository provider must be overridden with actual implementation',
  );
});
