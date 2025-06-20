import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chukshin_app/data/models/match_model.dart';
import 'package:chukshin_app/domain/entities/match_entity.dart';
import 'package:chukshin_app/core/models/common_models.dart';

/// 프로덕션 레벨 Firestore 서비스
/// 중복 방지, 배치 처리, 실시간 동기화 담당
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 컬렉션 참조
  static const String _matchesCollection = 'matches';
  static const String _crawlLogsCollection = 'crawl_logs';
  static const String _syncMetadataCollection = 'sync_metadata';

  // 배치 설정
  static const int _batchSize = 500; // Firestore 제한: 500개
  static const Duration _streamTimeout = Duration(seconds: 30);

  /// 경기 데이터 배치 저장 (중복 방지)
  Future<SaveResult> saveMatches(List<MatchModel> matches) async {
    if (matches.isEmpty) {
      return SaveResult();
    }

    debugPrint('💾 [Firestore] 경기 데이터 저장 시작: ${matches.length}개');

    int savedCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;
    final batches = <WriteBatch>[];
    WriteBatch currentBatch = _firestore.batch();
    int operationsInBatch = 0;

    try {
      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];

        // 데이터 검증
        if (!match.isValid()) {
          debugPrint('⚠️ [Firestore] 유효하지 않은 데이터 스킵: ${match.id}');
          skippedCount++;
          continue;
        }

        // 중복 검사
        final existingMatch = await _getExistingMatch(match.id);
        final docRef = _firestore.collection(_matchesCollection).doc(match.id);

        if (existingMatch != null) {
          // 업데이트 필요한지 확인
          if (_shouldUpdateMatch(existingMatch, match)) {
            currentBatch.update(docRef, match.toFirestore());
            updatedCount++;
            debugPrint('🔄 [Firestore] 경기 데이터 업데이트: ${match.id}');
          } else {
            skippedCount++;
          }
        } else {
          // 새로운 데이터 추가
          currentBatch.set(docRef, match.toFirestore());
          savedCount++;
          debugPrint('✅ [Firestore] 새 경기 데이터 저장: ${match.id}');
        }

        operationsInBatch++;

        // 배치 크기 제한 확인
        if (operationsInBatch >= _batchSize || i == matches.length - 1) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationsInBatch = 0;
        }
      }

      // 모든 배치 실행
      for (int i = 0; i < batches.length; i++) {
        debugPrint('📦 [Firestore] 배치 ${i + 1}/${batches.length} 실행 중...');
        await batches[i].commit();

        // 배치 간 지연 (Rate Limiting 방지)
        if (i < batches.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // 최종 결과 생성
      final result = SaveResult(
        savedCount: savedCount,
        updatedCount: updatedCount,
        skippedCount: skippedCount,
      );

      // 동기화 메타데이터 업데이트
      await _updateSyncMetadata(result);

      debugPrint(
          '✅ [Firestore] 저장 완료 - 신규: $savedCount, 업데이트: $updatedCount, 스킵: $skippedCount');
    } catch (e) {
      debugPrint('❌ [Firestore] 저장 실패: $e');
      throw FirestoreException('경기 데이터 저장 실패: $e');
    }

    return SaveResult(
      savedCount: savedCount,
      updatedCount: updatedCount,
      skippedCount: skippedCount,
    );
  }

  /// 특정 경기 데이터 조회
  Future<MatchModel?> getMatch(String matchId) async {
    try {
      final doc =
          await _firestore.collection(_matchesCollection).doc(matchId).get();

      if (doc.exists) {
        return MatchModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Firestore] 경기 조회 실패: $e');
      return null;
    }
  }

  /// 경기 목록 실시간 스트림
  Stream<List<MatchEntity>> getMatchesStream({
    String? leagueCode,
    String? areaCode,
    String? season,
    String? teamName,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    try {
      Query query = _firestore.collection(_matchesCollection);

      // 필터 적용
      if (leagueCode != null && leagueCode.isNotEmpty) {
        query = query.where('leagueCode', isEqualTo: leagueCode);
      }

      if (areaCode != null && areaCode.isNotEmpty) {
        query = query.where('areaCode', isEqualTo: areaCode);
      }

      if (season != null && season.isNotEmpty) {
        query = query.where('season', isEqualTo: season);
      }

      // 팀명 검색
      if (teamName != null && teamName.isNotEmpty) {
        query = query.where('teams', arrayContains: teamName);
      }

      // 날짜 범위 필터
      if (startDate != null) {
        query = query.where('matchDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('matchDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // 정렬 및 제한
      query = query.orderBy('matchDate', descending: true).limit(limit);

      return query.snapshots().timeout(_streamTimeout).map((snapshot) {
        return snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc).toEntity())
            .toList();
      });
    } catch (e) {
      debugPrint('❌ [Firestore] 스트림 생성 실패: $e');
      return Stream.error(e);
    }
  }

  /// 팀별 경기 통계 조회
  Future<Map<String, MatchStatistics>> getTeamStatistics({
    String? leagueCode,
    String? areaCode,
    String? season,
  }) async {
    try {
      Query query = _firestore.collection(_matchesCollection);

      // 완료된 경기만 조회
      query = query.where('isCompleted', isEqualTo: true);

      // 필터 적용
      if (leagueCode != null)
        query = query.where('leagueCode', isEqualTo: leagueCode);
      if (areaCode != null)
        query = query.where('areaCode', isEqualTo: areaCode);
      if (season != null) query = query.where('season', isEqualTo: season);

      final snapshot = await query.get();
      final matches =
          snapshot.docs.map((doc) => MatchModel.fromFirestore(doc)).toList();

      return _calculateTeamStatistics(matches);
    } catch (e) {
      debugPrint('❌ [Firestore] 팀 통계 조회 실패: $e');
      return {};
    }
  }

  /// 리그 순위표 조회
  Future<List<TeamRanking>> getLeagueTable({
    required String leagueCode,
    required String areaCode,
    required String season,
  }) async {
    try {
      final statistics = await getTeamStatistics(
        leagueCode: leagueCode,
        areaCode: areaCode,
        season: season,
      );

      // 순위 계산 (승점 → 득실차 → 다득점 순)
      final rankings = statistics.entries.map((entry) {
        final stats = entry.value;
        return TeamRanking(
          teamName: entry.key,
          matches: stats.totalMatches,
          wins: stats.wins,
          draws: stats.draws,
          losses: stats.losses,
          goalsFor: stats.goalsFor,
          goalsAgainst: stats.goalsAgainst,
          points: stats.points,
          goalDifference: stats.goalDifference,
        );
      }).toList();

      // 순위 정렬
      rankings.sort((a, b) {
        // 1. 승점 비교
        if (a.points != b.points) return b.points.compareTo(a.points);
        // 2. 득실차 비교
        if (a.goalDifference != b.goalDifference)
          return b.goalDifference.compareTo(a.goalDifference);
        // 3. 다득점 비교
        return b.goalsFor.compareTo(a.goalsFor);
      });

      // 순위 번호 부여
      for (int i = 0; i < rankings.length; i++) {
        rankings[i] = rankings[i].copyWith(rank: i + 1);
      }

      return rankings;
    } catch (e) {
      debugPrint('❌ [Firestore] 리그 순위표 조회 실패: $e');
      return [];
    }
  }

  /// 최근 경기 결과 조회
  Future<List<MatchEntity>> getRecentMatches({
    int limit = 20,
    String? teamName,
  }) async {
    try {
      Query query = _firestore.collection(_matchesCollection);

      // 팀 필터
      if (teamName != null && teamName.isNotEmpty) {
        query = query.where('teams', arrayContains: teamName);
      }

      // 완료된 경기만
      query = query.where('isCompleted', isEqualTo: true);

      // 최신순 정렬
      query = query.orderBy('matchDate', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('❌ [Firestore] 최근 경기 조회 실패: $e');
      return [];
    }
  }

  /// 예정된 경기 조회
  Future<List<MatchEntity>> getUpcomingMatches({
    int limit = 20,
    String? teamName,
  }) async {
    try {
      Query query = _firestore.collection(_matchesCollection);

      // 팀 필터
      if (teamName != null && teamName.isNotEmpty) {
        query = query.where('teams', arrayContains: teamName);
      }

      // 예정된 경기만
      query = query.where('status', isEqualTo: 'scheduled');

      // 날짜순 정렬
      query = query.orderBy('matchDate', descending: false).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('❌ [Firestore] 예정 경기 조회 실패: $e');
      return [];
    }
  }

  /// 크롤링 로그 저장
  Future<void> saveCrawlLog({
    required String type,
    required int matchCount,
    required int successCount,
    required int errorCount,
    required Duration duration,
    List<String>? errors,
  }) async {
    try {
      await _firestore.collection(_crawlLogsCollection).add({
        'type': type,
        'matchCount': matchCount,
        'successCount': successCount,
        'errorCount': errorCount,
        'duration': duration.inSeconds,
        'timestamp': FieldValue.serverTimestamp(),
        'errors': errors ?? [],
      });
    } catch (e) {
      debugPrint('❌ [Firestore] 크롤링 로그 저장 실패: $e');
    }
  }

  /// 검색 기능 (팀명, 경기장 등)
  Future<List<MatchEntity>> searchMatches({
    required String query,
    int limit = 50,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      final futures = <Future<QuerySnapshot>>[];

      // 홈팀 검색
      futures.add(_firestore
          .collection(_matchesCollection)
          .where('homeTeam', isGreaterThanOrEqualTo: query)
          .where('homeTeam', isLessThan: query + 'z')
          .limit(limit ~/ 2)
          .get());

      // 원정팀 검색
      futures.add(_firestore
          .collection(_matchesCollection)
          .where('awayTeam', isGreaterThanOrEqualTo: query)
          .where('awayTeam', isLessThan: query + 'z')
          .limit(limit ~/ 2)
          .get());

      final results = await Future.wait(futures);
      final matches = <MatchEntity>[];
      final seenIds = <String>{};

      for (final result in results) {
        for (final doc in result.docs) {
          if (!seenIds.contains(doc.id)) {
            seenIds.add(doc.id);
            matches.add(MatchModel.fromFirestore(doc).toEntity());
          }
        }
      }

      // 날짜순 정렬
      matches.sort((a, b) => b.matchDate.compareTo(a.matchDate));

      return matches.take(limit).toList();
    } catch (e) {
      debugPrint('❌ [Firestore] 검색 실패: $e');
      return [];
    }
  }

  // ===== 내부 메서드 =====

  /// 기존 경기 데이터 조회
  Future<MatchModel?> _getExistingMatch(String matchId) async {
    try {
      final doc =
          await _firestore.collection(_matchesCollection).doc(matchId).get();

      if (doc.exists) {
        return MatchModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 경기 데이터 업데이트 필요 여부 확인
  bool _shouldUpdateMatch(MatchModel existing, MatchModel newData) {
    return existing.homeScore != newData.homeScore ||
        existing.awayScore != newData.awayScore ||
        existing.status != newData.status ||
        existing.venue != newData.venue ||
        existing.matchTime != newData.matchTime;
  }

  /// 팀 통계 계산
  Map<String, MatchStatistics> _calculateTeamStatistics(
      List<MatchModel> matches) {
    final teamStats = <String, _TeamStatsAccumulator>{};

    for (final match in matches) {
      if (match.status != 'completed') continue;

      // 홈팀 통계
      final homeStats = teamStats.putIfAbsent(
        match.homeTeam,
        () => _TeamStatsAccumulator(match.homeTeam),
      );
      homeStats.addMatch(
        goalsFor: match.homeScore,
        goalsAgainst: match.awayScore,
        isWin: match.homeScore > match.awayScore,
        isDraw: match.homeScore == match.awayScore,
      );

      // 원정팀 통계
      final awayStats = teamStats.putIfAbsent(
        match.awayTeam,
        () => _TeamStatsAccumulator(match.awayTeam),
      );
      awayStats.addMatch(
        goalsFor: match.awayScore,
        goalsAgainst: match.homeScore,
        isWin: match.awayScore > match.homeScore,
        isDraw: match.homeScore == match.awayScore,
      );
    }

    return teamStats.map((key, value) => MapEntry(key, value.toStatistics()));
  }

  /// 동기화 메타데이터 업데이트
  Future<void> _updateSyncMetadata(SaveResult result) async {
    try {
      await _firestore.collection(_syncMetadataCollection).doc('latest').set({
        'lastSyncTime': FieldValue.serverTimestamp(),
        'totalMatches': FieldValue.increment(result.savedCount),
        'lastSaveResult': result.toJson(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ [Firestore] 메타데이터 업데이트 실패: $e');
    }
  }
}

/// 팀 통계 누적 클래스 (내부 사용)
class _TeamStatsAccumulator {
  final String teamName;
  int totalMatches = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  _TeamStatsAccumulator(this.teamName);

  void addMatch({
    required int goalsFor,
    required int goalsAgainst,
    required bool isWin,
    required bool isDraw,
  }) {
    totalMatches++;
    this.goalsFor += goalsFor;
    this.goalsAgainst += goalsAgainst;

    if (isWin) {
      wins++;
    } else if (isDraw) {
      draws++;
    } else {
      losses++;
    }
  }

  MatchStatistics toStatistics() {
    return MatchStatistics(
      teamName: teamName,
      totalMatches: totalMatches,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
    );
  }
}

/// Firestore 예외 클래스
class FirestoreException implements Exception {
  final String message;
  FirestoreException(this.message);

  @override
  String toString() => 'FirestoreException: $message';
}
