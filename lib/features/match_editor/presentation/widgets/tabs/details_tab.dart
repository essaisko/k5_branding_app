import 'package:flutter/material.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/input_fields/match_details_section.dart';

class DetailsTab extends StatelessWidget {
  const DetailsTab({super.key});

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
            // 경기 세부 정보 섹션
            MatchDetailsSection(),
            SizedBox(height: 16),
            // LeagueNameSection은 MatchDetailsSection에 포함되어 있으므로 여기서는 제거
          ],
        ),
      ),
    );
  }
}
