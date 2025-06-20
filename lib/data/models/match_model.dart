import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chukshin_app/domain/entities/match_entity.dart';

/// 경기 데이터 DTO 모델 (Firestore 연동)
/// JSON 직렬화/역직렬화 및 도메인 엔티티 변환 담당
class MatchModel {
  final String id;
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final DateTime matchDate;
  final String matchTime;
  final String venue;
  final String status;
  final String leagueCode;
  final String areaCode;
  final String season;
  final int round;
  final String divisionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime crawledAt;

  const MatchModel({
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

  /// JoinKFA API 응답에서 MatchModel 생성
  factory MatchModel.fromJoinKFAApi({
    required String leagueCode,
    required String areaCode,
    required String season,
    required Map<String, dynamic> apiData,
  }) {
    try {
      // API 응답 데이터 파싱
      final homeTeam =
          _parseString(apiData['HOME_TEAM'] ?? apiData['home_team'] ?? '');
      final awayTeam =
          _parseString(apiData['AWAY_TEAM'] ?? apiData['away_team'] ?? '');
      final homeScore =
          _parseInt(apiData['HOME_SCORE'] ?? apiData['home_score']);
      final awayScore =
          _parseInt(apiData['AWAY_SCORE'] ?? apiData['away_score']);

      // 경기 날짜 파싱
      final matchDate = _parseDate(apiData['MATCH_DATE'] ??
          apiData['match_date'] ??
          apiData['MAT_DATE']);

      final matchTime = _parseString(
          apiData['MATCH_TIME'] ?? apiData['match_time'] ?? '00:00');
      final venue = _parseString(apiData['VENUE'] ?? apiData['venue'] ?? '미정');
      final matchId =
          _parseString(apiData['MATCH_ID'] ?? apiData['match_id'] ?? '');
      final round = _parseInt(apiData['ROUND'] ?? apiData['round']);
      final divisionId =
          _parseString(apiData['DIVISION_ID'] ?? apiData['division_id'] ?? '');

      // 경기 상태 결정
      final status = _determineMatchStatus(homeScore, awayScore, matchDate);

      final now = DateTime.now();

      // 고유 ID 생성
      final id = MatchEntity.generateId(
        leagueCode: leagueCode,
        areaCode: areaCode,
        season: season,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        matchDate: matchDate,
      );

      return MatchModel(
        id: id,
        matchId: matchId,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeScore: homeScore,
        awayScore: awayScore,
        matchDate: matchDate,
        matchTime: matchTime,
        venue: venue,
        status: status,
        leagueCode: leagueCode,
        areaCode: areaCode,
        season: season,
        round: round,
        divisionId: divisionId,
        createdAt: now,
        updatedAt: now,
        crawledAt: now,
      );
    } catch (e) {
      throw FormatException('JoinKFA API 데이터 파싱 실패: $e\nData: $apiData');
    }
  }

  /// Firestore DocumentSnapshot에서 MatchModel 생성
  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      return MatchModel(
        id: doc.id,
        matchId: data['matchId'] ?? '',
        homeTeam: data['homeTeam'] ?? '',
        awayTeam: data['awayTeam'] ?? '',
        homeScore: data['homeScore'] ?? 0,
        awayScore: data['awayScore'] ?? 0,
        matchDate: (data['matchDate'] as Timestamp).toDate(),
        matchTime: data['matchTime'] ?? '00:00',
        venue: data['venue'] ?? '',
        status: data['status'] ?? 'scheduled',
        leagueCode: data['leagueCode'] ?? '',
        areaCode: data['areaCode'] ?? '',
        season: data['season'] ?? '',
        round: data['round'] ?? 0,
        divisionId: data['divisionId'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        crawledAt: (data['crawledAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      throw FormatException('Firestore 데이터 파싱 실패: $e\nDoc ID: ${doc.id}');
    }
  }

  /// JSON Map에서 MatchModel 생성
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? '',
      matchId: json['matchId'] ?? '',
      homeTeam: json['homeTeam'] ?? '',
      awayTeam: json['awayTeam'] ?? '',
      homeScore: json['homeScore'] ?? 0,
      awayScore: json['awayScore'] ?? 0,
      matchDate: DateTime.parse(json['matchDate']),
      matchTime: json['matchTime'] ?? '00:00',
      venue: json['venue'] ?? '',
      status: json['status'] ?? 'scheduled',
      leagueCode: json['leagueCode'] ?? '',
      areaCode: json['areaCode'] ?? '',
      season: json['season'] ?? '',
      round: json['round'] ?? 0,
      divisionId: json['divisionId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      crawledAt: DateTime.parse(json['crawledAt']),
    );
  }

  /// Firestore 저장용 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'matchDate': Timestamp.fromDate(matchDate),
      'matchTime': matchTime,
      'venue': venue,
      'status': status,
      'leagueCode': leagueCode,
      'areaCode': areaCode,
      'season': season,
      'round': round,
      'divisionId': divisionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'crawledAt': Timestamp.fromDate(crawledAt),

      // 검색 및 정렬용 추가 필드
      'teams': [homeTeam, awayTeam], // 팀 검색용
      'matchDateYear': matchDate.year,
      'matchDateMonth': matchDate.month,
      'matchDateDay': matchDate.day,
      'totalScore': homeScore + awayScore,
      'isCompleted': status == 'completed',
    };
  }

  /// JSON 직렬화용 Map으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'matchDate': matchDate.toIso8601String(),
      'matchTime': matchTime,
      'venue': venue,
      'status': status,
      'leagueCode': leagueCode,
      'areaCode': areaCode,
      'season': season,
      'round': round,
      'divisionId': divisionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'crawledAt': crawledAt.toIso8601String(),
    };
  }

  /// 도메인 엔티티로 변환
  MatchEntity toEntity() {
    return MatchEntity(
      id: id,
      matchId: matchId,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: homeScore,
      awayScore: awayScore,
      matchDate: matchDate,
      matchTime: matchTime,
      venue: venue,
      status: MatchStatus.fromCode(status),
      leagueCode: leagueCode,
      areaCode: areaCode,
      season: season,
      round: round,
      divisionId: divisionId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      crawledAt: crawledAt,
    );
  }

  /// 도메인 엔티티에서 MatchModel 생성
  factory MatchModel.fromEntity(MatchEntity entity) {
    return MatchModel(
      id: entity.id,
      matchId: entity.matchId,
      homeTeam: entity.homeTeam,
      awayTeam: entity.awayTeam,
      homeScore: entity.homeScore,
      awayScore: entity.awayScore,
      matchDate: entity.matchDate,
      matchTime: entity.matchTime,
      venue: entity.venue,
      status: entity.status.code,
      leagueCode: entity.leagueCode,
      areaCode: entity.areaCode,
      season: entity.season,
      round: entity.round,
      divisionId: entity.divisionId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      crawledAt: entity.crawledAt,
    );
  }

  /// 업데이트된 복사본 생성
  MatchModel copyWithUpdate({
    int? homeScore,
    int? awayScore,
    String? status,
    String? venue,
    String? matchTime,
  }) {
    return MatchModel(
      id: id,
      matchId: matchId,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      matchDate: matchDate,
      matchTime: matchTime ?? this.matchTime,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      leagueCode: leagueCode,
      areaCode: areaCode,
      season: season,
      round: round,
      divisionId: divisionId,
      createdAt: createdAt,
      updatedAt: DateTime.now(), // 업데이트 시간 갱신
      crawledAt: crawledAt,
    );
  }

  /// 데이터 검증
  bool isValid() {
    return id.isNotEmpty &&
        homeTeam.isNotEmpty &&
        awayTeam.isNotEmpty &&
        leagueCode.isNotEmpty &&
        areaCode.isNotEmpty &&
        season.isNotEmpty;
  }

  /// 중복 검사를 위한 해시값 생성
  String get duplicateCheckHash {
    return '$leagueCode-$areaCode-$season-$homeTeam-$awayTeam-${matchDate.toIso8601String().substring(0, 10)}';
  }

  // ===== 내부 유틸리티 메서드 =====

  /// 문자열 파싱 (null safe)
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  /// 정수 파싱 (null safe)
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

  /// 날짜 파싱 (다양한 형식 지원)
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();

    if (value is String) {
      // 다양한 날짜 형식 시도
      final formats = [
        RegExp(r'(\d{4})-(\d{2})-(\d{2})'), // YYYY-MM-DD
        RegExp(r'(\d{4})\.(\d{2})\.(\d{2})'), // YYYY.MM.DD
        RegExp(r'(\d{4})/(\d{2})/(\d{2})'), // YYYY/MM/DD
        RegExp(r'(\d{2})/(\d{2})/(\d{4})'), // MM/DD/YYYY
      ];

      for (final format in formats) {
        final match = format.firstMatch(value);
        if (match != null) {
          try {
            if (format == formats[3]) {
              // MM/DD/YYYY 형식
              final month = int.parse(match.group(1)!);
              final day = int.parse(match.group(2)!);
              final year = int.parse(match.group(3)!);
              return DateTime(year, month, day);
            } else {
              // YYYY-MM-DD, YYYY.MM.DD, YYYY/MM/DD 형식
              final year = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              final day = int.parse(match.group(3)!);
              return DateTime(year, month, day);
            }
          } catch (e) {
            continue;
          }
        }
      }

      // ISO 8601 형식 시도
      try {
        return DateTime.parse(value);
      } catch (e) {
        // 파싱 실패시 현재 날짜 반환
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  /// 경기 상태 결정
  static String _determineMatchStatus(
      int homeScore, int awayScore, DateTime matchDate) {
    final now = DateTime.now();

    if (matchDate.isAfter(now)) {
      return 'scheduled'; // 미래 경기
    } else if (homeScore == 0 && awayScore == 0) {
      return 'scheduled'; // 점수가 없으면 예정으로 간주
    } else {
      return 'completed'; // 점수가 있으면 완료로 간주
    }
  }

  @override
  String toString() {
    return 'MatchModel(id: $id, $homeTeam vs $awayTeam, $homeScore:$awayScore, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
