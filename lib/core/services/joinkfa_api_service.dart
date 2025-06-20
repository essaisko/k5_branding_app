import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// JoinKFA API 서비스 - 2025년 시즌 지원
/// 로컬 크롤링 서버를 통해 실제 2025년 데이터 제공
class JoinKFAApiService {
  // 다양한 서버 주소 시도 (Android 에뮬레이터 고려)
  static const List<String> _serverUrls = [
    'http://localhost:5000/api',
    'http://127.0.0.1:5000/api',
    'http://10.0.2.2:5000/api', // Android 에뮬레이터용
    'http://121.145.18.34:5000/api', // 실제 로컬 IP
    'http://192.168.1.100:5000/api', // 일반적인 로컬 네트워크 IP
    'http://192.168.0.100:5000/api', // 다른 일반적인 로컬 네트워크 IP
  ];

  String? _workingServerUrl;
  Map<String, dynamic>? _cachedData;

  /// 실제 JoinKFA 2025 데이터 로드 (assets에서)
  Future<Map<String, dynamic>> _loadRealJoinKFAData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      print('📱 실제 JoinKFA 2025 데이터 로드 중...');
      final String jsonString = await rootBundle.loadString('assets/data/joinkfa_2025_records.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      _cachedData = data;
      print('✅ JoinKFA 2025 데이터 로드 완료');
      print('   - 경기 결과: ${data['matches']?.length ?? 0}개');
      print('   - 경기 일정: ${data['schedules']?.length ?? 0}개');
      print('   - 팀: ${data['teams']?.length ?? 0}개');
      print('   - 리그: ${data['leagues']?.length ?? 0}개');
      
      return data;
    } catch (e) {
      print('❌ JoinKFA 2025 데이터 로드 실패: $e');
      throw Exception('실제 JoinKFA 2025 데이터를 로드할 수 없습니다: $e');
    }
  }

  /// 작동하는 서버 URL 찾기
  Future<String?> _findWorkingServer() async {
    if (_workingServerUrl != null) {
      return _workingServerUrl;
    }

    for (String serverUrl in _serverUrls) {
      try {
        print('서버 연결 시도: $serverUrl');
        final response = await http.get(
          Uri.parse('$serverUrl/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'healthy') {
            print('✅ 서버 연결 성공: $serverUrl');
            _workingServerUrl = serverUrl;
            return serverUrl;
          }
        }
      } catch (e) {
        print('❌ 서버 연결 실패: $serverUrl - $e');
        continue;
      }
    }

    print('❌ 모든 서버 주소 연결 실패');
    return null;
  }

  /// 리그 목록 가져오기 (2025년 시즌)
  Future<List<String>> getLeagues() async {
    try {
      // 먼저 실제 JoinKFA 데이터에서 로드 시도
      final data = await _loadRealJoinKFAData();
      final leagues = List<Map<String, dynamic>>.from(data['leagues'] ?? []);
      final leagueNames = leagues.map((league) => league['name'] as String).toList();
      
      if (leagueNames.isNotEmpty) {
        print('✅ 실제 JoinKFA 리그 목록: ${leagueNames.join(', ')}');
        return leagueNames;
      }
    } catch (e) {
      print('⚠️ 실제 데이터 로드 실패, 서버 시도: $e');
    }

    // 실제 데이터 로드 실패 시 서버 시도
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      // 서버도 실패 시 기본 리그 반환
      return ['K5리그 경남권', 'K5리그 부산권'];
    }

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/leagues'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('리그 목록 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['leagues']);
        }
        throw Exception('서버 응답 오류: ${data['message'] ?? 'Unknown error'}');
      }
      throw Exception('HTTP 오류: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('리그 목록 가져오기 실패: $e');
      // 최종 실패 시 기본 리그 반환
      return ['K5리그 경남권', 'K5리그 부산권'];
    }
  }

  /// 특정 리그의 경기 데이터 가져오기
  Future<List<MatchRecord>> getMatches(String league) async {
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      throw Exception('크롤링 서버에 연결할 수 없습니다.');
    }

    try {
      final encodedLeague = Uri.encodeComponent(league);
      final response = await http.get(
        Uri.parse('$serverUrl/matches/$encodedLeague'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('경기 데이터 응답 ($league): ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final matches = List<Map<String, dynamic>>.from(data['matches']);
          return matches.map((match) => MatchRecord.fromJson(match)).toList();
        }
        throw Exception('서버 응답 오류: ${data['message'] ?? 'Unknown error'}');
      }
      throw Exception('HTTP 오류: ${response.statusCode}');
    } catch (e) {
      print('경기 데이터 가져오기 실패 ($league): $e');
      rethrow;
    }
  }

  /// 모든 경기 데이터 가져오기
  Future<List<MatchRecord>> getAllMatches() async {
    try {
      // 먼저 실제 JoinKFA 데이터에서 로드 시도
      final data = await _loadRealJoinKFAData();
      final matches = List<Map<String, dynamic>>.from(data['matches'] ?? []);
      final schedules = List<Map<String, dynamic>>.from(data['schedules'] ?? []);
      
      // 경기 결과와 일정을 모두 합쳐서 반환
      final allMatches = <MatchRecord>[];
      
      // 완료된 경기들
      for (final match in matches) {
        allMatches.add(MatchRecord(
          matchId: match['id'] ?? '',
          homeTeam: match['homeTeam'] ?? '',
          awayTeam: match['awayTeam'] ?? '',
          homeScore: match['homeScore'] ?? 0,
          awayScore: match['awayScore'] ?? 0,
          matchDate: match['matchDate'] ?? '',
          matchTime: match['matchTime'] ?? '',
          venue: match['venue'] ?? '',
          leagueName: match['league'] ?? 'K5',
          matchStatus: 'completed',
          season: '2025',
          division: '경남권',
          level: 5,
          round: 1,
        ));
      }
      
      // 예정된 경기들
      for (final schedule in schedules) {
        allMatches.add(MatchRecord(
          matchId: schedule['id'] ?? '',
          homeTeam: schedule['homeTeam'] ?? '',
          awayTeam: schedule['awayTeam'] ?? '',
          homeScore: 0,
          awayScore: 0,
          matchDate: schedule['matchDate'] ?? '',
          matchTime: schedule['matchTime'] ?? '',
          venue: schedule['venue'] ?? '',
          leagueName: schedule['league'] ?? 'K5',
          matchStatus: 'scheduled',
          season: '2025',
          division: '경남권',
          level: 5,
          round: 1,
        ));
      }
      
      print('✅ 실제 JoinKFA 경기 데이터: ${allMatches.length}개 (완료: ${matches.length}, 예정: ${schedules.length})');
      return allMatches;
      
    } catch (e) {
      print('⚠️ 실제 데이터 로드 실패, 서버 시도: $e');
    }

    // 실제 데이터 로드 실패 시 서버 시도
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      throw Exception('크롤링 서버에 연결할 수 없고 실제 데이터도 로드할 수 없습니다.');
    }

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/matches'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final matches = List<Map<String, dynamic>>.from(data['matches']);
          return matches.map((match) => MatchRecord.fromJson(match)).toList();
        }
      }

      throw Exception('서버에서 모든 경기 데이터를 가져올 수 없습니다: ${response.statusCode}');
    } catch (e) {
      print('모든 경기 데이터 가져오기 실패: $e');
      rethrow;
    }
  }

  /// 특정 리그의 팀 목록 가져오기
  Future<List<String>> getTeams(String league) async {
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      throw Exception('크롤링 서버에 연결할 수 없습니다.');
    }

    try {
      final encodedLeague = Uri.encodeComponent(league);
      final response = await http.get(
        Uri.parse('$serverUrl/teams/$encodedLeague'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['teams']);
        }
      }

      throw Exception('서버에서 팀 목록을 가져올 수 없습니다: ${response.statusCode}');
    } catch (e) {
      print('팀 목록 가져오기 실패 ($league): $e');
      rethrow;
    }
  }

  /// 리그 통계 가져오기
  Future<LeagueStats?> getLeagueStats(String league) async {
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      throw Exception('크롤링 서버에 연결할 수 없습니다.');
    }

    try {
      final encodedLeague = Uri.encodeComponent(league);
      final response = await http.get(
        Uri.parse('$serverUrl/stats/$encodedLeague'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return LeagueStats.fromJson(data['stats']);
        }
      }

      throw Exception('서버에서 리그 통계를 가져올 수 없습니다: ${response.statusCode}');
    } catch (e) {
      print('리그 통계 가져오기 실패 ($league): $e');
      rethrow;
    }
  }

  /// 새 크롤링 시작
  Future<bool> triggerCrawling() async {
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/crawl'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('크롤링 시작 실패: $e');
      return false;
    }
  }

  /// 크롤링 상태 확인
  Future<CrawlingStatus?> getCrawlingStatus() async {
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      throw Exception('크롤링 서버에 연결할 수 없습니다.');
    }

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/crawl/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CrawlingStatus.fromJson(data);
        }
      }

      throw Exception('서버에서 크롤링 상태를 가져올 수 없습니다: ${response.statusCode}');
    } catch (e) {
      print('크롤링 상태 확인 실패: $e');
      rethrow;
    }
  }

  /// 서버 연결 상태 확인
  Future<bool> checkServerConnection() async {
    try {
      final serverUrl = await _findWorkingServer();
      return serverUrl != null;
    } catch (e) {
      print('서버 연결 확인 실패: $e');
      return false;
    }
  }

  /// 연결 재설정 (캐시된 서버 URL 초기화)
  void resetConnection() {
    _workingServerUrl = null;
    print('서버 연결 캐시 초기화');
  }

  /// 2025년 시즌 정보 가져오기
  Future<Map<String, dynamic>?> getSeasonInfo() async {
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'season': data['season'] ?? '2025',
          'version': data['version'] ?? 'Unknown',
          'data_summary': data['data_summary'] ?? {},
          'timestamp': data['timestamp'],
          'server_url': serverUrl, // 연결된 서버 URL 정보 추가
        };
      }
    } catch (e) {
      print('시즌 정보 조회 실패: $e');
    }
    return null;
  }

  /// 순위표 가져오기
  Future<List<StandingRecord>> getStandings(String? league) async {
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      throw Exception('크롤링 서버에 연결할 수 없습니다.');
    }

    try {
      String url = '$serverUrl/standings';
      if (league != null) {
        url += '?league_name=${Uri.encodeComponent(league)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final standings = List<Map<String, dynamic>>.from(data['standings']);
          return standings
              .map((standing) => StandingRecord.fromJson(standing))
              .toList();
        }
      }

      throw Exception('서버에서 순위표를 가져올 수 없습니다: ${response.statusCode}');
    } catch (e) {
      print('순위표 가져오기 실패: $e');
      rethrow;
    }
  }

  /// 통합 검색
  Future<SearchResult> search(String query, {String category = 'all'}) async {
    final serverUrl = await _findWorkingServer();
    if (serverUrl == null) {
      throw Exception('크롤링 서버에 연결할 수 없습니다.');
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$serverUrl/search?q=${Uri.encodeComponent(query)}&category=$category'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return SearchResult.fromJson(data);
        }
      }

      throw Exception('검색 실패: ${response.statusCode}');
    } catch (e) {
      print('검색 실패: $e');
      rethrow;
    }
  }

  /// 네트워크 진단 정보 가져오기
  Future<Map<String, dynamic>> getNetworkDiagnostics() async {
    Map<String, dynamic> diagnostics = {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'servers_tested': [],
      'working_server': _workingServerUrl,
    };

    for (String serverUrl in _serverUrls) {
      Map<String, dynamic> serverTest = {
        'url': serverUrl,
        'reachable': false,
        'response_time': null,
        'error': null,
      };

      try {
        final stopwatch = Stopwatch()..start();
        final response = await http.get(
          Uri.parse('$serverUrl/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 3));
        stopwatch.stop();

        serverTest['response_time'] = stopwatch.elapsedMilliseconds;

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'healthy') {
            serverTest['reachable'] = true;
          }
        }
      } catch (e) {
        serverTest['error'] = e.toString();
      }

      diagnostics['servers_tested'].add(serverTest);
    }

    return diagnostics;
  }
}

