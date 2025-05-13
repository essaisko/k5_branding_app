import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/features/match_editor/providers/design_pattern_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 이미지 소스 타입을 정의하기 위한 enum
enum ImageSourceType { sample, gallery, camera }

/// 디자인 패턴 선택 섹션
///
/// 여러 디자인 패턴 중 하나를 선택할 수 있는 토글 버튼 제공
class DesignPatternSection extends ConsumerWidget {
  const DesignPatternSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternState = ref.watch(designPatternProvider);
    final patternNotifier = ref.read(designPatternProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 패턴 없음
          _buildPatternToggle(
            context: context,
            icon: Icons.block,
            label: '없음',
            isSelected: patternState.selectedPattern == DesignPatternType.none,
            onTap: () => patternNotifier.selectPattern(DesignPatternType.none),
          ),

          // 대각선 패턴
          _buildPatternToggle(
            context: context,
            icon: Icons.trending_up,
            label: '대각선',
            isSelected:
                patternState.selectedPattern == DesignPatternType.diagonal,
            onTap: () =>
                patternNotifier.selectPattern(DesignPatternType.diagonal),
          ),

          // 도트 패턴
          _buildPatternToggle(
            context: context,
            icon: Icons.grain,
            label: '도트',
            isSelected: patternState.selectedPattern == DesignPatternType.dots,
            onTap: () => patternNotifier.selectPattern(DesignPatternType.dots),
          ),

          // 이미지 배경 토글 추가
          _buildPatternToggle(
            context: context,
            icon: Icons.image,
            label: '이미지',
            isSelected: patternState.selectedPattern == DesignPatternType.image,
            onTap: () {
              // 이미지 패턴이 아니면 먼저 이미지 패턴으로 상태 변경
              if (patternState.selectedPattern != DesignPatternType.image) {
                patternNotifier.selectPattern(DesignPatternType.image);
              }
              // 이미지 소스 선택 팝업 표시
              _showImageSourceSelectionPopup(context, ref);
            },
          ),
        ],
      ),
    );
  }

  /// 이미지 소스 선택 팝업 표시
  void _showImageSourceSelectionPopup(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('배경 이미지 소스 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('샘플 이미지 사용'),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // 선택 팝업 닫기
                  // 샘플 이미지 선택 다이얼로그 표시
                  _showImageSelectionDialogWithSafety(
                      context, ref, ImageSourceType.sample);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_search_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // 선택 팝업 닫기
                  // 갤러리 이미지 선택 (기존 로직 활용)
                  _showImageSelectionDialogWithSafety(
                      context, ref, ImageSourceType.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // 선택 팝업 닫기
                  _showImageSelectionDialogWithSafety(
                      context, ref, ImageSourceType.camera);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// 안전하게 이미지 선택 다이얼로그를 호출하고 최상위 레벨에서 오류를 처리하는 래퍼 함수
  void _showImageSelectionDialogWithSafety(
      BuildContext context, WidgetRef ref, ImageSourceType sourceType) async {
    try {
      if (!context.mounted) {
        print('Dialog attempt on unmounted context');
        return;
      }
      if (sourceType == ImageSourceType.sample) {
        await _showSampleImageSelectionDialog(context, ref);
      } else if (sourceType == ImageSourceType.gallery) {
        final patternNotifier = ref.read(designPatternProvider.notifier);
        await _pickImageFromGalleryOrCamera(
            context, ref, ImageSource.gallery, patternNotifier);
      } else if (sourceType == ImageSourceType.camera) {
        final patternNotifier = ref.read(designPatternProvider.notifier);
        await _pickImageFromGalleryOrCamera(
            context, ref, ImageSource.camera, patternNotifier);
      }
    } catch (e) {
      print('Critical error during image source selection process: $e');
      final patternNotifier = ref.read(designPatternProvider.notifier);
      patternNotifier.clearImageBackground();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 처리 중 심각한 오류가 발생했습니다.')),
        );
      }
    }
  }

  /// 샘플 이미지 선택 다이얼로그 표시 (기존 _showImageSelectionDialog 로직)
  Future<void> _showSampleImageSelectionDialog(
      BuildContext context, WidgetRef ref) async {
    final patternNotifier = ref.read(designPatternProvider.notifier);
    final patternState = ref.read(designPatternProvider);

    if (sampleBackgroundImages.isEmpty) {
      print('샘플 이미지가 없습니다');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용 가능한 샘플 이미지가 없습니다')),
        );
      }
      return;
    }
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => true,
          child: AlertDialog(
            title: const Text('샘플 배경 이미지 선택'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: sampleBackgroundImages.length,
                    itemBuilder: (context, index) {
                      try {
                        final image = sampleBackgroundImages[index];
                        final isSelected =
                            patternState.selectedImageId == image.id &&
                                !patternState.isCustomImage;
                        return InkWell(
                          onTap: () {
                            try {
                              patternNotifier.selectSampleImage(image.id);
                              if (dialogContext.mounted)
                                Navigator.of(dialogContext).pop();
                            } catch (e) {
                              print('샘플 이미지 선택 오류: $e');
                              if (dialogContext.mounted)
                                Navigator.of(dialogContext).pop();
                              patternNotifier.clearImageBackground();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('이미지 선택 중 오류 발생')),
                                );
                              }
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  image.path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, _) {
                                    print('이미지 로드 오류: ${image.path} - $err');
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.red),
                                    );
                                  },
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    image.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } catch (itemError) {
                        print('샘플 이미지 아이템 렌더링 오류: $itemError');
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('취소'),
              ),
            ],
          ),
        );
      },
    ).catchError((error) {
      print('샘플 이미지 다이얼로그 표시 오류: $error');
      final patternNotifier = ref.read(designPatternProvider.notifier);
      patternNotifier.clearImageBackground();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('샘플 이미지 선택 중 오류: $error')),
        );
      }
    });
  }

  Future<void> _pickImageFromGalleryOrCamera(
      BuildContext context,
      WidgetRef ref,
      ImageSource source,
      DesignPatternNotifier patternNotifier) async {
    try {
      final imagePicker = ImagePicker();
      print(
          '[_pickImageFromDevice] Attempting to pick image with source: $source');

      final XFile? pickedFile = await imagePicker
          .pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 80,
      )
          .catchError((error) {
        print('기기 이미지 선택 오류 (Future catchError): $error');
        throw error;
      });

      print('[_pickImageFromDevice] Picked file: ${pickedFile?.path}');

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (!await file.exists()) {
          throw Exception('선택된 이미지 파일(${pickedFile.path})이 존재하지 않습니다.');
        }
        if ((await file.length()) == 0) {
          throw Exception('이미지 파일(${pickedFile.path})이 비어 있습니다.');
        }
        patternNotifier.selectCustomImage(file);
        print(
            '[_pickImageFromDevice] Custom image selected and state updated.');
      } else {
        print(
            '[_pickImageFromDevice] Image picking cancelled or resulted in null.');
      }
    } catch (e) {
      print('기기 이미지 선택 프로세스 중 심각한 오류: $e');
      patternNotifier.clearImageBackground();
      throw e;
    }
  }

  Widget _buildPatternToggle({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.15)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
