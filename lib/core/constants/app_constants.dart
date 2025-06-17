/// 앱 전체에서 사용하는 상수들
/// 매직 넘버와 하드코딩된 값들을 중앙화하여 관리

class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// 앱 정보
  static const String appName = 'ChukShin App';
  static const String appVersion = '1.0.0';

  /// 이미지 설정
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int profileImageSize = 300;
  static const int imageQuality = 80;

  /// 팀 관련
  static const List<String> defaultTeams = [
    '한마음FC',
    '수우FC',
    '한FC',
  ];

  /// Firebase Storage 경로
  static const String profileImagesPath = 'profile_images';
  static const String teamImagesPath = 'team_images';

  /// 포지션 목록
  static const List<String> positions = [
    '골키퍼',
    '풀백',
    '센터백',
    '윙백',
    '수비형 미드필더',
    '중앙 미드필더',
    '공격형 미드필더',
    '윙어',
    '스트라이커',
  ];

  /// 애니메이션 시간
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  /// 페이징
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// 타임아웃
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);

  /// UI 관련
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;

  /// 에러 메시지
  static const String networkErrorMessage = '네트워크 연결을 확인해주세요.';
  static const String unknownErrorMessage = '알 수 없는 오류가 발생했습니다.';
  static const String authErrorMessage = '인증에 실패했습니다.';
}

/// 팀별 색상 매핑
class TeamColors {
  TeamColors._();

  static const Map<String, int> teamColorCodes = {
    '한마음FC': 0xFFE74C3C, // Red
    '수우FC': 0xFF3498DB, // Blue
    '한FC': 0xFF27AE60, // Green
  };

  static const Map<String, String> teamLogos = {
    '한마음FC': 'assets/images/default_crest.png',
    '수우FC': 'assets/images/default_crest.png',
    '한FC': 'assets/images/default_crest.png',
  };
}
