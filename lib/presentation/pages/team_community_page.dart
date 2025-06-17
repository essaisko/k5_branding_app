import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chukshin_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:chukshin_app/features/team/providers/team_provider.dart';
import 'package:chukshin_app/core/constants/app_constants.dart';
import 'package:chukshin_app/domain/entities/post.dart';
import 'package:chukshin_app/features/common/providers/post_provider.dart';
import 'package:chukshin_app/features/common/pages/create_post_page.dart';
import 'package:chukshin_app/features/common/pages/post_detail_page.dart';
import 'package:chukshin_app/presentation/navigation/navigation_state.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 팀별 커뮤니티 페이지
/// 각 팀의 소식, 일정, 멤버 소통 공간
class TeamCommunityPage extends ConsumerStatefulWidget {
  final String teamName;
  final Color teamColor;

  const TeamCommunityPage({
    super.key,
    required this.teamName,
    required this.teamColor,
  });

  @override
  ConsumerState<TeamCommunityPage> createState() => _TeamCommunityPageState();
}

class _TeamCommunityPageState extends ConsumerState<TeamCommunityPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditingHeaderImage = false;

  // 팀별 색상 매핑 (AppConstants 사용)
  Map<String, Color> get teamColors => {
        for (var entry in TeamColors.teamColorCodes.entries)
          entry.key: Color(entry.value),
        '기타': Colors.grey,
      };

  // 팀별 로고 매핑 (AppConstants 사용)
  Map<String, String> get teamLogos => {
        ...TeamColors.teamLogos,
        '기타': 'assets/images/default_crest.png',
      };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 탭 변경 리스너 추가
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // 탭이 변경될 때 네비게이션 상태에 저장
        ref
            .read(navigationProvider.notifier)
            .setTeamCommunityTabIndex(_tabController.index);
      }
    });

    // 저장된 탭 인덱스가 있으면 복원
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedTabIndex = ref.read(navigationProvider).teamCommunityTabIndex;
      if (savedTabIndex != null && savedTabIndex != _tabController.index) {
        _tabController.animateTo(savedTabIndex);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamColor = widget.teamColor;
    final teamLogo =
        teamLogos[widget.teamName] ?? 'assets/images/default_crest.png';

    // 팀 정보 가져오기
    final team = ref.watch(teamByNameProvider(widget.teamName));
    final teamHeaderImage =
        team != null ? ref.watch(teamHeaderImageProvider(team.id)) : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => ref.read(navigationProvider.notifier).popOverlay(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: teamColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  teamLogo,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.teamName} 커뮤니티',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // TODO: 팀 내 검색 기능
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              _showTeamMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 팀 헤더 섹션
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  image: teamHeaderImage != null
                      ? DecorationImage(
                          image: FileImage(teamHeaderImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: teamHeaderImage == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            teamColor,
                            teamColor.withOpacity(0.7),
                          ],
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 팀 로고와 이름
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.asset(
                                    teamLogo,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      Icons.sports_soccer,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.teamName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '멤버 ${_getTeamMemberCount(widget.teamName)}명',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
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
              // 관리자 전용 편집 버튼
              if (isAdmin)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _isEditingHeaderImage
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _cancelHeaderImageEdit,
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (teamHeaderImage != null)
                              IconButton(
                                onPressed: _saveHeaderImage,
                                icon: const Icon(Icons.check),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        )
                      : IconButton(
                          onPressed: _toggleHeaderImageEdit,
                          icon: const Icon(Icons.edit),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ),
              // 편집 모드일 때 이미지 선택 버튼
              if (_isEditingHeaderImage)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _pickHeaderImage,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('대문 사진 선택'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teamColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // 탭 바
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: teamColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: teamColor,
              tabs: const [
                Tab(text: '갤러리'),
                Tab(text: '커뮤니티'),
                Tab(text: '일정'),
                Tab(text: '멤버'),
              ],
            ),
          ),
          // 탭 바 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGalleryTab(teamColor),
                _buildNewsTab(teamColor),
                _buildScheduleTab(teamColor),
                _buildMembersTab(teamColor),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 현재 활성화된 탭에 따라 자동으로 카테고리 결정
          PostCategory category;
          switch (_tabController.index) {
            case 0:
              category = PostCategory.gallery;
              break;
            case 1:
              category = PostCategory.community;
              break;
            case 2:
              category = PostCategory.schedule;
              break;
            default:
              category = PostCategory.community;
              break;
          }

          // 직접 게시글 작성 페이지로 이동
          _navigateToCreatePost(category, teamColor);
        },
        backgroundColor: teamColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNewsTab(Color teamColor) {
    final communityPosts = ref.watch(teamCategoryPostsProvider((
      teamId: widget.teamName,
      category: PostCategory.community,
    )));

    if (communityPosts.isEmpty) {
      return _buildEmptyState(
        '커뮤니티 글이 없습니다',
        '첫 번째 글을 작성해보세요!',
        Icons.chat_bubble_outline,
        teamColor,
        PostCategory.community,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: communityPosts.length,
      itemBuilder: (context, index) {
        final post = communityPosts[index];
        return _buildPostCard(post, teamColor);
      },
    );
  }

  Widget _buildScheduleTab(Color teamColor) {
    final schedulePosts = ref.watch(teamCategoryPostsProvider((
      teamId: widget.teamName,
      category: PostCategory.schedule,
    )));

    if (schedulePosts.isEmpty) {
      return _buildEmptyState(
        '등록된 일정이 없습니다',
        '첫 번째 일정을 등록해보세요!',
        Icons.event_note_outlined,
        teamColor,
        PostCategory.schedule,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedulePosts.length,
      itemBuilder: (context, index) {
        final post = schedulePosts[index];
        return _buildScheduleCard(post, teamColor);
      },
    );
  }

  Widget _buildScheduleCard(Post post, Color teamColor) {
    return GestureDetector(
      onTap: () {
        // 게시글 상세 페이지로 이동
        ref.read(navigationProvider.notifier).pushFullScreen(
              PostDetailPage(
                post: post,
                teamColor: teamColor,
                teamName: widget.teamName,
              ),
            );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 날짜/시간 표시
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${post.createdAt.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: teamColor,
                      ),
                    ),
                    Text(
                      '${post.createdAt.month}월',
                      style: TextStyle(
                        fontSize: 10,
                        color: teamColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 일정 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.authorName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.createdAt.hour.toString().padLeft(2, '0')}:${post.createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 상태 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event,
                  color: teamColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 기존 _buildScheduleTab 메서드의 나머지 부분은 제거하고 위의 새로운 구현을 사용
  Widget _buildScheduleTabOld(Color teamColor) {
    // 임시 일정 데이터 (참고용으로 남겨둠)
    final schedules = [
      {
        'date': '12월 15일 (화)',
        'time': '19:00',
        'event': '정기 훈련',
        'location': '잠실종합운동장',
        'type': 'training',
      },
      {
        'date': '12월 20일 (일)',
        'time': '14:00',
        'event': '친선경기 vs 수우FC',
        'location': '서울월드컵경기장',
        'type': 'match',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final isMatch = schedule['type'] == 'match';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isMatch ? teamColor : teamColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isMatch ? Icons.sports_soccer : Icons.fitness_center,
                color: isMatch ? Colors.white : teamColor,
              ),
            ),
            title: Text(
              schedule['event'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${schedule['date']} ${schedule['time']}'),
                Text(schedule['location'] as String),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
            onTap: () {
              // TODO: 일정 상세 보기
            },
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(Color teamColor) {
    // 임시 멤버 데이터
    final members = [
      {
        'name': '김철수',
        'position': '공격수',
        'joinDate': '2023.01',
        'status': 'active',
      },
      {
        'name': '이영희',
        'position': '미드필더',
        'joinDate': '2023.03',
        'status': 'active',
      },
      {
        'name': '박민수',
        'position': '수비수',
        'joinDate': '2023.06',
        'status': 'inactive',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isActive = member['status'] == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: teamColor,
              child: Text(
                (member['name'] as String)[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  member['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isActive ? '활동중' : '비활동',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('포지션: ${member['position']}'),
                Text('가입일: ${member['joinDate']}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                // TODO: 개인 메시지 기능
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGalleryTab(Color teamColor) {
    final galleryPosts = ref.watch(teamCategoryPostsProvider((
      teamId: widget.teamName,
      category: PostCategory.gallery,
    )));

    if (galleryPosts.isEmpty) {
      return _buildEmptyState(
        '갤러리가 비어있습니다',
        '첫 번째 사진을 업로드해보세요!',
        Icons.photo_library_outlined,
        teamColor,
        PostCategory.gallery,
      );
    }

    // 원본 비율 유지를 위해 ListView로 변경
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: galleryPosts.length,
      itemBuilder: (context, index) {
        final post = galleryPosts[index];
        final firstImage = post.images.isNotEmpty ? post.images.first : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () {
              // 게시글 상세 페이지로 이동
              ref.read(navigationProvider.notifier).pushFullScreen(
                    PostDetailPage(
                      post: post,
                      teamColor: teamColor,
                      teamName: widget.teamName,
                    ),
                  );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이미지 영역 (원본 비율 유지)
                  if (firstImage != null)
                    Stack(
                      children: [
                        Image.network(
                          firstImage,
                          width: double.infinity,
                          fit: BoxFit.fitWidth, // 원본 비율 유지하면서 너비에 맞춤
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: double.infinity,
                            height: 200,
                            color: teamColor.withOpacity(0.1),
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: teamColor,
                            ),
                          ),
                        ),

                        // 여러 이미지 표시 아이콘
                        if (post.images.length > 1)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.collections,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: teamColor.withOpacity(0.1),
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: teamColor,
                      ),
                    ),

                  // 게시글 정보 영역
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (post.content.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            post.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.authorName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.favorite,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likes}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.comment,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.comments}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTeamMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('팀 정보'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 팀 정보 페이지
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('팀 설정'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 팀 설정 페이지
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('팀 나가기'),
              onTap: () {
                Navigator.pop(context);
                _showLeaveTeamDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context, Color teamColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              '새 글 작성',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: teamColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '어떤 종류의 글을 작성하시겠습니까?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // 카테고리 선택 버튼들
            Row(
              children: [
                Expanded(
                  child: _buildCategoryButton(
                    context,
                    '갤러리',
                    Icons.photo_library,
                    PostCategory.gallery,
                    teamColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryButton(
                    context,
                    '커뮤니티',
                    Icons.chat_bubble,
                    PostCategory.community,
                    teamColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCategoryButton(
                    context,
                    '일정',
                    Icons.event,
                    PostCategory.schedule,
                    teamColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryButton(
                    context,
                    '소식',
                    Icons.newspaper,
                    PostCategory.news,
                    teamColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context,
    String title,
    IconData icon,
    PostCategory category,
    Color teamColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _navigateToCreatePost(category, teamColor);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: teamColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: teamColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: teamColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: teamColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('팀 나가기'),
        content: Text('정말로 ${widget.teamName}에서 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 팀 페이지 닫기
              // TODO: 팀 탈퇴 처리
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  // 현재 사용자가 관리자인지 확인하는 임시 플래그 (실제로는 사용자 권한을 확인해야 함)
  bool get isAdmin => true; // TODO: 실제 관리자 권한 확인 로직

  /// 대문사진 편집 모드 토글
  void _toggleHeaderImageEdit() {
    setState(() {
      _isEditingHeaderImage = !_isEditingHeaderImage;
    });
  }

  /// 대문사진 선택
  Future<void> _pickHeaderImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: AppConstants.maxImageWidth.toDouble(),
        maxHeight: AppConstants.maxImageHeight.toDouble(),
        imageQuality: AppConstants.imageQuality,
      );

      if (pickedFile != null) {
        final team = ref.read(teamByNameProvider(widget.teamName));
        if (team != null) {
          final imageFile = File(pickedFile.path);
          await ref
              .read(teamProvider.notifier)
              .updateTeamHeaderImage(team.id, imageFile);

          // 업로드 완료 후 편집 모드 해제
          setState(() {
            _isEditingHeaderImage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('대문 사진이 업데이트되었습니다.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// 대문사진 저장
  Future<void> _saveHeaderImage() async {
    final team = ref.read(teamByNameProvider(widget.teamName));
    final currentImage =
        team != null ? ref.read(teamHeaderImageProvider(team.id)) : null;

    if (currentImage == null) return;

    try {
      setState(() {
        _isEditingHeaderImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대문 사진이 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('대문 사진 저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// 대문사진 편집 취소
  void _cancelHeaderImageEdit() {
    setState(() {
      _isEditingHeaderImage = false;
    });
  }

  /// 팀 멤버 수 반환 (임시 데이터)
  int _getTeamMemberCount(String teamName) {
    switch (teamName) {
      case '한마음FC':
        return 24;
      case '수우FC':
        return 18;
      case '한FC':
        return 22;
      default:
        return 20;
    }
  }

  /// 포스트 카드 위젯 생성
  Widget _buildPostCard(Post post, Color teamColor) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(post.createdAt);
    String timeAgo;

    if (difference.inMinutes < 1) {
      timeAgo = '방금 전';
    } else if (difference.inHours < 1) {
      timeAgo = '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      timeAgo = '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays}일 전';
    } else {
      timeAgo = DateFormat('yyyy.MM.dd').format(post.createdAt);
    }

    return GestureDetector(
      onTap: () {
        // 게시글 상세 페이지로 이동
        ref.read(navigationProvider.notifier).pushFullScreen(
              PostDetailPage(
                post: post,
                teamColor: teamColor,
                teamName: widget.teamName,
              ),
            );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 내용
              Text(
                post.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // 이미지들 (갤러리 카테고리인 경우)
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post.images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // 하단 정보 (작성자, 시간, 좋아요, 댓글)
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: teamColor),
                  const SizedBox(width: 4),
                  Text(
                    post.authorName,
                    style: TextStyle(
                      fontSize: 12,
                      color: teamColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  if (post.isEdited) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(편집됨)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        ref.read(postProvider.notifier).toggleLike(post.id),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.comments}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 빈 상태 위젯 생성
  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Color teamColor,
    PostCategory category,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _navigateToCreatePost(category, teamColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: teamColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('첫 ${category.displayName} 작성하기'),
            ),
          ],
        ),
      ),
    );
  }

  /// 포스트 작성 페이지로 이동
  void _navigateToCreatePost(PostCategory category, Color teamColor) {
    ref.read(navigationProvider.notifier).pushFullScreen(
          CreatePostPage(
            teamName: widget.teamName,
            category: category,
            teamColor: teamColor,
          ),
        );
  }
}
