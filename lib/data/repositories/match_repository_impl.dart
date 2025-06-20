import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chukshin_app/domain/entities/match_entity.dart';
import 'package:chukshin_app/domain/repositories/match_repository.dart';
import 'package:chukshin_app/core/models/common_models.dart';
import 'package:flutter/foundation.dart';
import 'package:chukshin_app/data/datasources/firestore_service.dart';
import 'package:chukshin_app/data/models/match_model.dart';

/// 프로덕션 레벨 경기 데이터 Repository 구현체
/// Firestore 서비스를 사용하여 데이터 관리 제공
class MatchRepositoryImpl implements MatchRepository {
  final FirestoreService _firestoreService;

  MatchRepositoryImpl({
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreService();

  // ===== 기본 CRUD 작업 =====

  @override
  Future<MatchEntity?> getMatch(String id) async {
    try {
      final matchModel = await _firestoreService.getMatch(id);
      return matchModel?.toEntity();
    } catch (e) {
      debugPrint('❌ [Repository] 경기 조회 실패: $e');
      return null;
    }
  }

  @override
  Future<List<MatchEntity>> getAllMatches({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // 스트림을 Future로 변환하여 모든 경기 조회
      return await getMatchesStream(limit: limit).first;
    } catch (e) {
      debugPrint('❌ [Repository] 전체 경기 조회 실패: $e');
      return [];
    }
  }

  @override
  Future<void> saveMatch(MatchEntity match) async {
    try {
      final matchModel = MatchModel.fromEntity(match);
      await _firestoreService.saveMatches([matchModel]);
    } catch (e) {
      debugPrint('❌ [Repository] 경기 저장 실패: $e');
    }
  }

  @override
  Future<SaveResult> saveMatches(List<MatchEntity> matches) async {
    try {
      final matchModels = matches.map((e) => MatchModel.fromEntity(e)).toList();
      return await _firestoreService.saveMatches(matchModels);
    } catch (e) {
      debugPrint('❌ [Repository] 경기 목록 저장 실패: $e');
      return const SaveResult();
    }
  }

  @override
  Future<void> deleteMatch(String id) async {
    try {
      // 실제 삭제 로직은 추후 구현
      debugPrint('⚠️ [Repository] 경기 삭제 기능은 아직 구현되지 않음: $id');
    } catch (e) {
      debugPrint('❌ [Repository] 경기 삭제 실패: $e');
    }
  }

  // ===== 검색 및 필터링 =====

  @override
  Future<List<MatchEntity>> getMatchesByTeam(String teamName,
      {int limit = 50}) async {
    try {
      return await getMatchesStream(teamName: teamName, limit: limit).first;
    } catch (e) {
      debugPrint('❌ [Repository] 팀별 경기 조회 실패: $e');
      return [];
    }
  }

  @override
  Future<List<MatchEntity>> getMatchesByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
  }) async {
    try {
      return await getMatchesStream(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      ).first;
    } catch (e) {
      debugPrint('❌ [Repository] 날짜별 경기 조회 실패: $e');
      return [];
    }
  }

  @override
  Future<List<MatchEntity>> getMatchesByLeague({
    String? leagueCode,
    String? areaCode,
    String? season,
    int limit = 50,
  }) async {
    try {
      return await getMatchesStream(
        leagueCode: leagueCode,
        areaCode: areaCode,
        season: season,
        limit: limit,
      ).first;
    } catch (e) {
      debugPrint('❌ [Repository] 리그별 경기 조회 실패: $e');
      return [];
    }
  }

  @override
  Future<List<MatchEntity>> searchMatches({
    required String query,
    int limit = 50,
  }) async {
    try {
      return await _firestoreService.searchMatches(query: query, limit: limit);
    } catch (e) {
      debugPrint('❌ [Repository] 경기 검색 실패: $e');
      return [];
    }
  }

  @override
  Future<List<MatchEntity>> getRecentMatches({
    int limit = 20,
    String? teamName,
  }) async {
    try {
      return await _firestoreService.getRecentMatches(
        limit: limit,
        teamName: teamName,
      );
    } catch (e) {
      debugPrint('❌ [Repository] 최근 경기 조회 실패: $e');
      return [];
    }
  }

  @override
  Future<List<MatchEntity>> getUpcomingMatches({
    int limit = 20,
    String? teamName,
  }) async {
    try {
      return await _firestoreService.getUpcomingMatches(
        limit: limit,
        teamName: teamName,
      );
    } catch (e) {
      debugPrint('❌ [Repository] 예정 경기 조회 실패: $e');
      return [];
    }
  }

  // ===== 실시간 스트림 =====