/// 경기 기록 모델 (2025년 시즌 데이터 구조에 맞춤)
class MatchRecord {
  final String matchId;
  final String leagueName;
  final String division;
  final int level;
  final String season;
  final int round;
  final String matchDate;
  final String? matchTime;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String matchStatus;
  final String? venue;
  final int? attendance;
  final String? weather;
  final String? referee;

  MatchRecord({
    required this.matchId,
    required this.leagueName,
    required this.division,
    required this.level,
    required this.season,
    required this.round,
    required this.matchDate,
    this.matchTime,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.matchStatus,
    this.venue,
    this.attendance,
    this.weather,
    this.referee,
  });

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      matchId: json['match_id'] ?? '',
      leagueName: json['league_name'] ?? '',
      division: json['division'] ?? '',
      level: json['level'] ?? 0,
      season: json['season'] ?? '2025',
      round: json['round'] ?? 0,
      matchDate: json['match_date'] ?? '',
      matchTime: json['match_time'],
      homeTeam: json['home_team'] ?? '',
      awayTeam: json['away_team'] ?? '',
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      matchStatus: json['status'] ?? '예정',
      venue: json['venue'],
      attendance: json['attendance'],
      weather: json['weather'],
      referee: json['referee'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'league_name': leagueName,
      'division': division,
      'level': level,
      'season': season,
      'round': round,
      'match_date': matchDate,
      'match_time': matchTime,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'home_score': homeScore,
      'away_score': awayScore,
      'status': matchStatus,
      'venue': venue,
      'attendance': attendance,
      'weather': weather,
      'referee': referee,
    };
  }

  bool get isCompleted => matchStatus == '완료';

  String get scoreDisplay {
    if (isCompleted && homeScore != null && awayScore != null) {
      return '$homeScore:$awayScore';
    }
    return 'VS';
  }

  String get fullLeagueName => '$leagueName $division';
}

