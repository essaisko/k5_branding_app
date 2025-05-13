import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/theme/app_colors.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/features/match_editor/providers/template_provider.dart';

/// Template selector widget to switch between different template types
///
/// Follows Steve Jobs' design philosophy:
/// - Simple, intuitive interface
/// - Visual clarity and feedback
/// - Focused on essential functionality
class TemplateSelector extends ConsumerWidget {
  const TemplateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTemplate = ref.watch(templateProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            '템플릿:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),

          // 템플릿 버튼들을 가로로 나열한 Row
          Expanded(
            child: SizedBox(
              height: 36, // 상하로 짧은 고정 높이
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    TemplateType.values.map((template) {
                      final isSelected = template == selectedTemplate;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildCompactTemplateButton(
                          context,
                          template,
                          isSelected,
                          () =>
                              ref.read(templateProvider.notifier).state =
                                  template,
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 간결한 템플릿 토글 버튼
  Widget _buildCompactTemplateButton(
    BuildContext context,
    TemplateType template,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.grey[100],
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForTemplate(template),
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                template.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns appropriate icon for each template type
  IconData _getIconForTemplate(TemplateType template) {
    switch (template) {
      case TemplateType.matchResult:
        return Icons.sports_soccer;
      case TemplateType.matchSchedule:
        return Icons.calendar_today;
      case TemplateType.lineup:
        return Icons.people;
      default:
        return Icons.image;
    }
  }
}
