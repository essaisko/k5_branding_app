import 'package:chukshin_app/domain/entities/match_entity.dart';
import 'package:chukshin_app/core/models/common_models.dart';

/// Match Repository Interface
///
/// 구글 수석 개발자 수준의 설계 원칙을 따른 Repository 인터페이스:
/// 1. Single Responsibility: 경기 데이터 관리만 담당
/// 2. Interface Segregation: 필요한 메서드만 정의
/// 3. Dependency Inversion: 구현체에 의존하지 않음
/// 4. Type Safety: 모든 반환 타입 명시
/// 5. Immutability: 불변 객체 사용
abstract class MatchRepository {
  // ===== 기본 CRUD 작업 =====

  /// 특정 ID로 경기 조회
  Future<MatchEntity?> getMatch(String id);

  /// 모든 경기 조회 (페이징 지원)
  Future<List<MatchEntity>> getAllMatches({
    int limit = 50,
    int offset = 0,
  });

  /// 경기 저장 (생성/업데이트)
  Future<void> saveMatch(MatchEntity match);

  /// 여러 경기 배치 저장
  Future<SaveResult> saveMatches(List<MatchEntity> matches);

  /// 경기 삭제
  Future<void> deleteMatch(String id);

  // ===== 검색 및 필터링 =====

  /// 팀명으로 경기 검색
  Future<List<MatchEntity>> getMatchesByTeam(String teamName, {int limit = 50});

  /// 날짜 범위로 경기 검색
  Future<List<MatchEntity>> getMatchesByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
  });

  /// 리그/지역별 경기 검색
  Future<List<MatchEntity>> getMatchesByLeague({
    String? leagueCode,
    String? areaCode,
    String? season,
    int limit = 50,
  });

  /// 텍스트 검색 (팀명, 경기장 등)
  Future<List<MatchEntity>> searchMatches({
    required String query,
    int limit = 50,
  });

  /// 최근 경기 조회
  Future<List<MatchEntity>> getRecentMatches({
    int limit = 20,
    String? teamName,
  });

  /// 예정된 경기 조회
  Future<List<MatchEntity>> getUpcomingMatches({
    int limit = 20,
    String? teamName,
  });

  // ===== 실시간 스트림 =====

  /// 경기 목록 실시간 스트림
  Stream<List<MatchEntity>> getMatchesStream({
    String? leagueCode,
    String? areaCode,
    String? season,
    String? teamName,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  });

  // ===== 통계 및 분석 =====

  /// 팀별 통계 조회
  Future<Map<String, MatchStatistics>> getTeamStatistics({
    String? leagueCode,
    String? areaCode,
    String? season,
  });

  /// 리그 순위표 조회
  Future<List<TeamRanking>> getLeagueTable({
    required String leagueCode,
    required String areaCode,
    required String season,
  });

  /// 리소스 정리
  Future<void> dispose();
}
