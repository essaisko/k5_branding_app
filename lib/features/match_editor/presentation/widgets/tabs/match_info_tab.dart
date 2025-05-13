import 'package:flutter/material.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/input_fields/goals_section.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/input_fields/team_section.dart';
import 'package:k5_branding_app/features/match_editor/providers/template_provider.dart'; // TemplateType 사용을 위해 추가

class MatchInfoTab extends StatelessWidget {
  final TemplateType templateType;

  const MatchInfoTab({super.key, required this.templateType});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            // 팀 정보 섹션 (팀명, 점수, 로고) - 최상단으로 이동
            TeamSection(),
            SizedBox(height: 16),

            // 득점자 섹션 - 두 번째로 이동
            GoalsSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
