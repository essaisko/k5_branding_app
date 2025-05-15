import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart'; // 주석 처리 - 문제 있음
import 'package:open_filex/open_filex.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/core/theme/app_colors.dart';
import 'package:k5_branding_app/features/match_editor/providers/providers.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/photo_display_area.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/template_selector.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/match_info_tab.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/details_tab.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/design_tab.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

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
  bool _isPreviewExpanded = true;
  bool _isPreviewReady = true;
  bool _isSaving = false;
  final GlobalKey _captureKey = GlobalKey();
  bool _isCaptureModeEnabled = false;

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
    // 저장 중인 경우 중복 실행 방지
    if (_isSaving) {
      print("이미 저장 중입니다. 중복 실행 방지");
      return;
    }

    // 미리보기가 닫혀있는 경우 열기
    if (!_isPreviewExpanded) {
      _togglePreview();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 새 스낵바 표시 전 기존 스낵바 모두 제거
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

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

    if (!mounted) return;

    // 저장 플래그 설정
    _isSaving = true;
    print("저장 시작: _isSaving = true");

    // 로딩 표시를 위한 작은 오버레이
    OverlayEntry? loadingOverlay;
    if (mounted) {
      loadingOverlay = OverlayEntry(
        builder: (context) => Positioned(
          right: 16,
          bottom: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '저장 중...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      print("로딩 오버레이 표시");
      Overlay.of(context).insert(loadingOverlay);
    }

    try {
      print("이미지 캡처 시작");

      // 직접 만든 위젯으로 캡처 (오프스크린 렌더링)
      final captureWidget = SizedBox(
        width: 1080,
        height: 1350,
        child: PhotoDisplayArea(isCaptureMode: true),
      );

      // 1. 오프스크린 렌더링을 위한 설정
      final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
      final BuildContext? currentCtx = context;

      if (currentCtx == null) {
        throw Exception('컨텍스트가 유효하지 않습니다');
      }

      // 2. 오프스크린 렌더링 파이프라인 설정
      final RenderView renderView = WidgetsBinding.instance.renderView;
      final devicePixelRatio = MediaQuery.of(currentCtx).devicePixelRatio;
      print("디바이스 픽셀 비율: $devicePixelRatio");

      // 3. 렌더 객체 트리 생성
      final RenderObjectWidget renderObjectWidget = RepaintBoundary(
        child: captureWidget,
      );

      // 4. 오버레이 엔트리를 사용하여 위젯 렌더링
      final GlobalKey overlayKey = GlobalKey();
      final overlayEntry = OverlayEntry(
        builder: (context) => Opacity(
          opacity: 0.0, // 완전히 투명하게
          child: RepaintBoundary(
            key: overlayKey,
            child: captureWidget,
          ),
        ),
      );

      Overlay.of(currentCtx).insert(overlayEntry);

      // 5. 렌더링이 완료될 때까지 대기
      await Future.delayed(const Duration(milliseconds: 500));

      // 6. 이미지 캡처 수행
      final ui.Image? capturedImage = await _captureWidgetToImage(
        overlayKey.currentContext,
        devicePixelRatio: 1.0, // 정확히 1080x1350픽셀을 위한 설정
        targetSize: const ui.Size(1080, 1350), // 목표 크기 명시
      );

      // 7. 오버레이 제거
      overlayEntry.remove();

      if (capturedImage == null) {
        throw Exception('이미지 캡처에 실패했습니다');
      }

      print("캡처된 이미지 크기: ${capturedImage.width}x${capturedImage.height}");

      // 이미지 크기 확인
      if (capturedImage.width != 1080 || capturedImage.height != 1350) {
        print(
            "경고: 이미지 크기가 1080x1350이 아닙니다. 실제: ${capturedImage.width}x${capturedImage.height}");

        // 옵션: 이미지 리사이징 수행 (리사이징 로직이 필요하면 추가해야 함)
        // 현재는 원본 그대로 저장
      }

      // 이미지 데이터 변환
      final byteData =
          await capturedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('이미지 데이터 생성 실패');
      }
      print("이미지 데이터 변환 성공");

      final pngBytes = byteData.buffer.asUint8List();
      print("PNG 데이터 생성 성공, 크기: ${pngBytes.length} 바이트");

      // 갤러리에 저장
      final filename = 'k5_match_${DateTime.now().millisecondsSinceEpoch}.png';
      print("갤러리에 저장 시도: $filename");

      final imageEntity = await PhotoManager.editor.saveImage(
        pngBytes,
        filename: filename,
      );
      print("갤러리 저장 결과: ${imageEntity != null ? '성공' : '실패'}");

      // 로딩 오버레이 제거
      if (loadingOverlay != null && loadingOverlay.mounted) {
        print("로딩 오버레이 제거");
        loadingOverlay.remove();
        loadingOverlay = null;
      }

      // 결과 표시
      if (mounted) {
        if (imageEntity != null) {
          print("이미지 엔티티 저장 성공, 파일 정보 가져오기 시도");
          imageEntity.file.then((file) {
            if (file != null && mounted) {
              final filePath = file.path;
              print("저장된 파일 경로: $filePath");
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('이미지가 갤러리에 저장되었습니다'),
                action: SnackBarAction(
                  label: '보기',
                  onPressed: () {
                    OpenFilex.open(filePath);
                  },
                ),
              ));
            } else if (mounted) {
              print("파일은 null이지만 이미지는 저장됨");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('이미지가 갤러리에 저장되었습니다')),
              );
            }
          }).catchError((error) {
            print('파일 경로 얻기 오류: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('이미지가 갤러리에 저장되었습니다')),
              );
            }
          });
        } else {
          print("이미지 엔티티가 null, 저장 실패");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 저장에 실패했습니다')),
          );
        }
      }
    } catch (e) {
      print('Error capturing or saving image: $e');
      print('Stack trace: ${StackTrace.current}');

      // 캡처 모드 초기화 (에러 발생 시에도)
      setState(() {
        _isCaptureModeEnabled = false;
      });

      // 로딩 오버레이 제거
      if (loadingOverlay != null && loadingOverlay.mounted) {
        print("오류 발생으로 로딩 오버레이 제거");
        loadingOverlay.remove();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: ${e.toString()}')),
        );
      }
    } finally {
      print("저장 프로세스 종료: _isSaving = false");
      _isSaving = false;
    }
  }

  // 위젯을 이미지로 캡처하는 헬퍼 메소드
  Future<ui.Image?> _captureWidgetToImage(
    BuildContext? context, {
    double devicePixelRatio = 1.0,
    ui.Size? targetSize,
  }) async {
    if (context == null) {
      print("컨텍스트가 null, 캡처할 수 없음");
      return null;
    }

    try {
      // 렌더 객체 찾기
      final RenderRepaintBoundary? boundary =
          context.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        print("렌더 객체를 찾을 수 없음");
        return null;
      }

      // 렌더링 완료 대기
      for (int i = 0; i < 20; i++) {
        if (!boundary.debugNeedsPaint) {
          break;
        }
        print("렌더링 대기 중... ($i/20)");
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 이미지 캡처
      print("이미지 캡처 시도 (pixelRatio: $devicePixelRatio)");
      final ui.Image image =
          await boundary.toImage(pixelRatio: devicePixelRatio);
      print("캡처 성공: ${image.width}x${image.height}");

      // 크기 확인
      if (targetSize != null &&
          (image.width != targetSize.width.toInt() ||
              image.height != targetSize.height.toInt())) {
        print("주의: 캡처된 이미지 크기가 목표 크기와 다릅니다.");
        print(
            "목표: ${targetSize.width.toInt()}x${targetSize.height.toInt()}, 실제: ${image.width}x${image.height}");
      }

      return image;
    } catch (e) {
      print("이미지 캡처 중 오류: $e");
      return null;
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
        child: Stack(
          children: [
            Column(
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
                      opacity:
                          _isPreviewReady && _isPreviewExpanded ? 1.0 : 0.0,
                      child: RepaintBoundary(
                        key: _captureKey,
                        child: _isPreviewExpanded
                            ? Center(
                                child: AspectRatio(
                                  aspectRatio: 1080 / 1350, // 정확한 비율
                                  child: SizedBox(
                                    width: 1080,
                                    height: 1350,
                                    child: PhotoDisplayArea(
                                        isCaptureMode: _isCaptureModeEnabled),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                }),

                // TabBar 추가 (복원)
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // 아이콘과 텍스트 중앙 정렬
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
          ],
        ),
      ),
    );
  }
}
