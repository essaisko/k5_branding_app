import 'dart:async'; // For Future
import 'dart:io'; // For File
import 'dart:typed_data'; // For Uint8List
import 'dart:ui'
    as ui; // For ui.Image, ui.PictureRecorder, ui.Canvas, ui.ImageByteFormat, ui.TextDirection
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // For RepaintBoundary, RenderBox, RenderRepaintBoundary
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/constants/asset_paths.dart';
import 'package:k5_branding_app/core/theme/app_colors.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/template_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/theme_color_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/design_pattern_provider.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/patterns/pattern_painters.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that displays the match information visually
///
/// This is the visual representation of the match data that
/// will be captured as an image.
class PhotoDisplayArea extends ConsumerWidget {
  final bool isCaptureMode;
  // 캡처용 정적 키 추가
  static final GlobalKey previewDialogKey = GlobalKey();

  const PhotoDisplayArea({super.key, this.isCaptureMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTemplate = ref.watch(templateProvider);

    // Build proper frame for preview area
    return Container(
      margin: isCaptureMode ? EdgeInsets.zero : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            isCaptureMode ? BorderRadius.zero : BorderRadius.circular(12),
        boxShadow: isCaptureMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
              ],
        border: isCaptureMode
            ? null
            : Border.all(
                color: AppColors.k5LeagueBlue.withOpacity(0.5),
                width: 2,
              ),
      ),
      // 인스타그램 세로형 비율로 변경 (1080x1350 = 4:5)
      child: GestureDetector(
        onTap: isCaptureMode
            ? null
            : () => _showFullScreenPreview(context, ref, selectedTemplate),
        child: AspectRatio(
          // 정확히 1080:1350 = 0.8 비율 적용
          aspectRatio: 1080 / 1350,
          child: Stack(
            children: [
              // Main content
              ClipRRect(
                borderRadius: isCaptureMode
                    ? BorderRadius.zero
                    : BorderRadius.circular(10),
                child: _buildTemplateContent(context, ref, selectedTemplate),
              ),

              // 확대 아이콘 표시
              if (!isCaptureMode)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 전체화면 미리보기 표시
  void _showFullScreenPreview(
      BuildContext context, WidgetRef ref, TemplateType selectedTemplate) {
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
                          key: previewDialogKey,
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
                          onPressed: () => _captureAndSaveImage(context, ref),
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
  Future<void> _captureAndSaveImage(BuildContext context, WidgetRef ref) async {
    try {
      // 권한 확인
      final permissionStatus = await PhotoManager.requestPermissionExtend();
      if (!permissionStatus.hasAccess) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('갤러리 접근 권한이 필요합니다')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
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

      // RepaintBoundary에서 이미지 캡처
      final boundary = previewDialogKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('캡처할 위젯을 찾을 수 없습니다');
      }

      // 렌더링 완료 대기
      await Future.delayed(const Duration(milliseconds: 300));

      // 1080x1350 크기로 정확히 캡처
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);

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

      // 갤러리에 저장
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
              onPressed: () => _captureAndSaveImage(context, ref),
            ),
          ),
        );
      }
    }
  }

  /// Builds content based on selected template
  Widget _buildTemplateContent(
    BuildContext context,
    WidgetRef ref,
    TemplateType selectedTemplate,
  ) {
    // Build appropriate template based on selection
    switch (selectedTemplate) {
      case TemplateType.matchResult:
        return _buildMatchResultTemplate(context, ref);
      case TemplateType.matchSchedule:
        return _buildMatchScheduleTemplate(context);
      case TemplateType.lineup:
        return _buildLineupTemplate(context);
      default:
        return Container(
          alignment: Alignment.center,
          color: Colors.grey[200],
          child: const Text('템플릿을 선택해주세요'),
        );
    }
  }

  /// Builds the match result template display with Instagram-style design
  Widget _buildMatchResultTemplate(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchEditorProvider);
    final colorState = ref.watch(teamColorProvider);
    final patternState = ref.watch(designPatternProvider);

    // 디버깅용 로그
    print(
        '현재 선택된 패턴: ${patternState.selectedPattern.name}, 투명도: ${patternState.patternOpacity}');

