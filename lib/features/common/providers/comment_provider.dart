import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:chukshin_app/domain/entities/post.dart';
import 'package:chukshin_app/features/common/providers/post_provider.dart';

/// 댓글 상태 클래스
class CommentState {
  final List<Comment> comments;
  final bool isLoading;
  final String? error;

  const CommentState({
    this.comments = const [],
    this.isLoading = false,
    this.error,
  });

  CommentState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<Comment> getCommentsByPostId(String postId) {
    return comments.where((comment) => comment.postId == postId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}

/// 댓글 관리 Notifier
class CommentNotifier extends StateNotifier<CommentState> {
  CommentNotifier(this.ref) : super(const CommentState()) {
    _loadCommentsFromFirebase();
  }

  final Ref ref;
  static const _uuid = Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase에서 댓글 로드
  Future<void> _loadCommentsFromFirebase() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      final comments = querySnapshot.docs
          .map((doc) => Comment.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      state = state.copyWith(comments: comments, isLoading: false);

      print('✅ Firebase에서 ${comments.length}개 댓글 로드 완료');
    } catch (e) {
      print('❌ Firebase 댓글 로드 오류: $e');
      state = state.copyWith(isLoading: false, error: '댓글 로드 실패: $e');
    }
  }

  /// 댓글 추가 (Firebase에 저장)
  Future<void> addComment(
    String postId,
    String content,
    String authorId,
    String authorName,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newComment = Comment(
        id: _uuid.v4(),
        postId: postId,
        authorId: authorId,
        authorName: authorName,
        content: content,
        createdAt: DateTime.now(),
      );

      // Firebase에 저장
      await _firestore
          .collection('comments')
          .doc(newComment.id)
          .set(newComment.toMap());

      // 로컬 상태 업데이트
      final updatedComments = [...state.comments, newComment];
      state = state.copyWith(
        comments: updatedComments,
        isLoading: false,
      );

      // 게시글의 댓글 수 업데이트
      final postComments =
          state.copyWith(comments: updatedComments).getCommentsByPostId(postId);
      await ref
          .read(postProvider.notifier)
          .updateCommentCount(postId, postComments.length);

      print('✅ 새 댓글 Firebase 저장 완료: ${newComment.content}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '댓글 생성 실패: $e',
      );
      print('❌ 댓글 Firebase 저장 오류: $e');
    }
  }

  /// 댓글 수정 (Firebase 업데이트)
  Future<void> updateComment(String commentId, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updateData = {
        'content': content,
        'updatedAt': DateTime.now().toIso8601String(),
        'isEdited': true,
      };

      // Firebase 업데이트
      await _firestore.collection('comments').doc(commentId).update(updateData);

      // 로컬 상태 업데이트
      final updatedComments = state.comments.map((comment) {
        if (comment.id == commentId) {
          return comment.copyWith(
            content: content,
            updatedAt: DateTime.now(),
            isEdited: true,
          );
        }
        return comment;
      }).toList();

      state = state.copyWith(
        comments: updatedComments,
        isLoading: false,
      );

      print('✅ 댓글 Firebase 수정 완료: $commentId');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '댓글 수정 실패: $e',
      );
      print('❌ 댓글 Firebase 수정 오류: $e');
    }
  }

  /// 댓글 삭제 (Firebase에서 삭제)
  Future<void> deleteComment(String commentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final comment = state.comments.firstWhere((c) => c.id == commentId);

      // Firebase에서 삭제
      await _firestore.collection('comments').doc(commentId).delete();

      // 로컬 상태 업데이트
      final updatedComments =
          state.comments.where((comment) => comment.id != commentId).toList();

      state = state.copyWith(
        comments: updatedComments,
        isLoading: false,
      );

      // 게시글의 댓글 수 업데이트
      final postComments =
          updatedComments.where((c) => c.postId == comment.postId).toList();
      await ref
          .read(postProvider.notifier)
          .updateCommentCount(comment.postId, postComments.length);

      print('✅ 댓글 Firebase 삭제 완료: $commentId');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '댓글 삭제 실패: $e',
      );
      print('❌ 댓글 Firebase 삭제 오류: $e');
    }
  }

  /// 댓글 좋아요 토글 (Firebase 업데이트)
  Future<void> toggleCommentLike(String commentId) async {
    try {
      final comment = state.comments.firstWhere((c) => c.id == commentId);
      final newLikes = comment.likes + 1;

      // Firebase 업데이트
      await _firestore.collection('comments').doc(commentId).update({
        'likes': newLikes,
      });

      // 로컬 상태 업데이트
      final updatedComments = state.comments.map((comment) {
        if (comment.id == commentId) {
          return comment.copyWith(likes: newLikes);
        }
        return comment;
      }).toList();

      state = state.copyWith(comments: updatedComments);
    } catch (e) {
      print('❌ 댓글 좋아요 업데이트 오류: $e');
    }
  }

  /// 실시간 댓글 리스너 설정 (Firebase 실시간 업데이트)
  void listenToCommentsRealTime() {
    _firestore
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          final comments = snapshot.docs
              .map((doc) => Comment.fromMap({...doc.data(), 'id': doc.id}))
              .toList();

          state = state.copyWith(comments: comments, isLoading: false);
          print('🔄 Firebase 실시간 댓글 업데이트: ${comments.length}개');
        } catch (e) {
          print('❌ Firebase 댓글 실시간 업데이트 오류: $e');
        }
      },
      onError: (error) {
        print('❌ Firebase 댓글 리스너 오류: $error');
      },
    );
  }
}

/// 댓글 Provider
final commentProvider = StateNotifierProvider<CommentNotifier, CommentState>(
  (ref) => CommentNotifier(ref),
);

/// 특정 게시글의 댓글 Provider
final postCommentsProvider =
    Provider.family<List<Comment>, String>((ref, postId) {
  final commentState = ref.watch(commentProvider);
  return commentState.comments
      .where((comment) => comment.postId == postId)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});
