import 'package:flutter/material.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/input_fields/design_pattern_section.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/input_fields/team_color_section.dart';

class DesignTab extends StatelessWidget {
  const DesignTab({super.key});

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
            // 팀 색상 설정 섹션
            TeamColorSection(),
            SizedBox(height: 16),

            // 디자인 패턴 섹션
            Text(
              '디자인 패턴 설정',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            DesignPatternSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
