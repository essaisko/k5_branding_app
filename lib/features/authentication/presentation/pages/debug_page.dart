import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chukshin_app/core/theme/app_theme.dart';
import 'package:chukshin_app/core/theme/app_colors.dart';
import 'package:chukshin_app/presentation/navigation/routes.dart';
import 'package:chukshin_app/features/authentication/presentation/providers/auth_provider.dart';

/// 디버깅용 페이지
///
/// 개발 중 모든 페이지로 쉽게 이동할 수 있는 개발자 전용 페이지
/// - 모든 주요 페이지로의 네비게이션 버튼
/// - 현재 인증 상태 표시
/// - Firebase 연결 상태 확인
/// - 빠른 로그아웃/로그인 기능
class DebugPage extends ConsumerWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐛 축신 디버깅 페이지'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 앱 상태 새로고침
              ref.read(authProvider.notifier).refreshUser();
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.white,
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재 상태 정보
              _buildStatusCard(context, theme, authState),

              const SizedBox(height: 20),

              // 인증 관련 페이지들
              _buildSectionCard(
                context,
                theme,
                '🔐 인증 페이지',
                [
                  _DebugButton(
                    title: 'AuthGate (인증 게이트)',
                    subtitle: '인증 상태에 따른 자동 라우팅',
                    icon: Icons.security,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.authGate),
                  ),
                  _DebugButton(
                    title: 'Opening Page (시작 페이지)',
                    subtitle: 'K5 League 브랜딩 페이지',
                    icon: Icons.home,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.opening),
                  ),
                  _DebugButton(
                    title: 'Login Page (휴대전화 로그인)',
                    subtitle: '휴대전화번호 + SMS 인증',
                    icon: Icons.login,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                  ),
                  _DebugButton(
                    title: 'Profile Setup (프로필 설정)',
                    subtitle: '휴대전화 인증 후 추가 정보 입력',
                    icon: Icons.edit,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.profileSetup),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 메인 기능 페이지들
              _buildSectionCard(
                context,
                theme,
                '⚽ 메인 기능',
                [
                  _DebugButton(
                    title: 'Main Page (메인 페이지)',
                    subtitle: '홈 피드 및 바텀 네비게이션',
                    icon: Icons.home,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.main),
                  ),
                  _DebugButton(
                    title: 'Match Editor (매치 에디터)',
                    subtitle: '경기 정보 편집 및 브랜딩',
                    icon: Icons.edit_note,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.home),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 개발자 도구
              _buildSectionCard(
                context,
                theme,
                '🛠️ 개발자 도구',
                [
                  _DebugButton(
                    title: 'Firebase Setup Guide',
                    subtitle: 'Firebase 연결 상태 확인',
                    icon: Icons.cloud,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.firebaseSetup),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 빠른 액션들
              _buildQuickActions(context, theme, ref, authState),

              const SizedBox(height: 20),

              // 테스트 데이터
              _buildTestDataSection(context, theme, ref),

              const SizedBox(height: 40),

              // 경고 메시지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '⚠️ 이 페이지는 개발용입니다.\n출시 전에 반드시 제거하거나 숨겨야 합니다.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context, ThemeData theme, AuthState authState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 현재 상태',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
                '인증 상태', authState.isAuthenticated ? '✅ 로그인됨' : '❌ 로그아웃됨'),
            _buildStatusRow('사용자 이름', authState.user?.name ?? '없음'),
            _buildStatusRow('휴대전화번호', authState.user?.phoneNumber ?? '없음'),
            _buildStatusRow('사용자 이메일', authState.user?.email ?? '없음'),
            _buildStatusRow('로딩 상태', authState.isLoading ? '🔄 로딩 중' : '✅ 완료'),
            _buildStatusRow('SMS 인증 진행',
                authState.isVerificationInProgress ? '📱 진행 중' : '⏸️ 대기'),
            if (authState.error != null)
              _buildStatusRow('에러', '❌ ${authState.error}'),
            if (authState.user?.birthDate != null)
              _buildStatusRow('생년월일',
                  '${authState.user!.birthDate.year}년 ${authState.user!.birthDate.month}월 ${authState.user!.birthDate.day}일'),
            if (authState.user?.residenceArea != null)
              _buildStatusRow('거주지역', authState.user!.residenceArea!),
            if (authState.user?.affiliatedTeams.isNotEmpty == true)
              _buildStatusRow(
                  '소속팀', authState.user!.affiliatedTeams.join(', ')),
            if (authState.user?.position != null)
              _buildStatusRow('포지션', authState.user!.position!),
            _buildStatusRow('휴대전화 인증',
                authState.user?.isPhoneVerified == true ? '✅ 인증됨' : '❌ 미인증'),
            _buildStatusRow(
                '프로필 완료',
                authState.user?.isProfileSetupComplete == true
                    ? '✅ 완료'
                    : '❌ 미완료'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, ThemeData theme, String title,
      List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme,
      WidgetRef ref, AuthState authState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ 빠른 액션',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: authState.isAuthenticated
                        ? () async {
                            await ref.read(authProvider.notifier).logout();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('로그아웃되었습니다')),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.logout),
                    label: const Text('로그아웃'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(authProvider.notifier).clearError();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('에러 상태가 클리어되었습니다')),
                      );
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('에러 클리어'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestDataSection(
      BuildContext context, ThemeData theme, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 테스트 데이터',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 테스트 인증 코드 전송
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // 테스트용 휴대전화번호로 인증 코드 전송
                        await ref
                            .read(authProvider.notifier)
                            .sendVerificationCode('010-1234-5678');

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '테스트 번호로 인증 코드가 전송되었습니다!\n번호: 010-1234-5678'),
                            duration: Duration(seconds: 5),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('테스트 인증 코드 전송 실패: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.sms),
                    label: const Text('테스트 인증 코드 전송'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // 테스트 인증 코드로 로그인 시도
                        final isNewUser = await ref
                            .read(authProvider.notifier)
                            .verifyCodeAndSignIn('123456');

                        if (isNewUser) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('새 사용자로 로그인됨! 추가 정보를 입력하세요.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('기존 사용자로 로그인됨!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('테스트 로그인 실패: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('테스트 로그인 (123456)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 테스트 사용자 프로필 완성
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ref.read(authProvider.notifier).completeSignup(
                        name: '테스트 사용자',
                        birthDate: DateTime(1995, 5, 15),
                        residenceArea: '서울 강남구 역삼동',
                        affiliatedTeams: ['한마음FC', '수우FC'],
                        position: '미드필더',
                      );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('테스트 사용자 프로필이 완성되었습니다!\n'
                          '이름: 테스트 사용자\n'
                          '생년월일: 1995년 5월 15일\n'
                          '거주지역: 서울 강남구 역삼동\n'
                          '소속팀: 한마음FC, 수우FC\n'
                          '포지션: 미드필더'),
                      duration: Duration(seconds: 5),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('테스트 사용자 생성 실패: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('테스트 사용자 프로필 완성'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // 앱 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 앱 정보',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('앱 이름', 'K5 Branding App'),
                  _buildInfoRow('버전', '1.0.0+1 (개발)'),
                  _buildInfoRow('인증 방식', '휴대전화번호 SMS 인증'),
                  _buildInfoRow('Flutter 버전', '3.x.x'),
                  _buildInfoRow('Firebase 프로젝트', 'footballbranding-9d2f8'),
                  _buildInfoRow('빌드 모드', 'Debug'),
                  _buildInfoRow('지원 팀', '한마음FC, 한FC, 수우FC'),
                  _buildInfoRow('지원 포지션', '골키퍼, 수비수, 미드필더, 공격수'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DebugButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
