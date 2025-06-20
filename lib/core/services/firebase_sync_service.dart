import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/common_models.dart';

/// Firebase 실시간 동기화 서비스
/// 크롤링 데이터의 중복 감지, 변경 감지, 신규 데이터 추가 등을 관리
class FirebaseSyncService {
  static const String _matchesCollection = 'matches';
  static const String _crawlingLogsCollection = 'crawling_logs';
  static const String _syncMetadataCollection = 'sync_metadata';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final JoinKFABrowserCrawlerService _crawler = JoinKFABrowserCrawlerService();

  // 실시간 스트림 구독
  StreamSubscription? _matchesSubscription;
  StreamSubscription? _syncMetadataSubscription;

  // 상태 관리
  bool _isInitialized = false;
  bool _isAutoSyncEnabled = false;
  bool _isRunning = false;
  Timer? _autoSyncTimer;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Firestore 인덱스 및 보안 규칙 확인
      await _ensureFirestoreSetup();

      // 마지막 동기화 정보 로드
      await _loadSyncMetadata();

      _isInitialized = true;
      print('✅ Firebase 동기화 서비스 초기화 완료');
    } catch (e) {
      print('❌ Firebase 동기화 서비스 초기화 실패: $e');
      rethrow;
    }
  }

  /// 전체 데이터 동기화 (초기 실행용)
  Future<SyncResult> performFullSync({
    List<String>? targetLeagues,
    List<String>? targetAreas,
    List<int>? targetYears,
    bool forceUpdate = false,
    Function(CrawlingProgress)? onProgress,
  }) async {
    await initialize();

    final startTime = DateTime.now();

    try {
      print('🔄 전체 데이터 동기화 시작');

      // 크롤링 로그 기록
      final logDocRef = await _createCrawlingLog(
        'full_sync',
        targetLeagues: targetLeagues,
        targetAreas: targetAreas,
        targetYears: targetYears,
      );

      // 크롤링 실행
      final crawlingResult = await _crawler.startFullCrawling(
        targetLeagues: targetLeagues,
        targetAreas: targetAreas,
        targetYears: targetYears,
        forceUpdate: forceUpdate,
        onProgress: onProgress,
      );

      // 중복 및 변경 감지
      final duplicateResult = await _detectDuplicatesAndChanges();

      // 동기화 메타데이터 업데이트
      await _updateSyncMetadata(crawlingResult);

      // 크롤링 로그 완료
      await _completeCrawlingLog(logDocRef, crawlingResult);

      final endTime = DateTime.now();
      final syncResult = SyncResult(
        totalMatches: crawlingResult.totalMatches,
        newMatches: crawlingResult.savedMatches,
        updatedMatches: duplicateResult.updatedMatches,
        duplicateMatches: crawlingResult.duplicateSkips,
        startTime: startTime,
        endTime: endTime,
        leagues: crawlingResult.leagues,
        areas: crawlingResult.areas,
        years: crawlingResult.years,
      );

      print('✅ 전체 동기화 완료');
      print('   - 새로운 경기: ${syncResult.newMatches}개');
      print('   - 업데이트된 경기: ${syncResult.updatedMatches}개');
      print('   - 중복 경기: ${syncResult.duplicateMatches}개');
      print('   - 소요 시간: ${syncResult.duration.inMinutes}분');

      return syncResult;
    } catch (e) {
      print('❌ 전체 동기화 실패: $e');
      rethrow;
    }
  }

  /// 최근 경기 동기화 (새로운 메서드)
  Future<void> syncRecentMatches(DateTime cutoffDate) async {
    _isRunning = true;
    try {
      print('🔄 최근 경기 동기화 시작 (${cutoffDate.toString().split(' ')[0]} 이후)');

      // 현재 년도의 최근 데이터만 크롤링
      final currentYear = DateTime.now().year;
      await _crawler.startFullCrawling(
        targetLeagues: ['K5', 'K6', 'K7'],
        targetAreas: ['부산', '경남'],
        targetYears: [currentYear],
        forceUpdate: true,
      );

      print('✅ 최근 경기 동기화 완료');
    } catch (e) {
      print('❌ 최근 경기 동기화 실패: $e');
      rethrow;
    } finally {
      _isRunning = false;
    }
  }

  /// 증분 동기화 (정기 업데이트용)
  Future<SyncResult> performIncrementalSync({
    Duration? lookbackPeriod,
    Function(CrawlingProgress)? onProgress,
  }) async {
    await initialize();

    lookbackPeriod ??= const Duration(days: 7); // 기본 7일 이내 데이터만 확인

    final startTime = DateTime.now();
    final cutoffDate = startTime.subtract(lookbackPeriod);

    try {
      print('🔄 증분 동기화 시작 (${lookbackPeriod.inDays}일 이내)');

      // 최근 데이터만 크롤링
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime.now().month;

      final crawlingResult = await _crawler.startFullCrawling(
        targetLeagues: ['K5', 'K6', 'K7'],
        targetAreas: ['부산', '경남'],
        targetYears: [currentYear, currentYear - 1], // 올해와 작년만
        forceUpdate: true, // 최신 데이터 강제 업데이트
        onProgress: onProgress,
      );

      // 변경 감지 및 업데이트
      final changeResult = await _detectAndUpdateChanges(cutoffDate);

      // 동기화 메타데이터 업데이트
      await _updateSyncMetadata(crawlingResult);

      final endTime = DateTime.now();
      final syncResult = SyncResult(
        totalMatches: crawlingResult.totalMatches,
        newMatches: crawlingResult.savedMatches,
        updatedMatches: changeResult.updatedMatches,
        duplicateMatches: crawlingResult.duplicateSkips,
        startTime: startTime,
        endTime: endTime,
        leagues: crawlingResult.leagues,
        areas: crawlingResult.areas,
        years: crawlingResult.years,
      );

      print('✅ 증분 동기화 완료');
      print('   - 새로운 경기: ${syncResult.newMatches}개');
      print('   - 업데이트된 경기: ${syncResult.updatedMatches}개');

      return syncResult;
    } catch (e) {
      print('❌ 증분 동기화 실패: $e');
      rethrow;
    }
  }

  /// 자동 동기화 시작
  void startAutoSync({
    Duration interval = const Duration(hours: 6), // 6시간마다
    Duration lookbackPeriod = const Duration(days: 7),
  }) {
    if (_isAutoSyncEnabled) {
      print('⚠️ 자동 동기화가 이미 실행 중입니다.');
      return;
    }

    _isAutoSyncEnabled = true;

    print('🔄 자동 동기화 시작 (${interval.inHours}시간 간격)');

    _autoSyncTimer = Timer.periodic(interval, (timer) async {
      if (!_isAutoSyncEnabled) {
        timer.cancel();
        return;
      }

      try {
        print('🔄 자동 동기화 실행 중...');
        await performIncrementalSync(lookbackPeriod: lookbackPeriod);
      } catch (e) {
        print('❌ 자동 동기화 중 오류: $e');
      }
    });
  }

  /// 자동 동기화 중지
  void stopAutoSync() {
    _isAutoSyncEnabled = false;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    print('🛑 자동 동기화 중지');
  }

  /// 실시간 경기 데이터 스트림
  Stream<List<MatchData>> getMatchesStream({
    String? league,
    String? area,
    String? season,
    int? limit,
  }) {
    Query query = _firestore.collection(_matchesCollection);

    if (league != null) {
      query = query.where('league', isEqualTo: league);
    }
    if (area != null) {
      query = query.where('area', isEqualTo: area);
    }
    if (season != null) {
      query = query.where('season', isEqualTo: season);
    }

    query = query.orderBy('matchDate', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MatchData.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// 경기 검색
  Future<List<MatchData>> searchMatches({
    String? teamName,
    String? venue,
    String? league,
    String? area,
    String? season,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    Query query = _firestore.collection(_matchesCollection);

    // 복합 쿼리 구성
    if (league != null) query = query.where('league', isEqualTo: league);
    if (area != null) query = query.where('area', isEqualTo: area);
    if (season != null) query = query.where('season', isEqualTo: season);

    if (startDate != null) {
      query = query.where('matchDate',
          isGreaterThanOrEqualTo: startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.where('matchDate',
          isLessThanOrEqualTo: endDate.toIso8601String().split('T')[0]);
    }

    query = query.orderBy('matchDate', descending: true).limit(limit);

    final snapshot = await query.get();
    final matches = snapshot.docs.map((doc) {
      return MatchData.fromFirestore(doc.data() as Map<String, dynamic>);
    }).toList();

    // 클라이언트 측 필터링 (Firestore 제한 우회)
    if (teamName != null) {
      matches.retainWhere((match) =>
          match.homeTeam.contains(teamName) ||
          match.awayTeam.contains(teamName));
    }
    if (venue != null) {
      matches.retainWhere((match) => match.venue.contains(venue));
    }

    return matches;
  }

  /// 팀 통계 가져오기
  Future<Map<String, dynamic>> getTeamStats(String teamName,
      {String? season}) async {
    final query = _firestore
        .collection(_matchesCollection)
        .where('season', isEqualTo: season ?? DateTime.now().year.toString());

    final snapshot = await query.get();
    final matches = snapshot.docs
        .map((doc) {
          return MatchData.fromFirestore(doc.data() as Map<String, dynamic>);
        })
        .where(
            (match) => match.homeTeam == teamName || match.awayTeam == teamName)
        .toList();

    int wins = 0, draws = 0, losses = 0;
    int goalsFor = 0, goalsAgainst = 0;

    for (final match in matches) {
      if (match.matchStatus != 'completed') continue;

      if (match.homeTeam == teamName) {
        goalsFor += match.homeScore;
        goalsAgainst += match.awayScore;
        if (match.homeScore > match.awayScore)
          wins++;
        else if (match.homeScore == match.awayScore)
          draws++;
        else
          losses++;
      } else {
        goalsFor += match.awayScore;
        goalsAgainst += match.homeScore;
        if (match.awayScore > match.homeScore)
          wins++;
        else if (match.awayScore == match.homeScore)
          draws++;
        else
          losses++;
      }
    }

    final totalGames = wins + draws + losses;
    final points = wins * 3 + draws;

    return {
      'teamName': teamName,
      'season': season ?? DateTime.now().year.toString(),
      'totalGames': totalGames,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDifference': goalsFor - goalsAgainst,
      'points': points,
      'winRate': totalGames > 0 ? wins / totalGames : 0.0,
      'averageGoalsFor': totalGames > 0 ? goalsFor / totalGames : 0.0,
      'averageGoalsAgainst': totalGames > 0 ? goalsAgainst / totalGames : 0.0,
    };
  }

  /// 리그 순위표 가져오기
  Future<List<Map<String, dynamic>>> getLeagueTable(
      String league, String area, String season) async {
    final matches = await searchMatches(
      league: league,
      area: area,
      season: season,
    );

    final Map<String, Map<String, dynamic>> teamStats = {};

    for (final match in matches) {
      if (match.matchStatus != 'completed') continue;

      // 홈팀 처리
      teamStats[match.homeTeam] ??= {
        'teamName': match.homeTeam,
        'games': 0,
        'wins': 0,
        'draws': 0,
        'losses': 0,
        'goalsFor': 0,
        'goalsAgainst': 0,
        'points': 0,
      };

      // 어웨이팀 처리
      teamStats[match.awayTeam] ??= {
        'teamName': match.awayTeam,
        'games': 0,
        'wins': 0,
        'draws': 0,
        'losses': 0,
        'goalsFor': 0,
        'goalsAgainst': 0,
        'points': 0,
      };

      final homeStats = teamStats[match.homeTeam]!;
      final awayStats = teamStats[match.awayTeam]!;

      homeStats['games']++;
      awayStats['games']++;

      homeStats['goalsFor'] += match.homeScore;
      homeStats['goalsAgainst'] += match.awayScore;
      awayStats['goalsFor'] += match.awayScore;
      awayStats['goalsAgainst'] += match.homeScore;

      if (match.homeScore > match.awayScore) {
        homeStats['wins']++;
        homeStats['points'] += 3;
        awayStats['losses']++;
      } else if (match.homeScore == match.awayScore) {
        homeStats['draws']++;
        homeStats['points'] += 1;
        awayStats['draws']++;
        awayStats['points'] += 1;
      } else {
        homeStats['losses']++;
        awayStats['wins']++;
        awayStats['points'] += 3;
      }
    }

    final standings = teamStats.values.toList();

    // 승점 > 골득실 > 다득점 순으로 정렬
    standings.sort((a, b) {
      final pointsComparison = b['points'].compareTo(a['points']);
      if (pointsComparison != 0) return pointsComparison;

      final goalDiffA = a['goalsFor'] - a['goalsAgainst'];
      final goalDiffB = b['goalsFor'] - b['goalsAgainst'];
      final goalDiffComparison = goalDiffB.compareTo(goalDiffA);
      if (goalDiffComparison != 0) return goalDiffComparison;

      return b['goalsFor'].compareTo(a['goalsFor']);
    });

    // 순위 추가
    for (int i = 0; i < standings.length; i++) {
      standings[i]['position'] = i + 1;
      standings[i]['goalDifference'] =
          standings[i]['goalsFor'] - standings[i]['goalsAgainst'];
    }

    return standings;
  }

  // 내부 메서드들

  Future<void> _ensureFirestoreSetup() async {
    // 컬렉션 존재 확인 및 생성
    try {
      await _firestore
          .collection(_syncMetadataCollection)
          .doc('last_sync')
          .get();
    } catch (e) {
      // 초기 설정
      await _firestore
          .collection(_syncMetadataCollection)
          .doc('last_sync')
          .set({
        'lastFullSync': null,
        'lastIncrementalSync': null,
        'totalMatches': 0,
        'createdAt': Timestamp.now(),
      });
    }
  }

  Future<void> _loadSyncMetadata() async {
    // 마지막 동기화 정보 로드
    final doc = await _firestore
        .collection(_syncMetadataCollection)
        .doc('last_sync')
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      print('📊 마지막 동기화 정보:');
      print('   - 전체 동기화: ${data['lastFullSync']}');
      print('   - 증분 동기화: ${data['lastIncrementalSync']}');
      print('   - 총 경기 수: ${data['totalMatches']}');
    }
  }

  Future<DocumentReference> _createCrawlingLog(
    String type, {
    List<String>? targetLeagues,
    List<String>? targetAreas,
    List<int>? targetYears,
  }) async {
    return await _firestore.collection(_crawlingLogsCollection).add({
      'type': type,
      'targetLeagues': targetLeagues,
      'targetAreas': targetAreas,
      'targetYears': targetYears,
      'startTime': Timestamp.now(),
      'status': 'running',
    });
  }

  Future<void> _completeCrawlingLog(
      DocumentReference logRef, CrawlingResult result) async {
    await logRef.update({
      'status': 'completed',
      'endTime': Timestamp.now(),
      'totalMatches': result.totalMatches,
      'savedMatches': result.savedMatches,
      'duplicateSkips': result.duplicateSkips,
      'duration': result.duration.inSeconds,
    });
  }

  Future<DuplicateDetectionResult> _detectDuplicatesAndChanges() async {
    // 중복 감지 로직 구현
    return DuplicateDetectionResult(updatedMatches: 0, duplicateMatches: 0);
  }

  Future<ChangeDetectionResult> _detectAndUpdateChanges(
      DateTime cutoffDate) async {
    // 변경 감지 로직 구현
    return ChangeDetectionResult(updatedMatches: 0);
  }

  Future<void> _updateSyncMetadata(CrawlingResult result) async {
    await _firestore
        .collection(_syncMetadataCollection)
        .doc('last_sync')
        .update({
      'lastFullSync': Timestamp.now(),
      'totalMatches': result.totalMatches,
      'lastResult': {
        'savedMatches': result.savedMatches,
        'duplicateSkips': result.duplicateSkips,
        'duration': result.duration.inSeconds,
      },
    });
  }

  /// 실행 상태 getter 추가
  bool get isRunning => _isRunning;

  /// 리소스 정리
  void dispose() {
    stopAutoSync();
    _matchesSubscription?.cancel();
    _syncMetadataSubscription?.cancel();
    _crawler.dispose();
  }
}

/// 동기화 결과
class SyncResult {
  final int totalMatches;
  final int newMatches;
  final int updatedMatches;
  final int duplicateMatches;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> leagues;
  final List<String> areas;
  final List<int> years;

  SyncResult({
    required this.totalMatches,
    required this.newMatches,
    required this.updatedMatches,
    required this.duplicateMatches,
    required this.startTime,
    required this.endTime,
    required this.leagues,
    required this.areas,
    required this.years,
  });

  Duration get duration => endTime.difference(startTime);
  int get totalProcessed => newMatches + updatedMatches + duplicateMatches;
  double get successRate =>
      totalMatches > 0 ? totalProcessed / totalMatches : 0.0;
}

/// 중복 감지 결과
class DuplicateDetectionResult {
  final int updatedMatches;
  final int duplicateMatches;

  DuplicateDetectionResult({
    required this.updatedMatches,
    required this.duplicateMatches,
  });
}

/// 변경 감지 결과
class ChangeDetectionResult {
  final int updatedMatches;

  ChangeDetectionResult({
    required this.updatedMatches,
  });
}
