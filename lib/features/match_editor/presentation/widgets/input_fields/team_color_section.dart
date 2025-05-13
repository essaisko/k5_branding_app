import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/theme_color_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/design_pattern_provider.dart';

/// 팀 컬러 선택 섹션 - 컴팩트 버전
///
/// 홈팀, 원정팀의 색상을 선택하고 커스텀 색상을 설정할 수 있는 위젯
class TeamColorSection extends ConsumerStatefulWidget {
  const TeamColorSection({super.key});

  @override
  ConsumerState<TeamColorSection> createState() => _TeamColorSectionState();
}

class _TeamColorSectionState extends ConsumerState<TeamColorSection> {
  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchEditorProvider);
    final colorState = ref.watch(teamColorProvider);
    final colorNotifier = ref.read(teamColorProvider.notifier);
    final patternState = ref.watch(designPatternProvider);
    final patternNotifier = ref.read(designPatternProvider.notifier);

    // 팀 이름이 비어있을 경우 기본값 설정
    final homeTeamNameText =
        match.homeTeamName.isNotEmpty ? match.homeTeamName : '홈팀';
    final awayTeamNameText =
        match.awayTeamName.isNotEmpty ? match.awayTeamName : '원정팀';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더와 색상 선택 버튼을 가로로 배치
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '디자인 색상',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            // 커스텀 색상 버튼만 분리하여 더 작게 표시
            _CustomColorPickerButton(
              colorState: colorState,
              colorNotifier: colorNotifier,
              showPickerCallback: _showCustomColorPicker,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 팀 색상 선택 옵션 (홈팀, 원정팀, 커스텀)
        // ToggleButtons 또는 Row와 버튼 조합으로 구현
        LayoutBuilder(
          builder: (context, constraints) {
            // 화면 너비에 따라 버튼 크기 동적 조절
            double buttonWidth =
                (constraints.maxWidth - 16) / 3; // 버튼 3개, 간격 2개 (8*2)
            if (buttonWidth < 90) buttonWidth = 90; // 최소 너비 살짝 줄임

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TeamColorOptionButton(
                  label: homeTeamNameText,
                  color: colorState.homeTeamColor,
                  isSelected:
                      colorState.colorThemeSource == ColorThemeSource.home,
                  onTap: () => colorNotifier
                      .useCustomTeamColorForTheme(ColorThemeSource.home),
                  buttonWidth: buttonWidth,
                ),
                _TeamColorOptionButton(
                  label: awayTeamNameText,
                  color: colorState.awayTeamColor,
                  isSelected:
                      colorState.colorThemeSource == ColorThemeSource.away,
                  onTap: () => colorNotifier
                      .useCustomTeamColorForTheme(ColorThemeSource.away),
                  buttonWidth: buttonWidth,
                ),
                _TeamColorOptionButton(
                  label: '커스텀',
                  color: colorState.colorThemeSource == ColorThemeSource.custom
                      ? colorState.selectedColor
                      : Colors.grey.shade400,
                  isSelected:
                      colorState.colorThemeSource == ColorThemeSource.custom,
                  onTap: () => _showCustomColorPicker(
                      context, colorNotifier, colorState.selectedColor),
                  buttonWidth: buttonWidth,
                  isCustomButton: true,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // 패턴 투명도 조절 슬라이더
        if (patternState.selectedPattern != DesignPatternType.none)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '패턴 투명도: ${(patternState.patternOpacity * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Slider(
                value: patternState.patternOpacity,
                min: 0.05,
                max: 0.5,
                divisions: 9,
                label: '${(patternState.patternOpacity * 100).toInt()}%',
                onChanged: (value) {
                  patternNotifier.setPatternOpacity(value);
                },
              ),
            ],
          ),
      ],
    );
  }

  /// 커스텀 색상 선택기 다이얼로그 표시 (Notifier 직접 사용)
  Future<void> _showCustomColorPicker(BuildContext context,
      TeamColorNotifier colorNotifier, Color initialColor) async {
    Color pickerColor = initialColor;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('커스텀 색상 선택'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) {
                      setState(() {
                        pickerColor = color;
                      });
                    },
                    colorPickerWidth: 300.0,
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: true,
                    displayThumbColor: true,
                    paletteType: PaletteType.hsvWithHue,
                    labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex],
                    pickerAreaBorderRadius:
                        const BorderRadius.all(Radius.circular(2.0)),
                    hexInputBar: true,
                    showLabel: true, // 레이블 표시 추가
                    // heading: Text('색상 선택',
                    //     style: Theme.of(context).textTheme.titleMedium),
                    // subheading: Text('채도 및 명도 조절',
                    //     style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              );
            }),
          ),
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
                colorNotifier.setCustomColorForTheme(pickerColor);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// 새로운 private 위젯
