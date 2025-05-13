/// 앱 내 라우트 정의
/// - 중앙화된 라우트 상수
/// - 일관된 이름 패턴
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // 라우트 이름 상수

  // 에디터 라우트
  static const String home = '/';
  static const String editor = '/editor';
  static const String editorSettings = '/editor/settings';

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
