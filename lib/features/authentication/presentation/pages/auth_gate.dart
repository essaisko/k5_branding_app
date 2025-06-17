import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chukshin_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:chukshin_app/features/authentication/presentation/pages/opening_page.dart';
import 'package:chukshin_app/features/authentication/presentation/pages/profile_setup_page.dart';
import 'package:chukshin_app/presentation/pages/main_page.dart';

/// 인증 상태에 따라 적절한 화면을 보여주는 게이트 위젯
///
/// - 로그인되지 않은 사용자: Opening 페이지
/// - 로그인된 사용자 (프로필 미완성): 추가정보 입력 페이지
/// - 로그인된 사용자 (프로필 완성): 메인 앱 (매치 에디터)
/// - 로딩 중: 로딩 화면
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 로딩 중일 때
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('인증 상태를 확인하고 있습니다...'),
            ],
          ),
        ),
      );
    }

    // 로그인된 사용자
    if (authState.isAuthenticated) {
      final user = authState.user;

      // 프로필 설정이 완료되지 않은 경우 추가정보 입력 페이지로 이동
      if (user == null || !user.isProfileSetupComplete) {
        return const ProfileSetupPage();
      }

      // 프로필 설정이 완료된 경우 메인 앱으로 이동
      return const MainPage();
    }

    // 로그인되지 않은 사용자
    return const OpeningPage();
  }
}