    // 선택된 색상으로 배경 색상 설정
    final themeColor = colorState.selectedColor;

    // 선택된 색상의 밝기에 따라 텍스트 색상 결정
    final isLightColor = themeColor.computeLuminance() > 0.5;
    final textColor = isLightColor ? Colors.black : Colors.white;
    final contrastColor = isLightColor ? Colors.black : Colors.white;

    // 홈팀과 원정팀 로고 및 이름
    final homeTeamName = match.homeTeamName.isEmpty ? '홈팀' : match.homeTeamName;
    final awayTeamName =
        match.awayTeamName.isEmpty ? '원정팀' : match.awayTeamName;
    final homeLogo = match.homeLogoPath.isEmpty
        ? AssetPaths.defaultCrest
        : match.homeLogoPath;
    final awayLogo = match.awayLogoPath.isEmpty
        ? AssetPaths.defaultCrest
        : match.awayLogoPath;

    // 점수 설정
    final homeScore = match.homeScore ?? 0;
    final awayScore = match.awayScore ?? 0;

    // 경기 일자 형식 지정
    String formattedDate = '';
    if (match.matchDateTime != null) {
      final dateTime = match.matchDateTime!;
      // 요일 구하기 (영어 -> 한국어)
      final days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
      final dayOfWeek = days[dateTime.weekday - 1];
      formattedDate =
          '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} $dayOfWeek ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 기본 날짜 표시
      formattedDate = '경기 일자를 입력해주세요';
    }

