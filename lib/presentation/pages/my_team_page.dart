import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chukshin_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:chukshin_app/presentation/pages/team_community_page.dart';
import 'package:chukshin_app/presentation/navigation/navigation_state.dart';
import 'package:chukshin_app/features/team/providers/team_provider.dart';

/// 나의 팀 페이지
class MyTeamPage extends ConsumerStatefulWidget {
  const MyTeamPage({super.key});

  @override
  ConsumerState<MyTeamPage> createState() => _MyTeamPageState();
}

class _MyTeamPageState extends ConsumerState<MyTeamPage> {
  bool _isUploadingBackground = false;

  // 배경 이미지 업로드
  Future<void> _uploadBackgroundImage(String teamName) async {
    setState(() {
      _isUploadingBackground = true;
    });

    try {
      final imageUrl = await ref
          .read(teamBackgroundProvider.notifier)
          .pickAndUploadImage(teamName);

      if (imageUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('배경 이미지가 설정되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('배경 이미지 설정 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingBackground = false;
      });
    }
  }

  // 배경 이미지 제거
  Future<void> _removeBackgroundImage(String teamName) async {
    try {
      await ref
          .read(teamBackgroundProvider.notifier)
          .removeBackgroundImage(teamName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('배경 이미지가 제거되었습니다.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('배경 이미지 제거 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 배경 이미지 설정 메뉴 표시
  void _showBackgroundImageMenu(String teamName) {
    final backgroundImages = ref.read(teamBackgroundProvider);
    final hasBackground = backgroundImages[teamName] != null;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '배경 이미지 설정',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _uploadBackgroundImage(teamName);
              },
            ),
            if (hasBackground)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('배경 이미지 제거'),
                onTap: () {
                  Navigator.pop(context);
                  _removeBackgroundImage(teamName);
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('취소'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final backgroundImages = ref.watch(teamBackgroundProvider);

    // 팀별 색상 매핑
    final teamColors = {
      '한마음FC': Colors.red,
      '수우FC': Colors.blue,
      '한FC': Colors.green,
      '기타': Colors.grey,
    };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '나의 팀',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: user == null || user.affiliatedTeams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '소속 팀이 없습니다',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '프로필 설정에서 소속 팀을 추가해주세요.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 프로필 설정 페이지로 이동
                    },
                    child: const Text('프로필 설정하기'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '소속 팀 (${user.affiliatedTeams.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView.builder(
                      itemCount: user.affiliatedTeams.length,
                      itemBuilder: (context, index) {
                        final teamName = user.affiliatedTeams[index];
                        final teamColor = teamColors[teamName] ?? Colors.grey;
                        final backgroundImageUrl = backgroundImages[teamName];

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                // 새로운 네비게이션 시스템 사용
                                ref
                                    .read(navigationProvider.notifier)
                                    .pushOverlay(
                                      TeamCommunityPage(
                                        teamName: teamName,
                                        teamColor: teamColor,
                                      ),
                                      showBottomNav: true,
                                    );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: backgroundImageUrl == null
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            teamColor.withOpacity(0.8),
                                            teamColor,
                                          ],
                                        )
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    // 배경 이미지 또는 기본 배경
                                    if (backgroundImageUrl != null)
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Image.network(
                                            backgroundImageUrl,
                                            fit: BoxFit.cover,
                                            colorBlendMode: BlendMode.darken,
                                            color: Colors.black.withOpacity(
                                                0.2), // 약간의 어두운 필터만 적용
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      teamColor
                                                          .withOpacity(0.8),
                                                      teamColor,
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                    // 컨텐츠 영역에만 적용되는 부분적 오버레이
                                    if (backgroundImageUrl != null)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        height: 200, // 하단 컨텐츠 영역만 오버레이
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(20),
                                              bottomRight: Radius.circular(20),
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.7),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                    // 기본 배경 패턴 (배경 이미지가 없을 때)
                                    if (backgroundImageUrl == null) ...[
                                      Positioned(
                                        top: -50,
                                        right: -50,
                                        child: Container(
                                          width: 150,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -30,
                                        left: -30,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.white.withOpacity(0.05),
                                          ),
                                        ),
                                      ),
                                    ],

                                    // 배경 설정 버튼
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showBackgroundImageMenu(teamName),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: _isUploadingBackground
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.photo_camera,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                        ),
                                      ),
                                    ),

                                    // 메인 콘텐츠 - 하단에 배치하여 배경 이미지가 더 잘 보이도록
                                    Positioned(
                                      bottom: 24,
                                      left: 24,
                                      right: 24,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 팀 로고 - 크기 축소 및 투명도 조정
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.sports_soccer,
                                              size: 40,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // 팀 이름 - 더 강한 그림자 효과
                                          Text(
                                            teamName,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 2),
                                                  blurRadius: 4,
                                                  color: Colors.black,
                                                ),
                                                Shadow(
                                                  offset: Offset(2, 2),
                                                  blurRadius: 8,
                                                  color: Colors.black54,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          // 설명 - 배경 강화
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Text(
                                              '팀 커뮤니티',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // 액션 버튼 - 디자인 개선
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.arrow_forward,
                                                  color: teamColor,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '입장하기',
                                                  style: TextStyle(
                                                    color: teamColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // 페이지 인디케이터
                  if (user.affiliatedTeams.length > 1) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        user.affiliatedTeams.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ],
                  // 팀 추가/변경 버튼
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: 팀 변경/추가 기능
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('팀 설정 기능은 준비 중입니다.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('팀 설정'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
