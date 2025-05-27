import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:k5_branding_app/core/constants/asset_paths.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/features/match_editor/providers/sample_data_provider.dart';
import 'dart:developer' as dev;
import 'dart:io';

class CompactLogoButton extends ConsumerWidget {
  final bool isHomeTeam;
  final String currentPath;
  final Function(String) onLogoSelected;
  final double size;

  const CompactLogoButton({
    super.key,
    required this.isHomeTeam,
    required this.currentPath,
    required this.onLogoSelected,
    this.size = 48.0,
  });

  Future<void> _pickImageFromGallery(
      BuildContext context, Function(String) onLogoSelectedCallback) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        onLogoSelectedCallback(image.path);
        if (context.mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      dev.log('이미지 선택 오류: $e', name: 'CompactLogoButton');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultImage = AssetPaths.defaultCrest;
    final displayedPath = currentPath.isEmpty ? defaultImage : currentPath;
    final double paddingValue = size / 12.0;

    return InkWell(
      onTap: () =>
          _showLogoSelectionDialog(context, ref, isHomeTeam, onLogoSelected),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: EdgeInsets.all(paddingValue),
          child: ClipOval(
            child: displayedPath.startsWith('http') ||
                    displayedPath.startsWith('/')
                ? (displayedPath.startsWith('http')
                    ? Image.network(
                        displayedPath,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) =>
                            const Icon(Icons.broken_image),
                      )
                    : Image.file(
                        File(displayedPath),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) =>
                            const Icon(Icons.broken_image),
                      ))
                : Image.asset(
                    displayedPath,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, _) =>
                        const Icon(Icons.broken_image),
                  ),
          ),
        ),
      ),
    );
  }

  void _showLogoSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    bool isHomeTeam,
    Function(String) onLogoSelectedCallback,
  ) {
    try {
      final sampleTeams = ref.read(sampleTeamsProvider);
      final List<String> displayableLogoPaths = [
        AssetPaths.defaultCrest,
        ...sampleTeams
            .map((team) => team.logoPath)
            .where((path) => path.isNotEmpty)
      ];
      final uniqueLogoPaths = displayableLogoPaths.toSet().toList();

      final int itemCountWithGalleryOption = uniqueLogoPaths.length + 1;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('로고 선택', style: AppTypography.heading3),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: itemCountWithGalleryOption,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return InkWell(
                    onTap: () {
                      _pickImageFromGallery(
                          dialogContext, onLogoSelectedCallback);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library,
                              size: 32, color: Theme.of(context).primaryColor),
                          const SizedBox(height: 8),
                          Text('갤러리', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  );
                }

                final logoPath = uniqueLogoPaths[index - 1];
                return InkWell(
                  onTap: () {
                    try {
                      onLogoSelectedCallback(logoPath);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (e) {
                      dev.log('로고 선택 오류: $e', name: 'CompactLogoButton');
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('로고 선택 중 오류: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: _buildSafeImage(logoPath),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: Text('취소', style: AppTypography.buttonMedium),
            ),
          ],
        ),
      ).catchError((e) {
        dev.log('로고 선택 다이얼로그 표시 오류: $e', name: 'CompactLogoButton');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('다이얼로그 표시 중 오류: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      dev.log('로고 선택 프로세스 오류: $e', name: 'CompactLogoButton');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로고 선택 처리 중 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSafeImage(String path) {
    if (path.startsWith('/') || path.startsWith('file://')) {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          dev.log('파일 이미지 로드 오류: $path - $error', name: 'CompactLogoButton');
          return const Icon(Icons.broken_image, color: Colors.red);
        },
      );
    } else if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          dev.log('네트워크 이미지 로드 오류: $path - $error', name: 'CompactLogoButton');
          return const Icon(Icons.broken_image, color: Colors.red);
        },
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        dev.log('에셋 이미지 로드 오류: $path - $error', name: 'CompactLogoButton');
        return const Icon(Icons.broken_image, color: Colors.red);
      },
    );
  }
}
