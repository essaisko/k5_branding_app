import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// 프로덕션 레벨 JoinKFA 네트워크 서비스
/// 실제 브라우저와 100% 동일한 요청 시뮬레이션
class JoinKFANetworkService {
  static const String _baseUrl = 'https://www.joinkfa.com';
  static const String _portalPath = '/portal/mat';

  // API 엔드포인트
  static const String _matchListEndpoint = '$_portalPath/getMatchList.do';
  static const String _matchSingleEndpoint =
      '$_portalPath/getMatchSingleList.do';

  late http.Client _httpClient;
  final Map<String, String> _sessionCookies = {};
  bool _isSessionValid = false;
  DateTime? _lastSessionUpdate;

  // 세션 유효시간 (30분)
  static const Duration _sessionTimeout = Duration(minutes: 30);

  JoinKFANetworkService() {
    _initializeClient();
  }

  /// HTTP 클라이언트 초기화
  void _initializeClient() {
    _httpClient = http.Client();
  }

  /// 실제 크롬 브라우저 헤더 생성 (네트워크탭 기반)
  Map<String, String> _getBrowserHeaders({
    bool isAjax = true,
    String? referer,
  }) {
    final headers = <String, String>{
      // 필수 브라우저 헤더 (실제 크롬과 동일)
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': isAjax
          ? 'application/json, text/javascript, */*; q=0.01'
          : 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Sec-Fetch-Dest': isAjax ? 'empty' : 'document',
      'Sec-Fetch-Mode': isAjax ? 'cors' : 'navigate',
      'Sec-Fetch-Site': 'same-origin',
      'Sec-Ch-Ua':
          '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
      'Sec-Ch-Ua-Mobile': '?0',
      'Sec-Ch-Ua-Platform': '"Windows"',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };

    // AJAX 요청시 추가 헤더
    if (isAjax) {
      headers['X-Requested-With'] = 'XMLHttpRequest';
      headers['Origin'] = _baseUrl;
    }

    // Referer 설정
    headers['Referer'] = referer ?? _baseUrl;

    // 세션 쿠키 추가
    if (_sessionCookies.isNotEmpty) {
      headers['Cookie'] =
          _sessionCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }

    return headers;
  }

  /// POST 요청용 헤더 (Content-Type 추가)
  Map<String, String> _getPostHeaders({String? referer}) {
    final headers = _getBrowserHeaders(isAjax: true, referer: referer);
    headers['Content-Type'] =
        'application/x-www-form-urlencoded; charset=UTF-8';
    return headers;
  }

