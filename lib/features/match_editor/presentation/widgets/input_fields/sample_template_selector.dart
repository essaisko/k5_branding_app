import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/theme/app_colors.dart';
import 'package:k5_branding_app/features/match_editor/providers/template_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/theme_color_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/design_pattern_provider.dart';

/// Sample template selector widget
/// Allows users to choose from predefined template styles
class SampleTemplateSelector extends ConsumerWidget {
  const SampleTemplateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSample = ref.watch(sampleTemplateProvider);
    final allConfigs = SampleTemplateConfigs.getAllConfigs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목과 아이콘
        Row(
          children: [
            Icon(
              Icons.palette,
              color: AppColors.k5LeagueBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '샘플 템플릿',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 설명 텍스트
        Text(
          '미리 설정된 템플릿 스타일을 선택하여 빠르게 디자인을 적용하세요',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),

        // 그리드 형태의 템플릿 선택기
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: allConfigs.length,
          itemBuilder: (context, index) {
            final config = allConfigs[index];
            final isSelected = config.style == selectedSample;
            return _buildTemplateCard(context, ref, config, isSelected);
          },
        ),

        const SizedBox(height: 16),

        // 선택된 템플릿 정보 카드
        if (selectedSample != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SampleTemplateConfigs.getConfig(selectedSample)
                      .primaryColor
                      .withOpacity(0.1),
                  SampleTemplateConfigs.getConfig(selectedSample)
                      .primaryColor
                      .withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SampleTemplateConfigs.getConfig(selectedSample)
                    .primaryColor
                    .withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: SampleTemplateConfigs.getConfig(selectedSample)
                          .primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '선택된 템플릿: ${SampleTemplateConfigs.getConfig(selectedSample).displayName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: SampleTemplateConfigs.getConfig(selectedSample)
                            .primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  SampleTemplateConfigs.getConfig(selectedSample).description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 템플릿 카드 위젯
  Widget _buildTemplateCard(
    BuildContext context,
    WidgetRef ref,
    SampleTemplateConfig config,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _applySampleTemplate(ref, config.style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    config.primaryColor,
                    config.primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? config.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: config.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                // 색상 미리보기
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : config.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : config.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 템플릿 이름
                Expanded(
                  child: Text(
                    config.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                // 선택 표시 아이콘
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // 패턴 정보
            Text(
              config.patternType == 'none'
                  ? '패턴 없음'
                  : '${config.patternType} 패턴',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 샘플 템플릿 적용
  void _applySampleTemplate(WidgetRef ref, SampleTemplateStyle style) {
    final config = SampleTemplateConfigs.getConfig(style);

    // 샘플 템플릿 선택 상태 업데이트
    ref.read(sampleTemplateProvider.notifier).state = style;

    // 색상 테마 적용
    ref
        .read(teamColorProvider.notifier)
        .setCustomColorForTheme(config.primaryColor);

    // 패턴 적용
    final patternType = _getPatternTypeFromString(config.patternType);
    ref.read(designPatternProvider.notifier).selectPattern(patternType);

    // 패턴 투명도 적용 (패턴이 있는 경우에만)
    if (patternType != DesignPatternType.none) {
      ref
          .read(designPatternProvider.notifier)
          .setPatternOpacity(config.patternOpacity);
    }

    // 기존 스낵바 모두 제거 후 새로운 스낵바 표시
    final scaffoldMessenger = ScaffoldMessenger.of(ref.context);
    scaffoldMessenger.clearSnackBars();

    // 짧은 지연 후 새로운 스낵바 표시
    Future.delayed(const Duration(milliseconds: 100), () {
      if (ref.context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${config.displayName} 템플릿이 적용되었습니다'),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: config.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });
  }

  /// 문자열을 DesignPatternType으로 변환
  DesignPatternType _getPatternTypeFromString(String patternString) {
    switch (patternString.toLowerCase()) {
      case 'diagonal':
        return DesignPatternType.diagonal;
      case 'dots':
        return DesignPatternType.dots;
      case 'image':
        return DesignPatternType.image;
      case 'none':
      default:
        return DesignPatternType.none;
    }
  }
}