/// 순위표 데이터 모델
class StandingRecord {
  final String leagueName;
  final String division;
  final int position;
  final String teamName;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final List<String> form;

  StandingRecord({
    required this.leagueName,
    required this.division,
    required this.position,
    required this.teamName,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.form,
  });

  factory StandingRecord.fromJson(Map<String, dynamic> json) {
    return StandingRecord(
      leagueName: json['league_name'] ?? '',
      division: json['division'] ?? '',
      position: json['position'] ?? 0,
      teamName: json['team_name'] ?? '',
      matchesPlayed: json['matches_played'] ?? 0,
      wins: json['wins'] ?? 0,
      draws: json['draws'] ?? 0,
      losses: json['losses'] ?? 0,
      goalsFor: json['goals_for'] ?? 0,
      goalsAgainst: json['goals_against'] ?? 0,
      goalDifference: json['goal_difference'] ?? 0,
      points: json['points'] ?? 0,
      form: json['form'] is List
          ? List<String>.from(json['form'])
          : json['form'] is String
              ? json['form'].split(',')
              : [],
    );
  }
}

/// 리그 통계 데이터 모델
class LeagueStats {
  final String league;
  final String season;
  final int totalMatches;
  final int completedMatches;
  final int upcomingMatches;
  final int totalTeams;
  final Map<String, int> teamMatchCounts;