  /// 세션 초기화 - 메인 페이지 접속으로 쿠키 획득
  Future<bool> initializeSession() async {
    try {
      debugPrint('🔐 [JoinKFA] 세션 초기화 시작...');

      final response = await _httpClient
          .get(
            Uri.parse(_baseUrl),
            headers: _getBrowserHeaders(isAjax: false),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _extractCookiesFromResponse(response);
        _isSessionValid = true;
        _lastSessionUpdate = DateTime.now();

        debugPrint(
            '✅ [JoinKFA] 세션 초기화 성공 - 쿠키: ${_sessionCookies.keys.join(", ")}');
        return true;
      } else {
        debugPrint('❌ [JoinKFA] 세션 초기화 실패 - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [JoinKFA] 세션 초기화 오류: $e');
      return false;
    }
  }

  /// HTTP 응답에서 쿠키 추출
  void _extractCookiesFromResponse(http.Response response) {
    final setCookieHeader = response.headers['set-cookie'];
    if (setCookieHeader != null) {
      // 여러 쿠키가 콤마로 구분되어 올 수 있음
      final cookies = setCookieHeader.split(',');

      for (String cookie in cookies) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) {
          final name = parts[0].trim();
          final value = parts[1].trim();

          // 중요한 세션 쿠키만 저장
          if (name.isNotEmpty && value.isNotEmpty) {
            _sessionCookies[name] = value;
            debugPrint('🍪 [JoinKFA] 쿠키 저장: $name');
          }
        }
      }
    }
  }

  /// 세션 유효성 검사
  bool _isSessionExpired() {
    if (!_isSessionValid || _lastSessionUpdate == null) return true;

    return DateTime.now().difference(_lastSessionUpdate!) > _sessionTimeout;
  }

  /// 세션 갱신 (필요시)
  Future<bool> _refreshSessionIfNeeded() async {
    if (_isSessionExpired()) {
      debugPrint('🔄 [JoinKFA] 세션 만료, 갱신 중...');
      return await initializeSession();
    }
    return true;
  }

  /// 경기 목록 요청 (getMatchList.do)
  Future<Map<String, dynamic>> getMatchList({
    required String areaCode, // BS(부산), KN(경남)
    required String leagueCode, // 25(K5), 24(K6), 23(K7)
    required String year,
  }) async {
    await _refreshSessionIfNeeded();

    final payload = {
      'v_AREACODE': areaCode,
      'v_MGC_IDX': leagueCode,
      'v_YEAR': year,
    };

    return await _makePostRequest(
      endpoint: _matchListEndpoint,
      payload: payload,
      requestName: 'getMatchList',
    );
  }

  /// 단일 경기 목록 요청 (getMatchSingleList.do)
  Future<Map<String, dynamic>> getMatchSingleList({
    required String matchIdx,
    required String yearMonth, // YYYY-MM 형식
  }) async {
    await _refreshSessionIfNeeded();

    final payload = {
      'v_MATCH_IDX': matchIdx,
      'v_YEAR_MONTH': yearMonth,
    };

    return await _makePostRequest(
      endpoint: _matchSingleEndpoint,
      payload: payload,
      requestName: 'getMatchSingleList',
    );
  }

  /// POST 요청 실행 (재시도 및 오류 처리 포함)
  Future<Map<String, dynamic>> _makePostRequest({
    required String endpoint,
    required Map<String, String> payload,
    required String requestName,
    int maxRetries = 3,
  }) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('📡 [JoinKFA] $requestName 요청 (시도 $attempt/$maxRetries)');

        final body = payload.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');

        final response = await _httpClient
            .post(
              Uri.parse('$_baseUrl$endpoint'),
              headers: _getPostHeaders(referer: _baseUrl),
              body: body,
            )
            .timeout(const Duration(seconds: 30));

        // 새로운 쿠키가 있으면 업데이트
        _extractCookiesFromResponse(response);

        // 응답 처리
        return await _handleResponse(
            response, requestName, attempt, maxRetries);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        debugPrint('❌ [JoinKFA] $requestName 시도 $attempt 실패: $e');

        if (attempt < maxRetries) {
          // 지수 백오프로 재시도 딜레이
          final delay = Duration(seconds: attempt * 2);
          debugPrint('⏳ [JoinKFA] ${delay.inSeconds}초 후 재시도...');
          await Future.delayed(delay);

          // 세션 재초기화 시도
          if (attempt == 2) {
            debugPrint('🔄 [JoinKFA] 세션 재초기화 시도...');
            await initializeSession();
          }
        }
      }
    }

    throw lastException ?? Exception('Unknown error occurred');
  }

  /// HTTP 응답 처리 (JSON 검증 포함)
  Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
    String requestName,
    int attempt,
    int maxRetries,
  ) async {
    debugPrint('📥 [JoinKFA] $requestName 응답: ${response.statusCode}');

    // 성공 응답
    if (response.statusCode == 200) {
      try {
        // JSON 응답인지 확인
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.toLowerCase().contains('application/json') &&
            !contentType.toLowerCase().contains('text/json')) {
          throw Exception('Expected JSON response, got: $contentType');
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [JoinKFA] $requestName 성공');
        return data;
      } catch (e) {
        debugPrint('❌ [JoinKFA] JSON 파싱 실패: $e');
        debugPrint(
            '📄 [JoinKFA] 응답 내용 (첫 500자): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        throw Exception('Invalid JSON response: $e');
      }
    }

    // 302 리다이렉트 처리
    if (response.statusCode == 302 || response.statusCode == 301) {
      debugPrint('🔄 [JoinKFA] 리다이렉트 감지 - 세션 재초기화');

      if (attempt < maxRetries) {
        // 세션 무효화 후 재초기화
        _isSessionValid = false;
        _sessionCookies.clear();

        final sessionResult = await initializeSession();
        if (!sessionResult) {
          throw Exception('Session reinitialization failed after redirect');
        }

        throw Exception('Redirect detected - retrying with new session');
      } else {
        throw Exception('Max retries reached after redirect');
      }
    }

    // 기타 HTTP 오류
    throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
  }

  /// 세션 상태 확인
  bool get isSessionValid => _isSessionValid && !_isSessionExpired();

  /// 세션 정보 반환
  Map<String, String> get sessionInfo => {
        'isValid': _isSessionValid.toString(),
        'lastUpdate': _lastSessionUpdate?.toIso8601String() ?? 'never',
        'cookieCount': _sessionCookies.length.toString(),
        'cookies': _sessionCookies.keys.join(', '),
      };

  /// 리소스 정리
  void dispose() {
    _httpClient.close();
    _sessionCookies.clear();
    _isSessionValid = false;
  }
}

/// 네트워크 응답 예외
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  NetworkException(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() =>
      'NetworkException: $message (${statusCode ?? 'unknown'}) at $endpoint';
}

/// 세션 예외
class SessionException implements Exception {
  final String message;

  SessionException(this.message);

  @override
  String toString() => 'SessionException: $message';
}
