import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/design_pattern_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/theme_color_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/sample_data_provider.dart';
import 'package:k5_branding_app/domain/entities/match.dart' as domain_match;
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/match_info_tab.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/details_tab.dart';
import 'package:k5_branding_app/features/match_editor/presentation/widgets/tabs/design_tab.dart';
import 'package:k5_branding_app/features/match_editor/providers/template_provider.dart';

class MatchEditorPage extends ConsumerWidget {
  const MatchEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domain_match.Match defaultMatchForReset = emptyMatchTemplate;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('경기 편집기'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                try {
                  ref.read(matchEditorProvider.notifier).saveMatch();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('경기가 저장되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('경기 저장 실패: $e')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '템플릿 초기화',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('템플릿 초기화'),
                    content: const Text('정말로 모든 설정을 기본 템플릿 값으로 초기화하시겠습니까?'),
                    actions: [
                      TextButton(
                        child: const Text('취소'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: const Text('초기화'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref
                      .read(matchEditorProvider.notifier)
                      .resetToDefaultTemplate();
                  ref.read(designPatternProvider.notifier).resetToDefault();

                  final sampleTeams = ref.read(sampleTeamsProvider);
                  ref
                      .read(teamColorProvider.notifier)
                      .resetToDefault(defaultMatchForReset, sampleTeams);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('템플릿이 기본값으로 초기화되었습니다.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '경기 정보'),
              Tab(text: '세부 정보'),
              Tab(text: '디자인'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const MatchInfoTab(templateType: TemplateType.matchResult),
            const DetailsTab(),
            DesignTab(),
          ],
        ),
      ),
    );
  }
}