  LeagueStats({
    required this.league,
    required this.season,
    required this.totalMatches,
    required this.completedMatches,
    required this.upcomingMatches,
    required this.totalTeams,
    required this.teamMatchCounts,
  });

  factory LeagueStats.fromJson(Map<String, dynamic> json) {
    return LeagueStats(
      league: json['league'] ?? '',
      season: json['season'] ?? '2025',
      totalMatches: json['total_matches'] ?? 0,
      completedMatches: json['completed_matches'] ?? 0,
      upcomingMatches: json['upcoming_matches'] ?? 0,
      totalTeams: json['total_teams'] ?? 0,
      teamMatchCounts: Map<String, int>.from(json['team_match_counts'] ?? {}),
    );
  }
}

/// 크롤링 상태 데이터 모델
class CrawlingStatus {
  final bool success;
  final String status;
  final String season;
  final String lastCrawl;
  final Map<String, dynamic> dataSummary;

  CrawlingStatus({
    required this.success,
    required this.status,
    required this.season,
    required this.lastCrawl,
    required this.dataSummary,
  });

  factory CrawlingStatus.fromJson(Map<String, dynamic> json) {
    return CrawlingStatus(
      success: json['success'] ?? false,
      status: json['status'] ?? '',
      season: json['season'] ?? '2025',
      lastCrawl: json['last_crawl'] ?? '',
      dataSummary: Map<String, dynamic>.from(json['data_summary'] ?? {}),
    );
  }
}

/// 검색 결과 데이터 모델
class SearchResult {
  final bool success;
  final String query;
  final String category;
  final String season;
  final int totalResults;
  final Map<String, List<dynamic>> data;

  SearchResult({
    required this.success,
    required this.query,
    required this.category,
    required this.season,
    required this.totalResults,
    required this.data,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      success: json['success'] ?? false,
      query: json['query'] ?? '',
      category: json['category'] ?? '',
      season: json['season'] ?? '2025',
      totalResults: json['total_results'] ?? 0,
      data: Map<String, List<dynamic>>.from(json['data'] ?? {}),
    );
  }
}