  @override
  Stream<List<MatchEntity>> getMatchesStream({
    String? leagueCode,
    String? areaCode,
    String? season,
    String? teamName,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    return _firestoreService.getMatchesStream(
      leagueCode: leagueCode,
      areaCode: areaCode,
      season: season,
      teamName: teamName,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  // ===== 통계 및 분석 =====

  @override
  Future<Map<String, MatchStatistics>> getTeamStatistics({
    String? leagueCode,
    String? areaCode,
    String? season,
  }) async {
    try {
      return await _firestoreService.getTeamStatistics(
        leagueCode: leagueCode,
        areaCode: areaCode,
        season: season,
      );
    } catch (e) {
      debugPrint('❌ [Repository] 팀 통계 조회 실패: $e');
      return {};
    }
  }

  @override
  Future<List<TeamRanking>> getLeagueTable({
    required String leagueCode,
    required String areaCode,
    required String season,
  }) async {
    try {
      return await _firestoreService.getLeagueTable(
        leagueCode: leagueCode,
        areaCode: areaCode,
        season: season,
      );
    } catch (e) {
      debugPrint('❌ [Repository] 리그 순위표 조회 실패: $e');
      return [];
    }
  }

  // ===== 동기화 작업 =====

  @override
  Future<SyncResult> syncAllMatches({
    List<String>? targetLeagues,
    List<String>? targetAreas,
    List<int>? targetYears,
  }) async {
    debugPrint('🚀 [Repository] 전체 동기화 시작');

    try {
      // 1. 크롤링 실행
      final crawlResult = await _firestoreService.crawlAllMatches(
        targetLeagues: targetLeagues,
        targetAreas: targetAreas,
        targetYears: targetYears,
      );

      debugPrint('📊 [Repository] 크롤링 완료: ${crawlResult.matches.length}개 경기');

      if (crawlResult.matches.isNotEmpty) {
        // 2. Firestore 저장
        final saveResult =
            await _firestoreService.saveMatches(crawlResult.matches);

        // 3. 크롤링 로그 저장
        await _firestoreService.saveCrawlLog(
          type: 'full_sync',
          matchCount: crawlResult.matches.length,
          successCount: crawlResult.successCount,
          errorCount: crawlResult.errorCount,
          duration: crawlResult.duration,
          errors: crawlResult.errors.map((e) => e.toString()).toList(),
        );

        debugPrint(
            '💾 [Repository] Firestore 저장 완료: 신규 ${saveResult.savedCount}, 업데이트 ${saveResult.updatedCount}');

        return crawlResult;
      } else {
        return crawlResult;
      }
    } catch (e) {
      debugPrint('❌ [Repository] 전체 동기화 실패: $e');
      return crawlResult;
    }
  }

  @override
  Future<SyncResult> syncRecentMatches({int daysPast = 7}) async {
    debugPrint('🔄 [Repository] 증분 동기화 시작 (최근 ${daysPast}일)');

    try {
      // 1. 증분 크롤링 실행
      final crawlResult = await _firestoreService.crawlRecentMatches(
        daysPast: daysPast,
      );

      debugPrint(
          '📊 [Repository] 증분 크롤링 완료: ${crawlResult.matches.length}개 경기');

      if (crawlResult.matches.isNotEmpty) {
        // 2. Firestore 저장
        final saveResult =
            await _firestoreService.saveMatches(crawlResult.matches);

        // 3. 크롤링 로그 저장
        await _firestoreService.saveCrawlLog(
          type: 'incremental_sync',
          matchCount: crawlResult.matches.length,
          successCount: crawlResult.successCount,
          errorCount: crawlResult.errorCount,
          duration: crawlResult.duration,
          errors: crawlResult.errors.map((e) => e.toString()).toList(),
        );

        return crawlResult;
      } else {
        return crawlResult;
      }
    } catch (e) {
      debugPrint('❌ [Repository] 증분 동기화 실패: $e');
      return crawlResult;
    }
  }

  @override
  Future<SyncResult?> getLastSyncResult() async {
    return null;
  }

  // ===== 편집 세션 관리 =====

  @override
  MatchEntity getCurrentEditingMatch() {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void updateCurrentEditingMatch(MatchEntity match) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void initializeEditingSession([MatchEntity? initialMatch]) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  Future<void> finalizeEditingSession() async {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  // ===== 부분 업데이트 메서드 =====

  @override
  void updateHomeTeamName(String name) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void updateAwayTeamName(String name) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void updateHomeScore(int? score) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void updateAwayScore(int? score) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void updateHomeLogo(String logoPath) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void updateAwayLogo(String logoPath) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void updateMatchDateTime(DateTime dateTime) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void updateVenue(String venue) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  @override
  void updateLeagueInfo({
    String? leagueCode,
    String? areaCode,
    String? season,
  }) {
    throw StateError(
        '편집 세션이 초기화되지 않았습니다. initializeEditingSession()을 먼저 호출하세요.');
  }

  // ===== 세션 및 리소스 관리 =====

  @override
  bool get isSessionValid => false;

  @override
  Map<String, String> get sessionInfo => {};

  @override
  bool validateMatch(MatchEntity match) {
    // 기본 유효성 검사
    if (match.homeTeam.isEmpty || match.awayTeam.isEmpty) {
      return false;
    }
    if (match.leagueCode.isEmpty || match.areaCode.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Future<bool> isDuplicateMatch(MatchEntity match) async {
    try {
      // 같은 날짜, 같은 팀으로 경기가 있는지 확인
      final existingMatches = await getMatchesByDateRange(
        match.matchDate.subtract(const Duration(hours: 2)),
        match.matchDate.add(const Duration(hours: 2)),
        limit: 10,
      );

      return existingMatches.any((existing) =>
          existing.homeTeam == match.homeTeam &&
          existing.awayTeam == match.awayTeam);
    } catch (e) {
      debugPrint('❌ [Repository] 중복 검사 실패: $e');
      return false;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      // 캐시 삭제 로직 (추후 구현)
      debugPrint('⚠️ [Repository] 캐시 삭제 기능은 아직 구현되지 않음');
    } catch (e) {
      debugPrint('❌ [Repository] 캐시 삭제 실패: $e');
    }
  }

  @override
  Future<void> dispose() async {
    // No resources to dispose
  }
}

/// Provider for match repository
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepositoryImpl();
});
