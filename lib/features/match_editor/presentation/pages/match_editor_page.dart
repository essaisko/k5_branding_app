import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/theme/app_colors.dart';
import 'package:k5_branding_app/features/match_editor/providers/providers.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/photo_display_area.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/template_selector.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/match_info_tab.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/details_tab.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/design_tab.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

/// Match photo editor page following Steve Jobs' design philosophy:
/// - Focus on user experience
/// - Eliminate clutter
/// - Pay attention to details
/// - Make it intuitive
class MatchEditorPage extends ConsumerStatefulWidget {
  const MatchEditorPage({super.key});

  @override
  ConsumerState<MatchEditorPage> createState() => _MatchEditorPageState();
}

class _MatchEditorPageState extends ConsumerState<MatchEditorPage>
    with SingleTickerProviderStateMixin {
  bool _isPreviewExpanded = true;
  bool _isPreviewReady = true;

  // 탭 컨트롤러 추가
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 미리보기 영역 표시/숨김 토글
  void _togglePreview() {
    setState(() {
      // 미리보기 상태 변경 전에 준비 상태를 false로 설정
      _isPreviewReady = false;
      _isPreviewExpanded = !_isPreviewExpanded;

      // 상태 변경 후 애니메이션을 위한 딜레이 추가
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _isPreviewReady = true;
          });
        }
      });
    });
  }

  // 저장 미리보기 다이얼로그 표시 - PhotoDisplayArea의 미리보기와 동일
  void _showSavePreviewDialog() {
    final selectedTemplate = ref.read(templateProvider);

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                // 배경 색상
                Container(color: Colors.black),

                // 템플릿 내용 - 정확히 1080x1350 크기로 표시하되, 화면에 맞게 조정
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 화면에 맞는 최대 크기 계산
                      double maxWidth = constraints.maxWidth * 0.95;
                      double maxHeight =
                          constraints.maxHeight * 0.85; // 상단 컨트롤바 공간 확보

                      // 1080x1350 비율 유지하면서 최대 크기 맞추기
                      double aspectRatio = 1080 / 1350;

                      double displayWidth = maxWidth;
                      double displayHeight = displayWidth / aspectRatio;

                      if (displayHeight > maxHeight) {
                        displayHeight = maxHeight;
                        displayWidth = displayHeight * aspectRatio;
                      }

                      return Container(
                        width: displayWidth,
                        height: displayHeight,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: RepaintBoundary(
                          key: PhotoDisplayArea.previewDialogKey,
                          child: SizedBox(
                            width: 1080,
                            height: 1350,
                            child: PhotoDisplayArea(isCaptureMode: true),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 상단 컨트롤바
                SafeArea(
                  child: Container(
                    height: 56,
                    color: Colors.black.withOpacity(0.7),
                    child: Row(
                      children: [
                        // 뒤로가기 버튼
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),

                        // 제목
                        const Expanded(
                          child: Text(
                            '이미지 미리보기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // 저장 버튼
                        IconButton(
                          icon: const Icon(Icons.save_alt, color: Colors.white),
                          onPressed: () => _captureAndSaveImage(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 이미지 캡처 및 저장 기능
  Future<void> _captureAndSaveImage(BuildContext context) async {
    try {
      // PhotoDisplayArea의 저장 기능과 동일한 로직
      final boundary = PhotoDisplayArea.previewDialogKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('캡처할 위젯을 찾을 수 없습니다');
      }

      // 로딩 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(child: Text('이미지 저장 중...')),
              ],
            ),
            backgroundColor: AppColors.k5LeagueBlue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // 렌더링 완료 대기
      await Future.delayed(const Duration(milliseconds: 300));

      // 1080x1350 크기로 정확히 캡처
      final image = await boundary.toImage(pixelRatio: 1.0);

      // PNG 데이터로 변환
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('이미지 데이터 생성 실패');
      }

      final pngBytes = byteData.buffer.asUint8List();

      // 파일명 생성
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final filename = 'K5League_Match_$timestamp.png';

      // 갤러리에 저장 (PhotoManager 사용)
      final result = await PhotoManager.editor.saveImage(
        pngBytes,
        title: 'K5 League 매치',
        desc: '경기 결과 이미지 (1080x1350)',
        filename: filename,
      );

      if (context.mounted) {
        // 기존 스낵바 제거
        ScaffoldMessenger.of(context).clearSnackBars();

        if (result != null) {
          // 성공 다이얼로그 표시
          _showSuccessDialog(context, filename);
        } else {
          throw Exception('이미지 저장에 실패했습니다');
        }
      }
    } catch (e) {
      if (context.mounted) {
        // 기존 스낵바 제거
        ScaffoldMessenger.of(context).clearSnackBars();

        // 오류 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '재시도',
              textColor: Colors.white,
              onPressed: () => _captureAndSaveImage(context),
            ),
          ),
        );
      }
    }
  }

  /// 저장 성공 다이얼로그 표시
  void _showSuccessDialog(BuildContext context, String filename) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 성공 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 50,
              ),
            ),
            const SizedBox(height: 20),

            // 제목
            Text(
              '저장 완료!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // 설명
            Text(
              '이미지가 갤러리에 성공적으로 저장되었습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // 파일 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '크기: 1080 × 1350',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.folder, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          filename,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 버튼들
            Row(
              children: [
                // 확인 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 성공 다이얼로그 닫기
                      Navigator.of(context).pop(); // 미리보기 다이얼로그 닫기
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 갤러리 보기 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop(); // 성공 다이얼로그 닫기
                      Navigator.of(context).pop(); // 미리보기 다이얼로그 닫기
                      await _openGallery(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.k5LeagueBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '갤러리 보기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 갤러리 열기 기능
  Future<void> _openGallery(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        // Android에서 갤러리 앱 열기
        bool opened = false;

        // 방법 1: 기본 갤러리 앱 열기 (가장 안정적)
        try {
          final Uri galleryUri =
              Uri.parse('content://media/external/images/media');
          opened =
              await launchUrl(galleryUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          print('갤러리 URI 열기 실패: $e');
        }

        // 방법 2: Google Photos 앱 열기
        if (!opened) {
          try {
            final Uri photosUri =
                Uri.parse('market://details?id=com.google.android.apps.photos');
            opened = await launchUrl(photosUri,
                mode: LaunchMode.externalApplication);
          } catch (e) {
            print('Google Photos 열기 실패: $e');
          }
        }

        // 방법 3: 일반적인 이미지 뷰어 열기
        if (!opened) {
          try {
            final Uri imageUri =
                Uri.parse('content://media/external/images/media');
            opened =
                await launchUrl(imageUri, mode: LaunchMode.externalApplication);
          } catch (e) {
            print('이미지 뷰어 열기 실패: $e');
          }
        }

        if (!opened) {
          // 갤러리를 열 수 없는 경우 안내 메시지
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.photo_library, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('갤러리 앱을 직접 실행해주세요'),
                    ),
                  ],
                ),
                backgroundColor: AppColors.k5LeagueBlue,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else if (Platform.isIOS) {
        // iOS에서 Photos 앱 열기
        try {
          final Uri photosUri = Uri.parse('photos-redirect://');
          if (await canLaunchUrl(photosUri)) {
            await launchUrl(photosUri, mode: LaunchMode.externalApplication);
          } else {
            // iOS Photos 앱을 직접 열 수 없는 경우 안내 메시지
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.photo_library, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('사진 앱에서 저장된 이미지를 확인하세요'),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.k5LeagueBlue,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          print('iOS Photos 앱 열기 실패: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.photo_library, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('사진 앱에서 저장된 이미지를 확인하세요'),
                    ),
                  ],
                ),
                backgroundColor: AppColors.k5LeagueBlue,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('갤러리 열기 최종 실패: $e');
      // 갤러리 열기 실패 시 안내 메시지
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('갤러리를 자동으로 열 수 없습니다.\n직접 갤러리 앱을 실행해주세요'),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTemplate = ref.watch(templateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('K5 경기 사진 편집기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('템플릿 초기화'),
                    content: const Text('현재 입력된 모든 내용을 기본 템플릿으로 되돌리시겠습니까?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('취소'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('확인'),
                        onPressed: () {
                          ref
                              .read(matchEditorProvider.notifier)
                              .resetToDefaultTemplate();
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('템플릿이 기본값으로 초기화되었습니다.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
            tooltip: '템플릿 초기화',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _showSavePreviewDialog,
            tooltip: '이미지 저장',
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            // Template selector - 고정된 크기
            const TemplateSelector(),

            // 미리보기 토글 버튼
            InkWell(
              onTap: _togglePreview,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6, // 높이 줄임
                ),
                decoration: BoxDecoration(
                  color: AppColors.k5LeagueBlue.withOpacity(0.1),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.k5LeagueBlue.withOpacity(0.2),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: AppColors.k5LeagueBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '미리보기',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.k5LeagueBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isPreviewExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.k5LeagueBlue,
                    ),
                    const Spacer(),
                    Text(
                      _isPreviewExpanded ? '접기' : '펼치기',
                      style: TextStyle(
                        color: AppColors.k5LeagueBlue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 미리보기 영역 - 개선된 애니메이션으로 변경
            LayoutBuilder(builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              // 정확히 1080x1350 비율 계산
              final displayHeight = availableWidth * (1350 / 1080);

              // 요청사항: 미리보기 표시되는 비율을 15% 정도 줄여...
              final scaledDisplayHeight = displayHeight * 0.85;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isPreviewExpanded ? scaledDisplayHeight : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isPreviewReady && _isPreviewExpanded ? 1.0 : 0.0,
                  child: _isPreviewExpanded
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: 1080 / 1350, // 정확한 비율
                            child: SizedBox(
                              width: 1080,
                              height: 1350,
                              child: PhotoDisplayArea(isCaptureMode: false),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }),

            // TabBar 추가 (복원)
            TabBar(
              controller: _tabController,
              tabs: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 아이콘과 텍스트 중앙 정렬
                  children: [
                    Icon(Icons.sports_soccer, size: 18), // 아이콘 크기 조정 가능
                    SizedBox(width: 4), // 아이콘과 텍스트 간격
                    Text('경기 정보'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 18),
                    SizedBox(width: 4),
                    Text('세부 정보'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.palette, size: 18),
                    SizedBox(width: 4),
                    Text('디자인'),
                  ],
                ),
              ],
              labelColor: AppColors.k5LeagueBlue, // 이전 스타일 유지
              unselectedLabelColor: Colors.grey, // 이전 스타일 유지
              indicatorColor: AppColors.k5LeagueBlue, // 이전 스타일 유지
            ),

            // 탭바 추가 -> Expanded(child: TabBarView(...))
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 경기 정보 탭
                  MatchInfoTab(templateType: selectedTemplate),

                  // 세부 정보 탭
                  const DetailsTab(),

                  // 디자인 탭
                  const DesignTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
