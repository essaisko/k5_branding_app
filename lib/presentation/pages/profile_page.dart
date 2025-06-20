import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:chukshin_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:chukshin_app/presentation/navigation/routes.dart';
import 'package:chukshin_app/domain/entities/post.dart';
import 'package:chukshin_app/features/common/providers/post_provider.dart';
import 'package:chukshin_app/features/common/pages/post_detail_page.dart';
import 'package:chukshin_app/presentation/navigation/navigation_state.dart';
import 'package:flutter/foundation.dart';

/// 나의 정보 페이지
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;

  // 편집 모드용 컨트롤러들
  late TextEditingController _nameController;
  late TextEditingController _residenceController;
  String? _selectedPosition;
  DateTime? _selectedBirthDate;
  List<String> _selectedTeams = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _residenceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _residenceController.dispose();
    super.dispose();
  }

  void _initializeEditMode(user) {
    _nameController.text = user.name;
    _residenceController.text = user.residenceArea ?? '';
    _selectedPosition = user.position;
    _selectedBirthDate = user.birthDate;
    _selectedTeams = List<String>.from(user.affiliatedTeams);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '나의 정보',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80,
                    color: theme.primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '로그인이 필요합니다',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    child: const Text('로그인하기'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 프로필 카드
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // 프로필 이미지
                          GestureDetector(
                            onTap: _isEditing ? _pickProfileImage : null,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: theme.primaryColor,
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : (user.profileImageUrl != null &&
                                              user.profileImageUrl!.isNotEmpty
                                          ? NetworkImage(user.profileImageUrl!)
                                          : null) as ImageProvider?,
                                  child: (_profileImage == null &&
                                          (user.profileImageUrl == null ||
                                              user.profileImageUrl!.isEmpty))
                                      ? Text(
                                          user.name.isNotEmpty
                                              ? user.name[0]
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                // 로딩 인디케이터 (네트워크 이미지 로딩 시)
                                if (_profileImage == null &&
                                    user.profileImageUrl != null &&
                                    user.profileImageUrl!.isNotEmpty)
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.transparent,
                                      child: FutureBuilder(
                                        future: precacheImage(
                                            NetworkImage(user.profileImageUrl!),
                                            context),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator(
                                                strokeWidth: 2);
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                  ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (user.phoneNumber.isNotEmpty)
                            Text(
                              _formatPhoneNumber(user.phoneNumber),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 정보 섹션
                  _buildInfoSection(
                    '기본 정보',
                    [
                      _buildInfoItem('생년월일', _formatDate(user.birthDate)),
                      if (user.residenceArea != null)
                        _buildInfoItem('거주지역', user.residenceArea!),
                      if (user.position != null)
                        _buildInfoItem('포지션', user.position!),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 소속팀 섹션
                  if (user.affiliatedTeams.isNotEmpty)
                    _buildInfoSection(
                      '소속팀',
                      user.affiliatedTeams
                          .map((team) => _buildInfoItem('팀', team))
                          .toList(),
                    ),

                  const SizedBox(height: 16),

                  // 나의 작성 글 섹션
                  _buildMyPostsSection(user.id, theme),

                  const SizedBox(height: 24),

                  // 액션 버튼들
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_isEditing) {
                              _saveProfile();
                            } else {
                              _initializeEditMode(user);
                              setState(() {
                                _isEditing = true;
                              });
                            }
                          },
                          icon: Icon(_isEditing ? Icons.save : Icons.edit),
                          label: Text(_isEditing ? '저장' : '프로필 수정'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: _isEditing ? Colors.green : null,
                          ),
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _profileImage = null;
                              });
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('취소'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('로그아웃'),
                                content: const Text('정말 로그아웃하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('로그아웃'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldLogout == true) {
                              await ref.read(authProvider.notifier).logout();
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.opening,
                                  (route) => false,
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('로그아웃'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 개발자 메뉴 (디버그 모드에서만 표시)
                  if (kDebugMode) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '개발자 메뉴',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.bug_report),
                            title: const Text('디버그 페이지'),
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.debug);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.data_object),
                            title: const Text('데이터 구조 가이드'),
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.firebaseSetup);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  // 나의 작성 글 섹션
  Widget _buildMyPostsSection(String userId, ThemeData theme) {
    final myPosts = ref.watch(myPostsProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '나의 작성 글',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${myPosts.length}',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (myPosts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.edit_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '작성한 글이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '팀 커뮤니티에서 첫 글을 작성해보세요!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // 카테고리별 통계
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        _buildPostCategoryCount('갤러리', PostCategory.gallery,
                            myPosts, Icons.photo_library, Colors.purple),
                        const SizedBox(width: 16),
                        _buildPostCategoryCount('커뮤니티', PostCategory.community,
                            myPosts, Icons.chat_bubble, Colors.blue),
                        const SizedBox(width: 16),
                        _buildPostCategoryCount('일정', PostCategory.schedule,
                            myPosts, Icons.event, Colors.green),
                        const SizedBox(width: 16),
                        _buildPostCategoryCount('소식', PostCategory.news,
                            myPosts, Icons.newspaper, Colors.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 최근 작성 글 목록 (최대 3개)
                  ...myPosts
                      .take(3)
                      .map((post) => _buildMyPostItem(post, theme))
                      .toList(),

                  if (myPosts.length > 3) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        // TODO: 전체 작성 글 페이지로 이동
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('전체 작성 글 페이지는 준비 중입니다.')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: theme.primaryColor.withOpacity(0.3)),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '더 보기 (+${myPosts.length - 3})',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: theme.primaryColor,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCategoryCount(String label, PostCategory category,
      List<Post> posts, IconData icon, Color color) {
    final count = posts.where((post) => post.category == category).length;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPostItem(Post post, ThemeData theme) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(post.createdAt);
    String timeAgo;

    if (difference.inMinutes < 1) {
      timeAgo = '방금 전';
    } else if (difference.inHours < 1) {
      timeAgo = '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      timeAgo = '${difference.inHours}시간 전';
    } else {
      timeAgo = '${difference.inDays}일 전';
    }

    // 팀별 색상 매핑
    final teamColors = {
      '한마음FC': Colors.red,
      '수우FC': Colors.blue,
      '한FC': Colors.green,
      '기타': Colors.grey,
    };

    final teamColor = teamColors[post.teamId] ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        // 게시글 상세 페이지로 이동
        ref.read(navigationProvider.notifier).pushFullScreen(
              PostDetailPage(
                post: post,
                teamColor: teamColor,
              ),
            );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // 카테고리 아이콘
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getCategoryColor(post.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(post.category),
                size: 16,
                color: _getCategoryColor(post.category),
              ),
            ),
            const SizedBox(width: 12),

            // 글 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _getCategoryColor(post.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.category.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getCategoryColor(post.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.teamId,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(
                        '${post.likes}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (post.isEdited) ...[
                        const SizedBox(width: 8),
                        Text(
                          '편집됨',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 클릭 표시 아이콘 추가
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.gallery:
        return Colors.purple;
      case PostCategory.community:
        return Colors.blue;
      case PostCategory.schedule:
        return Colors.green;
      case PostCategory.news:
        return Colors.orange;
    }
  }

  IconData _getCategoryIcon(PostCategory category) {
    switch (category) {
      case PostCategory.gallery:
        return Icons.photo_library;
      case PostCategory.community:
        return Icons.chat_bubble;
      case PostCategory.schedule:
        return Icons.event;
      case PostCategory.news:
        return Icons.newspaper;
    }
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '미입력';
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return '미입력';

    // +8210으로 시작하는 경우 010으로 변환
    if (phoneNumber.startsWith('+8210')) {
      final number = phoneNumber.substring(4);
      if (number.length == 8) {
        return '010-${number.substring(0, 4)}-${number.substring(4)}';
      }
    }

    // 이미 형식화된 번호인 경우 그대로 반환
    if (phoneNumber.contains('-')) {
      return phoneNumber;
    }

    // 010으로 시작하는 11자리 번호 형식화
    if (phoneNumber.startsWith('010') && phoneNumber.length == 11) {
      return '${phoneNumber.substring(0, 3)}-${phoneNumber.substring(3, 7)}-${phoneNumber.substring(7)}';
    }

    return phoneNumber;
  }

  // 프로필 이미지 선택
  Future<void> _pickProfileImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로필 사진 선택'),
        content: const Text('어떤 방법으로 사진을 선택하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('카메라'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('갤러리'),
          ),
        ],
      ),
    );

    if (source != null) {
      try {
        print('🔥 이미지 선택 시작 - 소스: $source');
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 300,
          maxHeight: 300,
          imageQuality: 80,
        );

        if (image != null) {
          print('🔥 이미지 선택 완료: ${image.path}');
          final imageFile = File(image.path);
          print('🔥 파일 존재 확인: ${imageFile.existsSync()}');
          print('🔥 파일 크기: ${imageFile.lengthSync()} bytes');

          setState(() {
            _profileImage = imageFile;
          });
          print('🔥 상태 업데이트 완료');
        } else {
          print('🔥 이미지 선택 취소됨');
        }
      } catch (e) {
        print('🔴 이미지 선택 오류: ${e.toString()}');
        print('🔴 오류 타입: ${e.runtimeType}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미지 선택 중 오류가 발생했습니다: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 프로필 저장
  Future<void> _saveProfile() async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        print('🔴 저장 실패: 로그인된 사용자가 없음');
        return;
      }

      print('🔥 프로필 저장 시작');
      print('🔥 저장할 데이터:');
      print('   - name: ${_nameController.text.trim()}');
      print('   - birthDate: $_selectedBirthDate');
      print('   - position: $_selectedPosition');
      print('   - residenceArea: ${_residenceController.text.trim()}');
      print('   - affiliatedTeams: $_selectedTeams');
      print(
          '   - profileImage: ${_profileImage != null ? "있음 (${_profileImage!.path})" : "없음"}');

      await ref.read(authProvider.notifier).updateUserProfile(
            name: _nameController.text.trim(),
            birthDate: _selectedBirthDate,
            position: _selectedPosition,
            residenceArea: _residenceController.text.trim().isNotEmpty
                ? _residenceController.text.trim()
                : null,
            affiliatedTeams: _selectedTeams,
            profileImage: _profileImage,
          );

      print('🔥 프로필 저장 완료');

      setState(() {
        _isEditing = false;
        _profileImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 업데이트되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('🔴 프로필 저장 오류: ${e.toString()}');
      print('🔴 오류 타입: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 업데이트 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
