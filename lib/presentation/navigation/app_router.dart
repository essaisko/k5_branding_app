import 'package:flutter/material.dart';
import 'package:chukshin_app/features/match_editor/presentation/pages/match_editor_page.dart';
import 'package:chukshin_app/features/authentication/presentation/pages/auth_gate.dart';
import 'package:chukshin_app/features/authentication/presentation/pages/opening_page.dart';
import 'package:chukshin_app/features/authentication/presentation/pages/profile_setup_page.dart';
import 'package:chukshin_app/features/authentication/presentation/pages/firebase_setup_guide.dart';
import 'package:chukshin_app/features/authentication/presentation/pages/debug_page.dart';
import 'package:chukshin_app/presentation/pages/main_page.dart';
import 'package:chukshin_app/presentation/navigation/routes.dart';

/// 축신 앱 라우터 설정
class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  /// 중앙화된 라우트 정의
  static Map<String, WidgetBuilder> get routes {
    return {
      // 개발자 도구
      AppRoutes.debug: (context) => const DebugPage(),

      // 인증 관련 라우트
      AppRoutes.authGate: (context) => const AuthGate(),
      AppRoutes.opening: (context) => const OpeningPage(),
      // 회원가입 페이지 제거 - 휴대전화번호 인증에서는 프로필 설정으로 대체
      AppRoutes.profileSetup: (context) => const ProfileSetupPage(),
      AppRoutes.firebaseSetup: (context) => const FirebaseSetupGuide(),

      // 메인 앱 라우트 - 바텀 네비게이션이 있는 메인 페이지
      AppRoutes.home: (context) => const MainPage(),
      AppRoutes.main: (context) => const MainPage(),

      // 템플릿 편집기 (기능 메뉴로 이동)
      AppRoutes.templateEditor: (context) => const MatchEditorPage(),

      // Add other routes as they are implemented
    };
  }

  /// 알 수 없는 라우트 처리
  static Route<dynamic> unknownRouteHandler(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('페이지를 찾을 수 없습니다')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                '요청한 페이지를 찾을 수 없습니다',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text('경로: ${settings.name}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.home),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 파라미터 라우트 처리
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Extract route path and parameters
    final uri = Uri.parse(settings.name ?? '');
    final path = uri.path;

    // Match parametrized routes
    if (path.startsWith('${AppRoutes.teamDetail}/')) {
      final teamId = path.split('/').last;
      // TODO: Implement team detail page
      return null;
    }

    if (path.startsWith('${AppRoutes.mediaDetail}/')) {
      final mediaId = path.split('/').last;
      // TODO: Implement media detail page
      return null;
    }

    // Return null to fall back to the routes map
    return null;
  }

  /// 네비게이션 헬퍼 함수들

  /// 지정된 라우트로 이동
  static Future<T?> navigateTo<T>(BuildContext context, String routeName) {
    return Navigator.of(context).pushNamed<T>(routeName);
  }

  /// 현재 라우트를 새 라우트로 교체
  static Future<T?> replaceWith<T>(BuildContext context, String routeName) {
    return Navigator.of(context).pushReplacementNamed<T, dynamic>(routeName);
  }

  /// 이전 화면으로 돌아가기
  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// 네비게이션 스택을 비우고 라우트로 이동
  static Future<T?> clearStackAndNavigateTo<T>(
    BuildContext context,
    String routeName,
  ) {
    return Navigator.of(
      context,
    ).pushNamedAndRemoveUntil<T>(routeName, (route) => false);
  }
}
