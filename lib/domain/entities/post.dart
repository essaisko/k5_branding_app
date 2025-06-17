/// 사용자 생성 포스트 엔티티
/// 팀 커뮤니티의 갤러리, 커뮤니티, 일정 등에서 사용
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfileImage;
  final String title;
  final String content;
  final List<String> images;
  final PostCategory category;
  final String teamId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likes;
  final int comments;
  final bool isEdited;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfileImage,
    required this.title,
    required this.content,
    this.images = const [],
    required this.category,
    required this.teamId,
    required this.createdAt,
    this.updatedAt,
    this.likes = 0,
    this.comments = 0,
    this.isEdited = false,
  });

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorProfileImage,
    String? title,
    String? content,
    List<String>? images,
    PostCategory? category,
    String? teamId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    int? comments,
    bool? isEdited,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileImage: authorProfileImage ?? this.authorProfileImage,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      category: category ?? this.category,
      teamId: teamId ?? this.teamId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileImage': authorProfileImage,
      'title': title,
      'content': content,
      'images': images,
      'category': category.name,
      'teamId': teamId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'isEdited': isEdited,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      authorId: map['authorId'] as String,
      authorName: map['authorName'] as String,
      authorProfileImage: map['authorProfileImage'] as String?,
      title: map['title'] as String,
      content: map['content'] as String,
      images: List<String>.from(map['images'] as List),
      category: PostCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => PostCategory.community,
      ),
      teamId: map['teamId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      likes: map['likes'] as int? ?? 0,
      comments: map['comments'] as int? ?? 0,
      isEdited: map['isEdited'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, title: $title, authorName: $authorName, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 포스트 카테고리
enum PostCategory {
  gallery('갤러리'),
  community('커뮤니티'),
  schedule('일정'),
  news('소식');

  const PostCategory(this.displayName);
  final String displayName;
}

/// 포스트 생성을 위한 DTO
class CreatePostRequest {
  final String title;
  final String content;
  final List<String> imagePaths;
  final PostCategory category;
  final String teamId;

  const CreatePostRequest({
    required this.title,
    required this.content,
    this.imagePaths = const [],
    required this.category,
    required this.teamId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imagePaths': imagePaths,
      'category': category.name,
      'teamId': teamId,
    };
  }
}
