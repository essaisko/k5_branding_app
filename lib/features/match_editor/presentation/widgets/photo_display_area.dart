import 'package:flutter/material.dart';
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
import 'dart:io';

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
                      double maxHeight = constraints.maxHeight * 0.95;

                      // 1080x1350 비율 유지하면서 최대 크기 맞추기
                      double aspectRatio = 1080 / 1350;

                      double displayWidth = maxWidth;
                      double displayHeight = displayWidth / aspectRatio;

                      if (displayHeight > maxHeight) {
                        displayHeight = maxHeight;
                        displayWidth = displayHeight * aspectRatio;
                      }

                      return SizedBox(
                        width: displayWidth,
                        height: displayHeight,
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
              ],
            ),
          ),
        ),
      ),
    );
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

  /// 득점자 열 위젯 생성
  Widget _buildScorersColumn(List<ScorerInfo> scorers, Color textColor) {
    if (scorers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          '득점 없음',
          style: TextStyle(
            fontSize: 11,
            color: textColor.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // 시간 순서대로 정렬
    final sortedScorers = List<ScorerInfo>.from(scorers);
    sortedScorers.sort((a, b) {
      final aTime = int.tryParse(a.time) ?? 0;
      final bTime = int.tryParse(b.time) ?? 0;
      return aTime.compareTo(bTime);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sortedScorers.map((scorer) => _buildScorerItem(scorer, textColor)),
      ],
    );
  }
}
