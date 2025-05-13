import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/core/theme/app_colors.dart';
import 'package:k5_branding_app/features/match_editor/providers/providers.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/photo_display_area.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/template_selector.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/match_info_tab.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/details_tab.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/design_tab.dart';

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
  final GlobalKey _previewKey = GlobalKey();
  bool _isPreviewExpanded = true; // 미리보기 영역 표시 여부 상태
  bool _isPreviewReady = true; // 미리보기 로딩 상태

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

  Future<void> _captureAndSaveImage() async {
    // Request photo permissions
    final permissionStatus = await PhotoManager.requestPermissionExtend();
    if (!permissionStatus.hasAccess) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('갤러리 접근 권한이 필요합니다')));
      }
      return;
    }

    try {
      // Capture the widget as an image
      final boundary = _previewKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('이미지 데이터 생성 실패');
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Save image to gallery
      final imageEntity = await PhotoManager.editor.saveImage(
        pngBytes,
        filename: 'k5_match_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (mounted && imageEntity != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지가 갤러리에 저장되었습니다')));
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 저장에 실패했습니다')));
      }
    } catch (e) {
      print('Error capturing or saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: ${e.toString()}')));
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
            onPressed: _captureAndSaveImage,
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
              final maxHeight = constraints.maxWidth * 1.0; // 가로 세로 비율 1:1
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isPreviewExpanded ? maxHeight : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isPreviewReady && _isPreviewExpanded ? 1.0 : 0.0,
                  child: RepaintBoundary(
                    key: _previewKey,
                    child: _isPreviewExpanded
                        ? const PhotoDisplayArea()
                        : const SizedBox.shrink(),
                  ),
                ),
              );
            }),

            // 탭바 추가
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.sports_soccer),
                  text: '경기 정보',
                ),
                Tab(
                  icon: Icon(Icons.calendar_today),
                  text: '세부 정보',
                ),
                Tab(
                  icon: Icon(Icons.palette),
                  text: '디자인',
                ),
              ],
              labelColor: AppColors.k5LeagueBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.k5LeagueBlue,
            ),

            // Scrollable input area with TabBarView
            Expanded(
              child: Container(
                color: Colors.grey[50],
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
            ),
          ],
        ),
      ),
    );
  }
}
