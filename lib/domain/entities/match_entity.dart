import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 경기 데이터 도메인 엔티티
/// 비즈니스 로직과 불변성을 보장하는 프로덕션 레벨 모델
class MatchEntity extends Equatable {
  /// 고유 식별자
  final String id;

  /// 경기 기본 정보
  final String matchId; // JoinKFA 경기 ID
  final String homeTeam; // 홈팀명
  final String awayTeam; // 원정팀명
  final int homeScore; // 홈팀 득점
  final int awayScore; // 원정팀 득점

  /// 경기 일정 정보
  final DateTime matchDate; // 경기 날짜
  final String matchTime; // 경기 시간 (HH:mm)
  final String venue; // 경기장

  /// 경기 상태 및 분류
  final MatchStatus status; // 경기 상태
  final String leagueCode; // 리그 코드 (K5, K6, K7)
  final String areaCode; // 지역 코드 (BS, KN)
  final String season; // 시즌 (YYYY)
  final int round; // 라운드
  final String divisionId; // 디비전 ID

  /// 메타데이터
  final DateTime createdAt; // 생성 시간
  final DateTime updatedAt; // 수정 시간
  final DateTime crawledAt; // 크롤링 시간

  const MatchEntity({
    required this.id,
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.matchDate,
    required this.matchTime,
    required this.venue,
    required this.status,
    required this.leagueCode,
    required this.areaCode,
    required this.season,
    required this.round,
    required this.divisionId,
    required this.createdAt,
    required this.updatedAt,
    required this.crawledAt,
  });

  /// 경기 결과 계산
  MatchResult get result {
    if (status != MatchStatus.completed) {
      return MatchResult.pending;
    }

    if (homeScore > awayScore) {
      return MatchResult.homeWin;
    } else if (awayScore > homeScore) {
      return MatchResult.awayWin;
    } else {
      return MatchResult.draw;
    }
  }

  /// 총 득점
  int get totalScore => homeScore + awayScore;

  /// 득점차
  int get scoreDifference => (homeScore - awayScore).abs();

  /// 경기가 완료되었는지 확인
  bool get isCompleted => status == MatchStatus.completed;

  /// 경기가 예정된 상태인지 확인
  bool get isScheduled => status == MatchStatus.scheduled;

  /// 리그명 반환
  String get leagueName {
    switch (leagueCode) {
      case 'K5':
        return 'K5리그';
      case 'K6':
        return 'K6리그';
      case 'K7':
        return 'K7리그';
      default:
        return '알 수 없는 리그';
    }
  }

  /// 지역명 반환
  String get areaName {
    switch (areaCode) {
      case 'BS':
        return '부산';
      case 'KN':
        return '경남';
      default:
        return '알 수 없는 지역';
    }
  }

  /// 경기 결과 텍스트
  String get resultText {
    switch (result) {
      case MatchResult.homeWin:
        return '$homeTeam 승리';
      case MatchResult.awayWin:
        return '$awayTeam 승리';
      case MatchResult.draw:
        return '무승부';
      case MatchResult.pending:
        return '경기 예정';
    }
  }

  /// 스코어 텍스트
  String get scoreText {
    if (status == MatchStatus.scheduled) {
      return 'VS';
    }
    return '$homeScore : $awayScore';
  }

  /// 복사본 생성 (불변성 유지)
  MatchEntity copyWith({
    String? id,
    String? matchId,
    String? homeTeam,
    String? awayTeam,
    int? homeScore,
    int? awayScore,
    DateTime? matchDate,
    String? matchTime,
    String? venue,
    MatchStatus? status,
    String? leagueCode,
    String? areaCode,
    String? season,
    int? round,
    String? divisionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? crawledAt,
  }) {
    return MatchEntity(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      matchDate: matchDate ?? this.matchDate,
      matchTime: matchTime ?? this.matchTime,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      leagueCode: leagueCode ?? this.leagueCode,
      areaCode: areaCode ?? this.areaCode,
      season: season ?? this.season,
      round: round ?? this.round,
      divisionId: divisionId ?? this.divisionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      crawledAt: crawledAt ?? this.crawledAt,
    );
  }

  /// 고유 ID 생성 (중복 방지)
  static String generateId({
    required String leagueCode,
    required String areaCode,
    required String season,
    required String homeTeam,
    required String awayTeam,
    required DateTime matchDate,
  }) {
    final dateStr =
        '${matchDate.year}${matchDate.month.toString().padLeft(2, '0')}${matchDate.day.toString().padLeft(2, '0')}';
    final teams = [homeTeam, awayTeam]..sort(); // 팀명 정렬로 일관성 보장
    return '${leagueCode}_${areaCode}_${season}_${teams.join('_')}_$dateStr'
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .toLowerCase();
  }

  /// 빈 경기 엔티티 생성 (편집 세션용)
  static MatchEntity empty() {
    final now = DateTime.now();
    return MatchEntity(
      id: '',
      matchId: '',
      homeTeam: '',
      awayTeam: '',
      homeScore: 0,
      awayScore: 0,
      matchDate: now,
      matchTime: '00:00',
      venue: '',
      status: MatchStatus.scheduled,
      leagueCode: '',
      areaCode: '',
      season: now.year.toString(),
      round: 0,
      divisionId: '',
      createdAt: now,
      updatedAt: now,
      crawledAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        matchId,
        homeTeam,
        awayTeam,
        homeScore,
        awayScore,
        matchDate,
        matchTime,
        venue,
        status,
        leagueCode,
        areaCode,
        season,
        round,
        divisionId,
        createdAt,
        updatedAt,
        crawledAt,
      ];

  @override
  String toString() {
    return 'MatchEntity(id: $id, $homeTeam vs $awayTeam, score: $scoreText, status: $status, date: ${matchDate.toIso8601String()})';
  }
}

/// 경기 상태 열거형
enum MatchStatus {
  scheduled('scheduled', '경기 예정'),
  inProgress('in_progress', '경기 중'),
  completed('completed', '경기 완료'),
  postponed('postponed', '연기'),
  cancelled('cancelled', '취소');

  const MatchStatus(this.code, this.displayName);

  final String code;
  final String displayName;

  static MatchStatus fromCode(String code) {
    return MatchStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => MatchStatus.scheduled,
    );
  }
}

/// 경기 결과 열거형
enum MatchResult {
  homeWin('home_win', '홈팀 승리'),
  awayWin('away_win', '원정팀 승리'),
  draw('draw', '무승부'),
  pending('pending', '경기 예정');

  const MatchResult(this.code, this.displayName);

  final String code;
  final String displayName;
}

/// 경기 통계 정보
class MatchStatistics {
  final String teamName;
  final int totalMatches;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  const MatchStatistics({
    required this.teamName,
    required this.totalMatches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  /// 승점 계산 (승리: 3점, 무승부: 1점, 패배: 0점)
  int get points => (wins * 3) + draws;

  /// 득실차 계산
  int get goalDifference => goalsFor - goalsAgainst;

  /// 승률 계산 (백분율)
  double get winRate => totalMatches > 0 ? (wins / totalMatches) * 100 : 0.0;

  /// 평균 득점
  double get averageGoalsFor =>
      totalMatches > 0 ? goalsFor / totalMatches : 0.0;

  /// 평균 실점
  double get averageGoalsAgainst =>
      totalMatches > 0 ? goalsAgainst / totalMatches : 0.0;
}
