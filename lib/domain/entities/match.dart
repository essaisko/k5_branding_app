import 'package:flutter/foundation.dart';

/// Match entity representing a football match in the domain layer
/// - Pure data class with immutable properties
/// - No dependency on data sources or external frameworks
/// - Rich domain model with clear business rules
@immutable
class Match {
  final String id;
  final String homeTeamName;
  final String awayTeamName;
  final String homeLogoPath;
  final String awayLogoPath;
  final int? homeScore;
  final int? awayScore;
  final List<ScorerInfo> scorers;
  final DateTime? matchDateTime;
  final String? venueLocation;
  final String? roundInfo; // 경기 라운드 정보
  final String? goalScorers; // 득점자 정보 (문자열 형태로 저장)
  final String leagueName; // 리그 이름

  const Match({
    required this.id,
    this.homeTeamName = '',
    this.awayTeamName = '',
    this.homeLogoPath = '',
    this.awayLogoPath = '',
    this.homeScore,
    this.awayScore,
    this.scorers = const [],
    this.matchDateTime,
    this.venueLocation,
    this.roundInfo,
    this.goalScorers,
    this.leagueName = '리그명 입력',
  });

  /// Creates a copy of this Match with the given fields replaced with the new values
  Match copyWith({
    String? id,
    String? homeTeamName,
    String? awayTeamName,
    String? homeLogoPath,
    String? awayLogoPath,
    int? homeScore,
    int? awayScore,
    List<ScorerInfo>? scorers,
    DateTime? matchDateTime,
    String? venueLocation,
    String? roundInfo,
    String? goalScorers,
    String? leagueName,
    bool clearHomeScore = false,
    bool clearAwayScore = false,
  }) {
    return Match(
      id: id ?? this.id,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homeLogoPath: homeLogoPath ?? this.homeLogoPath,
      awayLogoPath: awayLogoPath ?? this.awayLogoPath,
      homeScore: clearHomeScore ? null : homeScore ?? this.homeScore,
      awayScore: clearAwayScore ? null : awayScore ?? this.awayScore,
      scorers: scorers ?? this.scorers,
      matchDateTime: matchDateTime ?? this.matchDateTime,
      venueLocation: venueLocation ?? this.venueLocation,
      roundInfo: roundInfo ?? this.roundInfo,
      goalScorers: goalScorers ?? this.goalScorers,
      leagueName: leagueName ?? this.leagueName,
    );
  }

  /// 기본값이 있는 Match 생성 팩토리 메서드
  factory Match.withDefaults({
    required String id,
    String homeTeamName = '',
    String awayTeamName = '',
    String homeLogoPath = '',
    String awayLogoPath = '',
    int? homeScore,
    int? awayScore,
    List<ScorerInfo> scorers = const [],
    DateTime? matchDateTime,
    String? venueLocation,
    String? roundInfo,
    String? goalScorers,
    String leagueName = '리그명 입력',
  }) {
    return Match(
      id: id,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeLogoPath: homeLogoPath,
      awayLogoPath: awayLogoPath,
      homeScore: homeScore,
      awayScore: awayScore,
      scorers: scorers,
      matchDateTime: matchDateTime,
      venueLocation: venueLocation,
      roundInfo: roundInfo,
      goalScorers: goalScorers,
      leagueName: leagueName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Match &&
        other.id == id &&
        other.homeTeamName == homeTeamName &&
        other.awayTeamName == awayTeamName &&
        other.homeLogoPath == homeLogoPath &&
        other.awayLogoPath == awayLogoPath &&
        other.homeScore == homeScore &&
        other.awayScore == awayScore &&
        listEquals(other.scorers, scorers) &&
        other.matchDateTime == matchDateTime &&
        other.venueLocation == venueLocation &&
        other.roundInfo == roundInfo &&
        other.goalScorers == goalScorers &&
        other.leagueName == leagueName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        homeTeamName.hashCode ^
        awayTeamName.hashCode ^
        homeLogoPath.hashCode ^
        awayLogoPath.hashCode ^
        homeScore.hashCode ^
        awayScore.hashCode ^
        scorers.hashCode ^
        matchDateTime.hashCode ^
        venueLocation.hashCode ^
        roundInfo.hashCode ^
        goalScorers.hashCode ^
        leagueName.hashCode;
  }
}

/// Scorer information entity
@immutable
class ScorerInfo {
  final String id;
  final bool isHomeTeam;
  final String time;
  final String name;
  final bool isOwnGoal;

  const ScorerInfo({
    required this.id,
    required this.isHomeTeam,
    this.time = '',
    this.name = '',
    this.isOwnGoal = false,
  });

  ScorerInfo copyWith({
    String? id,
    bool? isHomeTeam,
    String? time,
    String? name,
    bool? isOwnGoal,
  }) {
    return ScorerInfo(
      id: id ?? this.id,
      isHomeTeam: isHomeTeam ?? this.isHomeTeam,
      time: time ?? this.time,
      name: name ?? this.name,
      isOwnGoal: isOwnGoal ?? this.isOwnGoal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScorerInfo &&
        other.id == id &&
        other.isHomeTeam == isHomeTeam &&
        other.time == time &&
        other.name == name &&
        other.isOwnGoal == isOwnGoal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        isHomeTeam.hashCode ^
        time.hashCode ^
        name.hashCode ^
        isOwnGoal.hashCode;
  }
}
