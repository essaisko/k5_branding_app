import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chukshin_app/domain/entities/post.dart';
import 'package:chukshin_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

/// 포스트 상태 클래스
class PostState {
  final List<Post> posts;
  final bool isLoading;
  final String? error;

  const PostState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  PostState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
  }) {
    return PostState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 포스트 관리 Notifier
class PostNotifier extends StateNotifier<PostState> {
  PostNotifier() : super(const PostState()) {
    _loadSamplePosts();
  }

  static const _uuid = Uuid();

  /// 샘플 포스트 로드 (개발용)
  void _loadSamplePosts() {
    final samplePosts = [
      Post(
        id: _uuid.v4(),
        authorId: 'sample_user_1',
        authorName: '김철수',
        title: '오늘 훈련 후기',
        content: '오늘 훈련이 정말 좋았습니다! 새로운 전술을 배워서 즐거웠어요.',
        category: PostCategory.community,
        teamId: '한마음FC',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 5,
        comments: 3,
      ),
      Post(
        id: _uuid.v4(),
        authorId: 'sample_user_2',
        authorName: '이영희',
        title: '이번 주말 경기 사진',
        content: '지난 주말 경기에서 찍은 사진들입니다.',
        category: PostCategory.gallery,
        teamId: '수우FC',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        likes: 12,
        comments: 7,
      ),
      Post(
        id: _uuid.v4(),
        authorId: 'sample_user_3',
        authorName: '박민수',
        title: '다음 주 훈련 일정',
        content: '다음 주 화요일, 목요일 7시에 정기 훈련이 있습니다.',
        category: PostCategory.schedule,
        teamId: '한FC',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likes: 8,
        comments: 2,
      ),
    ];

    state = state.copyWith(posts: samplePosts);
  }

  /// 새 포스트 생성
  Future<void> createPost(
      CreatePostRequest request, String authorId, String authorName) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newPost = Post(
        id: _uuid.v4(),
        authorId: authorId,
        authorName: authorName,
        title: request.title,
        content: request.content,
        images: request.imagePaths,
        category: request.category,
        teamId: request.teamId,
        createdAt: DateTime.now(),
      );

      final updatedPosts = [newPost, ...state.posts];
      state = state.copyWith(
        posts: updatedPosts,
        isLoading: false,
      );

      print('✅ 새 포스트 생성 완료: ${newPost.title}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '포스트 생성 실패: $e',
      );
      print('❌ 포스트 생성 오류: $e');
    }
  }

  /// 포스트 수정
  Future<void> updatePost(String postId, String title, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            title: title,
            content: content,
            updatedAt: DateTime.now(),
            isEdited: true,
          );
        }
        return post;
      }).toList();

      state = state.copyWith(
        posts: updatedPosts,
        isLoading: false,
      );

      print('✅ 포스트 수정 완료: $postId');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '포스트 수정 실패: $e',
      );
      print('❌ 포스트 수정 오류: $e');
    }
  }

  /// 포스트 삭제
  Future<void> deletePost(String postId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedPosts =
          state.posts.where((post) => post.id != postId).toList();

      state = state.copyWith(
        posts: updatedPosts,
        isLoading: false,
      );

      print('✅ 포스트 삭제 완료: $postId');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '포스트 삭제 실패: $e',
      );
      print('❌ 포스트 삭제 오류: $e');
    }
  }

  /// 좋아요 토글
  void toggleLike(String postId) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(likes: post.likes + 1);
      }
      return post;
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  /// 팀별 포스트 필터링
  List<Post> getPostsByTeam(String teamId) {
    return state.posts.where((post) => post.teamId == teamId).toList();
  }

  /// 카테고리별 포스트 필터링
  List<Post> getPostsByCategory(PostCategory category) {
    return state.posts.where((post) => post.category == category).toList();
  }

  /// 사용자별 포스트 필터링
  List<Post> getPostsByAuthor(String authorId) {
    return state.posts.where((post) => post.authorId == authorId).toList();
  }

  /// 팀과 카테고리로 포스트 필터링
  List<Post> getPostsByTeamAndCategory(String teamId, PostCategory category) {
    return state.posts
        .where((post) => post.teamId == teamId && post.category == category)
        .toList();
  }
}

/// 포스트 상태 관리 Provider
final postProvider = StateNotifierProvider<PostNotifier, PostState>((ref) {
  return PostNotifier();
});

/// 팀별 포스트 Provider
final teamPostsProvider = Provider.family<List<Post>, String>((ref, teamId) {
  final postState = ref.watch(postProvider);
  return postState.posts.where((post) => post.teamId == teamId).toList();
});

/// 카테고리별 포스트 Provider
final categoryPostsProvider =
    Provider.family<List<Post>, PostCategory>((ref, category) {
  final postState = ref.watch(postProvider);
  return postState.posts.where((post) => post.category == category).toList();
});

/// 팀과 카테고리별 포스트 Provider
final teamCategoryPostsProvider =
    Provider.family<List<Post>, ({String teamId, PostCategory category})>(
        (ref, params) {
  final postState = ref.watch(postProvider);
  return postState.posts
      .where((post) =>
          post.teamId == params.teamId && post.category == params.category)
      .toList();
});

/// 현재 사용자의 포스트 Provider
final myPostsProvider = Provider<List<Post>>((ref) {
  final postState = ref.watch(postProvider);
  final authState = ref.watch(authProvider);
  final currentUserId = authState.user?.id;

  if (currentUserId == null) return [];

  return postState.posts
      .where((post) => post.authorId == currentUserId)
      .toList();
});