    // 경기장 정보
    final venueText = match.venueLocation?.isNotEmpty == true
        ? match.venueLocation!
        : '경기장을 입력해주세요';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: themeColor,
        child: Stack(
          children: [
            // 배경 패턴 - 선택된 패턴에 따라 표시
            if (patternState.selectedPattern != DesignPatternType.none)
              SizedBox.expand(
                child: Opacity(
                  opacity: patternState.patternOpacity,
                  child: _buildSelectedPattern(patternState, contrastColor),
                ),
              ),

            // 스크롤 가능한 컨텐츠
            SingleChildScrollView(
              child: Column(
                children: [
                  // 상단 헤더 - 리그 로고 및 라운드 정보
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // '경기 결과' 텍스트
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: contrastColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: contrastColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '경기 결과',
                            style: TextStyle(
                              color: contrastColor,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // K리그 로고 및 라운드 정보를 오른쪽에 배치
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: contrastColor.withOpacity(0.3),
                                  width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sports_soccer,
                                    color: contrastColor, size: 10),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    match.leagueName,
                                    style: TextStyle(
                                      color: contrastColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (match.roundInfo != null &&
                                    match.roundInfo!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: contrastColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'R${match.roundInfo}',
                                      style: TextStyle(
                                        color: contrastColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 경기 일자 및 장소
                  Container(
                    margin: const EdgeInsets.only(bottom: 10, top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: contrastColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: contrastColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '|',
                              style: TextStyle(
                                  color: contrastColor.withOpacity(0.5)),
                            ),
                          ),
                          Text(
                            venueText,
                            style: TextStyle(
                              color: contrastColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 점수 및 로고 영역 - 위로 이동하고 크기 축소
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 점수 표시 중앙 배치
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: contrastColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '$homeScore',
                                style: TextStyle(
                                  color: contrastColor,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    color: contrastColor.withOpacity(0.6),
                                    fontSize: 40,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '$awayScore',
                                style: TextStyle(
                                  color: contrastColor,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 로고 및 팀명 별도 배치
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                    child: Row(
                      children: [
                        // 홈팀 로고와 이름
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: _buildTeamLogo(homeLogo),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  homeTeamName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: contrastColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // VS 텍스트 추가
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 그림자 효과
                              Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black.withOpacity(0.3),
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.5),
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              // 메인 텍스트
                              Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: contrastColor,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.5,
                                  height: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 원정팀 로고와 이름
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: _buildTeamLogo(awayLogo),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  awayTeamName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: contrastColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 득점자 정보 - 넓은 공간 확보
                  if (match.goalScorers != null &&
                          match.goalScorers!.isNotEmpty ||
                      match.scorers.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        color: contrastColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 득점자 헤더
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '경기기록',
                                style: TextStyle(
                                  color: contrastColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // 득점자 테이블
                          _buildScorersTable(
                            homeTeamName: homeTeamName,
                            awayTeamName: awayTeamName,
                            homeScorers: match.scorers
                                .where((s) => s.isHomeTeam)
                                .toList(),
                            awayScorers: match.scorers
                                .where((s) => !s.isHomeTeam)
                                .toList(),
                            textColor: contrastColor,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the match schedule template (placeholder)
  Widget _buildMatchScheduleTemplate(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text('경기 일정 템플릿 (개발 중)', style: AppTypography.bodyLarge),
      ),
    );
  }

  /// Builds the lineup template (placeholder)
  Widget _buildLineupTemplate(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text('라인업 템플릿 (개발 중)', style: AppTypography.bodyLarge),
      ),
    );
  }

  /// 팀 로고 이미지 위젯 생성
  Widget _buildTeamLogo(String logoPath) {
    Widget imageWidget;
    if (logoPath.startsWith('http')) {
      imageWidget = Image.network(
        logoPath,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) =>
            const Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
      );
    } else if (logoPath.startsWith('/') || logoPath.startsWith('file://')) {
      imageWidget = Image.file(
        File(logoPath),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) =>
            const Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
      );
    } else {
      imageWidget = Image.asset(
        logoPath,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) =>
            const Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
      );
    }

    return ClipOval(
      child: imageWidget,
    );
  }

  /// 득점자 테이블 위젯 생성
  Widget _buildScorersTable({
    required String homeTeamName,
    required String awayTeamName,
    required List<ScorerInfo> homeScorers,
    required List<ScorerInfo> awayScorers,
    required Color textColor,
  }) {
    // 시간 순서대로 득점자 정렬
    final sortedHomeScorers = List<ScorerInfo>.from(homeScorers)
      ..sort((a, b) =>
          (int.tryParse(a.time) ?? 0).compareTo(int.tryParse(b.time) ?? 0));

    final sortedAwayScorers = List<ScorerInfo>.from(awayScorers)
      ..sort((a, b) =>
          (int.tryParse(a.time) ?? 0).compareTo(int.tryParse(b.time) ?? 0));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 홈팀 득점자 목록
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 팀 이름 헤더
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    homeTeamName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),

                // 득점자 목록 (7명 이상인 경우 두 열로 분리)
                if (sortedHomeScorers.isEmpty)
                  Text(
                    '득점 없음',
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (sortedHomeScorers.length <= 7)
                  // 7명 이하인 경우 한 열로 표시
                  Column(
                    children: sortedHomeScorers
                        .map((scorer) => _buildScorerItem(scorer, textColor))
                        .toList(),
                  )
                else
                  // 7명 초과인 경우 두 열로 분리
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 왼쪽 열 (첫 7명)
                      Expanded(
                        child: Column(
                          children: sortedHomeScorers
                              .take(7)
                              .map((scorer) =>
                                  _buildScorerItem(scorer, textColor))
                              .toList(),
                        ),
                      ),
                      // 오른쪽 열 (나머지)
                      Expanded(
                        child: Column(
                          children: sortedHomeScorers
                              .skip(7)
                              .map((scorer) =>
                                  _buildScorerItem(scorer, textColor))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 구분선
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: textColor.withOpacity(0.2),
          ),

          // 원정팀 득점자 목록
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 팀 이름 헤더
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    awayTeamName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),

                // 득점자 목록 (7명 이상인 경우 두 열로 분리)
                if (sortedAwayScorers.isEmpty)
                  Text(
                    '득점 없음',
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (sortedAwayScorers.length <= 7)
                  // 7명 이하인 경우 한 열로 표시
                  Column(
                    children: sortedAwayScorers
                        .map((scorer) => _buildScorerItem(scorer, textColor))
                        .toList(),
                  )
                else
                  // 7명 초과인 경우 두 열로 분리
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 왼쪽 열 (첫 7명)
                      Expanded(
                        child: Column(
                          children: sortedAwayScorers
                              .take(7)
                              .map((scorer) =>
                                  _buildScorerItem(scorer, textColor))
                              .toList(),
                        ),
                      ),
                      // 오른쪽 열 (나머지)
                      Expanded(
                        child: Column(
                          children: sortedAwayScorers
                              .skip(7)
                              .map((scorer) =>
                                  _buildScorerItem(scorer, textColor))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 득점자 개별 아이템 위젯 (재사용 가능)
  Widget _buildScorerItem(ScorerInfo scorer, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 시간과 이름만 표시 (아이콘 제거)
              Text(
                "${scorer.time}'",
                style: TextStyle(
                  color: scorer.isOwnGoal ? Colors.red : textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                scorer.name,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 선택된 패턴에 따라 배경 위젯 반환
  Widget _buildSelectedPattern(DesignPatternState patternState, Color color) {
    switch (patternState.selectedPattern) {
      case DesignPatternType.diagonal:
        return CustomPaint(
          painter: DiagonalPatternPainter(
            lineColor: color,
            strokeWidth: 1.0,
            gapWidth: 40,
          ),
          isComplex: true,
          willChange: false,
          size: Size.infinite,
        );
      case DesignPatternType.dots:
        return CustomPaint(
          painter: DotsPatternPainter(
            dotColor: color,
            dotSize: 2.5,
            spacing: 20,
          ),
          isComplex: true,
          willChange: false,
          size: Size.infinite,
        );
      case DesignPatternType.image:
        // 이미지 배경 처리
        if (patternState.isCustomImage &&
            patternState.customImageFile != null) {
          // 커스텀 이미지 사용 시 안전한 처리
          return _safeLoadFileImage(patternState.customImageFile!, color);
        } else if (patternState.selectedSampleImage != null) {
          // 샘플 이미지 사용 시 안전한 처리
          return _safeLoadAssetImage(
              patternState.selectedSampleImage!.path, color);
        }
        // 이미지가 없는 경우 색상 배경 반환
        return Container(color: color.withOpacity(0.1));
      case DesignPatternType.none:
      default:
        return Container(); // 패턴 없음
    }
  }

  /// 파일 이미지 안전하게 로드
  Widget _safeLoadFileImage(File file, Color color) {
    if (!file.existsSync()) {
      // 파일이 존재하지 않는 경우
      return _buildImageErrorWidget(color, '이미지 파일을 찾을 수 없습니다');
    }

    try {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('이미지 로딩 오류: $error');
          return _buildImageErrorWidget(color, '이미지를 불러올 수 없습니다');
        },
      );
    } catch (e) {
      print('이미지 로딩 시도 중 오류: $e');
      return _buildImageErrorWidget(color, '이미지 처리 중 오류가 발생했습니다');
    }
  }

  /// 에셋 이미지 안전하게 로드
  Widget _safeLoadAssetImage(String path, Color color) {
    try {
      // 경로가 비어있거나 null인 경우 처리
      if (path.isEmpty) {
        print('에셋 이미지 경로가 비어있음');
        return _buildImageErrorWidget(color, '이미지 경로가 유효하지 않습니다');
      }

      // 경로가 assets로 시작하는지 확인
      if (!path.startsWith('assets/')) {
        print('유효하지 않은 에셋 경로: $path');
        return _buildImageErrorWidget(color, '유효하지 않은 이미지 경로입니다');
      }

      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('샘플 이미지 로딩 오류: $error ($path)');
          return _buildImageErrorWidget(color, '샘플 이미지를 불러올 수 없습니다');
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          // 이미지가 로드되지 않으면 로딩 인디케이터 표시
          if (frame == null) {
            return Container(
              color: color.withOpacity(0.1),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(color.withOpacity(0.5)),
                ),
              ),
            );
          }
          // 이미지가 로드되면 정상 표시
          return child;
        },
      );
    } catch (e) {
      print('샘플 이미지 로딩 시도 중 오류: $e (경로: $path)');
      return _buildImageErrorWidget(color, '샘플 이미지 처리 중 오류가 발생했습니다');
    }
  }

  /// 이미지 오류 표시 위젯
  Widget _buildImageErrorWidget(Color color, String message) {
    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              color: color.withOpacity(0.3),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
}
