/// 축신 앱 내 라우트 정의
/// - 중앙화된 라우트 상수
/// - 일관된 이름 패턴
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // 라우트 이름 상수

  // 개발자 도구
  static const String debug = '/debug';

  // 인증 라우트
  static const String authGate = '/auth-gate';
  static const String opening = '/opening';
  static const String login = '/login';
  static const String profileSetup = '/profile-setup';
  static const String firebaseSetup = '/firebase-setup';

  // 메인 앱 라우트
  static const String home = '/';
  static const String main = '/main';
  static const String feed = '/feed';
  static const String myTeam = '/my-team';
  static const String records = '/records';
  static const String search = '/search';
  static const String profile = '/profile';

  // 템플릿 편집기 (기능 메뉴로 이동)
  static const String templateEditor = '/template-editor';
  static const String editorSettings = '/template-editor/settings';

  // 팀 관리
  static const String teams = '/teams';
  static const String teamDetail = '/teams/detail';
  static const String teamCreate = '/teams/create';

  // 미디어 관리
  static const String gallery = '/gallery';
  static const String mediaDetail = '/media/detail';

  // 설정
  static const String settings = '/settings';
  static const String themeSettings = '/settings/theme';
  static const String languageSettings = '/settings/language';

  // 파라미터화된 라우트 생성 헬퍼 함수

  /// 팀 상세 라우트 생성
  static String teamDetailRoute(String teamId) => '$teamDetail/$teamId';

  /// 미디어 상세 라우트 생성
  static String mediaDetailRoute(String mediaId) => '$mediaDetail/$mediaId';
}
