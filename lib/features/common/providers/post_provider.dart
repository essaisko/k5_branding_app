import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    _loadPostsFromFirebase();
  }

  static const _uuid = Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase에서 포스트 로드
  Future<void> _loadPostsFromFirebase() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      final posts = querySnapshot.docs
          .map((doc) => Post.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      state = state.copyWith(posts: posts, isLoading: false);

      print('✅ Firebase에서 ${posts.length}개 포스트 로드 완료');
    } catch (e) {
      print('❌ Firebase 포스트 로드 오류: $e');
      // Firebase 연결 실패 시 샘플 데이터 사용
      _loadSamplePosts();
    }
  }

  /// 샘플 포스트 로드 (Firebase 연결 실패 시 사용)
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

    state = state.copyWith(posts: samplePosts, isLoading: false);
  }

  /// 새 포스트 생성 (Firebase에 저장)
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

      // Firebase에 저장
      await _firestore.collection('posts').doc(newPost.id).set(newPost.toMap());

      // 로컬 상태 업데이트
      final updatedPosts = [newPost, ...state.posts];
      state = state.copyWith(
        posts: updatedPosts,
        isLoading: false,
      );

      print('✅ 새 포스트 Firebase 저장 완료: ${newPost.title}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '포스트 생성 실패: $e',
      );
      print('❌ 포스트 Firebase 저장 오류: $e');
    }
  }

  /// 포스트 수정 (Firebase 업데이트)
  Future<void> updatePost(String postId, String title, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updateData = {
        'title': title,
        'content': content,
        'updatedAt': DateTime.now().toIso8601String(),
        'isEdited': true,
      };

      // Firebase 업데이트
      await _firestore.collection('posts').doc(postId).update(updateData);

      // 로컬 상태 업데이트
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

      print('✅ 포스트 Firebase 수정 완료: $postId');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '포스트 수정 실패: $e',
      );
      print('❌ 포스트 Firebase 수정 오류: $e');
    }
  }

  /// 포스트 삭제 (Firebase에서 삭제)
  Future<void> deletePost(String postId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Firebase에서 삭제
      await _firestore.collection('posts').doc(postId).delete();

      // 로컬 상태 업데이트
      final updatedPosts =
          state.posts.where((post) => post.id != postId).toList();

      state = state.copyWith(
        posts: updatedPosts,
        isLoading: false,
      );

      print('✅ 포스트 Firebase 삭제 완료: $postId');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '포스트 삭제 실패: $e',
      );
      print('❌ 포스트 Firebase 삭제 오류: $e');
    }
  }

  /// 좋아요 토글 (Firebase 업데이트)
  Future<void> toggleLike(String postId) async {
    try {
      final post = state.posts.firstWhere((p) => p.id == postId);
      final newLikes = post.likes + 1;

      // Firebase 업데이트
      await _firestore.collection('posts').doc(postId).update({
        'likes': newLikes,
      });

      // 로컬 상태 업데이트
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(likes: newLikes);
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);
    } catch (e) {
      print('❌ 좋아요 업데이트 오류: $e');
    }
  }

  /// 댓글 수 업데이트 (Firebase 업데이트)
  Future<void> updateCommentCount(String postId, int commentCount) async {
    try {
      // Firebase 업데이트
      await _firestore.collection('posts').doc(postId).update({
        'comments': commentCount,
      });

      // 로컬 상태 업데이트
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(comments: commentCount);
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);
    } catch (e) {
      print('❌ 댓글 수 업데이트 오류: $e');
    }
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
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 실시간 포스트 리스너 설정 (Firebase 실시간 업데이트)
  void listenToPostsRealTime() {
    _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          final posts = snapshot.docs
              .map((doc) => Post.fromMap({...doc.data(), 'id': doc.id}))
              .toList();

          state = state.copyWith(posts: posts, isLoading: false);
          print('🔄 Firebase 실시간 포스트 업데이트: ${posts.length}개');
        } catch (e) {
          print('❌ Firebase 실시간 업데이트 오류: $e');
        }
      },
      onError: (error) {
        print('❌ Firebase 리스너 오류: $error');
      },
    );
  }
}

/// 포스트 Provider
final postProvider = StateNotifierProvider<PostNotifier, PostState>(
  (ref) => PostNotifier(),
);

/// 팀별 포스트 Provider
final teamPostsProvider = Provider.family<List<Post>, String>((ref, teamId) {
  final postState = ref.watch(postProvider);
  return postState.posts.where((post) => post.teamId == teamId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// 팀별 카테고리 포스트 Provider
final teamCategoryPostsProvider =
    Provider.family<List<Post>, ({String teamId, PostCategory category})>(
  (ref, params) {
    final postState = ref.watch(postProvider);
    return postState.posts
        .where((post) =>
            post.teamId == params.teamId && post.category == params.category)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  },
);

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
