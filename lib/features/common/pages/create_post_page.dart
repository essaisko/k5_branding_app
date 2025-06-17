import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:chukshin_app/domain/entities/post.dart';
import 'package:chukshin_app/features/common/providers/post_provider.dart';
import 'package:chukshin_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:chukshin_app/presentation/navigation/navigation_state.dart';
import 'package:chukshin_app/core/constants/app_constants.dart';
import 'package:chukshin_app/core/services/firebase_storage_service.dart';
import 'package:chukshin_app/presentation/pages/team_community_page.dart';

/// 포스트 작성 페이지
class CreatePostPage extends ConsumerStatefulWidget {
  final String teamName;
  final PostCategory category;
  final Color teamColor;

  const CreatePostPage({
    super.key,
    required this.teamName,
    required this.category,
    required this.teamColor,
  });

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // 팀 커뮤니티로 돌아가기
            ref.read(navigationProvider.notifier).popToTeamCommunity(
                  TeamCommunityPage(
                    teamName: widget.teamName,
                    teamColor: widget.teamColor,
                  ),
                );
          },
        ),
        title: Text(
          '${widget.category.displayName} 작성',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '완료',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카테고리 표시
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.teamColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.category.displayName,
                          style: TextStyle(
                            color: widget.teamColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),

                      // 제목 입력
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '제목',
                          hintText: '제목을 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '제목을 입력해주세요';
                          }
                          if (value.trim().length < 2) {
                            return '제목은 2글자 이상 입력해주세요';
                          }
                          return null;
                        },
                        maxLength: 50,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),

                      // 내용 입력
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: '내용',
                          hintText: '내용을 입력하세요',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 10,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '내용을 입력해주세요';
                          }
                          if (value.trim().length < 5) {
                            return '내용은 5글자 이상 입력해주세요';
                          }
                          return null;
                        },
                        maxLength: 1000,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),

                      // 이미지 추가 섹션
                      if (widget.category == PostCategory.gallery)
                        _buildImageSection(),
                    ],
                  ),
                ),
              ),

              // 하단 버튼 영역
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.category == PostCategory.gallery)
                      IconButton(
                        onPressed: _pickImages,
                        icon: Icon(
                          Icons.add_photo_alternate,
                          color: widget.teamColor,
                        ),
                        tooltip: '사진 추가',
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.teamColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('게시하기'),
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '사진',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_selectedImages.length}/5)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedImages.isEmpty)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '사진 추가',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  // 추가 버튼
                  return GestureDetector(
                    onTap: _selectedImages.length < 5 ? _pickImages : null,
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedImages.length < 5
                              ? Colors.grey[300]!
                              : Colors.grey[200]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: 32,
                          color: _selectedImages.length < 5
                              ? Colors.grey[600]
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  );
                }

                // 선택된 이미지 표시
                return Container(
                  width: 120,
                  margin: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          // 최대 5개까지만 선택 가능
          final remainingSlots = 5 - _selectedImages.length;
          _selectedImages.addAll(
              images.take(remainingSlots).map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 이미지 업로드
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final storageService = FirebaseStorageService();
        imageUrls = await storageService.uploadImages(_selectedImages, 'posts');
      }

      final request = CreatePostRequest(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imagePaths: imageUrls,
        category: widget.category,
        teamId: widget.teamName,
      );

      await ref.read(postProvider.notifier).createPost(
            request,
            authState.user!.id,
            authState.user!.name,
          );

      if (mounted) {
        // 팀 커뮤니티 페이지로 돌아가기
        ref.read(navigationProvider.notifier).popToTeamCommunity(
              TeamCommunityPage(
                teamName: widget.teamName,
                teamColor: widget.teamColor,
              ),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.category.displayName}이(가) 성공적으로 게시되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