class _TeamColorOptionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final double buttonWidth;
  final bool isCustomButton;

  const _TeamColorOptionButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.buttonWidth,
    this.isCustomButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColorForUnselectedCustom = Colors.grey.shade600;
    final Color iconColorForSelectedCustom = Colors.white;
    final Color iconColorForTeam = Colors.white;

    Color currentIconColor = isCustomButton
        ? (isSelected
            ? iconColorForSelectedCustom
            : iconColorForUnselectedCustom)
        : iconColorForTeam;

    bool showEditIcon = isCustomButton && isSelected;
    bool showColorLensIcon = isCustomButton && !isSelected;

    return SizedBox(
      width: buttonWidth,
      height: 60, // 버튼 높이 고정
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8), // 좀 더 둥글게
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isCustomButton && color.opacity > 0.0
                      ? color.withOpacity(0.85)
                      : color.withOpacity(0.15))
                  : Colors.grey.shade100, // 비선택시 더 밝은 회색
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? (isCustomButton && color.opacity > 0.0
                        ? color
                        : color.withOpacity(0.7))
                    : Colors.grey.shade300, // 비선택시 더 연한 테두리
                width: isSelected ? 2 : 1, // 선택시 테두리 강화
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCustomButton
                        ? (isSelected
                            ? color
                            : Colors
                                .transparent) // 커스텀+선택 시 실제 색, 아니면 아이콘 배경 없음
                        : color, // 팀 버튼은 항상 팀 색상
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isCustomButton
                            ? (isSelected
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade400)
                            : Colors.white.withOpacity(0.7),
                        width: 1.5),
                  ),
                  child: showEditIcon
                      ? Icon(Icons.edit, color: currentIconColor, size: 12)
                      : (showColorLensIcon
                          ? Icon(Icons.color_lens,
                              color: currentIconColor, size: 12)
                          : null),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11, // 폰트 크기 살짝 줄임
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? (isCustomButton && color.opacity > 0.0
                            ? (color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white)
                            : Theme.of(context)
                                .primaryColor) // 일반 선택은 테마 주요 색상으로 강조
                        : Colors.grey.shade700, // 비선택시 더 어두운 회색
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 새로운 private 위젯
class _CustomColorPickerButton extends StatelessWidget {
  final TeamColorState colorState;
  final TeamColorNotifier colorNotifier;
  final Future<void> Function(BuildContext, TeamColorNotifier, Color)
      showPickerCallback;

  const _CustomColorPickerButton({
    required this.colorState,
    required this.colorNotifier,
    required this.showPickerCallback,
  });

  @override
  Widget build(BuildContext context) {
    bool isCurrentlyCustom =
        colorState.colorThemeSource == ColorThemeSource.custom;
    Color displayColor =
        isCurrentlyCustom ? colorState.selectedColor : Colors.grey.shade400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showPickerCallback(
            context, colorNotifier, colorState.selectedColor),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 패딩 조정
          decoration: BoxDecoration(
            color: isCurrentlyCustom
                ? displayColor.withOpacity(0.15)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCurrentlyCustom ? displayColor : Colors.grey.shade300,
              width: isCurrentlyCustom ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.7), width: 1)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.palette_outlined,
                  size: 16,
                  color: isCurrentlyCustom
                      ? displayColor
                      : Colors.grey.shade700), // 아이콘 변경 및 색상 조정
              const SizedBox(width: 4),
              Text('색상 편집',
                  style: TextStyle(
                      fontSize: 12,
                      color: isCurrentlyCustom
                          ? displayColor
                          : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}
