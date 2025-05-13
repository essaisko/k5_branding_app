import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/features/match_editor/providers/focus_manager_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart';

/// 리그 이름 샘플 데이터 프로바이더
final leagueNameSamplesProvider = Provider<List<String>>((ref) {
  return [
    'K5 LEAGUE',
    'K LEAGUE',
    'K3 LEAGUE',
    'NATIONAL LEAGUE',
  ];
});

/// 리그 이름 편집 위젯
///
/// 리그 이름 입력 필드와 샘플 선택 기능 제공
class LeagueNameSection extends ConsumerStatefulWidget {
  const LeagueNameSection({Key? key}) : super(key: key);

  @override
  ConsumerState<LeagueNameSection> createState() => _LeagueNameSectionState();
}

class _LeagueNameSectionState extends ConsumerState<LeagueNameSection> {
  late TextEditingController _leagueNameController;

  @override
  void initState() {
    super.initState();
    _leagueNameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateControllerFromState();
  }

  void _updateControllerFromState() {
    final match = ref.read(matchEditorProvider);
    if (_leagueNameController.text != match.leagueName) {
      _leagueNameController.text = match.leagueName;
    }
  }

  void _selectLeagueName(String name) {
    ref.read(matchEditorProvider.notifier).updateLeagueName(name);
    _leagueNameController.text = name;
  }

  @override
  void dispose() {
    _leagueNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchEditorProvider);
    final sampleLeagues = ref.watch(leagueNameSamplesProvider);
    final focusNodes = ref.read(focusNodesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '리그 정보',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 리그 이름 입력 필드
            Expanded(
              flex: 3,
              child: TextField(
                controller: _leagueNameController,
                focusNode: focusNodes.getFocusNode('leagueName'),
                decoration: const InputDecoration(
                  labelText: '리그 이름',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  ref
                      .read(matchEditorProvider.notifier)
                      .updateLeagueName(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            // 샘플 선택 드롭다운
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: PopupMenuButton<String>(
                tooltip: '샘플 리그 선택',
                icon: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_soccer, size: 16),
                    SizedBox(width: 4),
                    Text('샘플'),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
                padding: EdgeInsets.zero,
                onSelected: _selectLeagueName,
                itemBuilder: (context) {
                  return sampleLeagues.map((name) {
                    return PopupMenuItem<String>(
                      value: name,
                      child: Text(name, style: AppTypography.bodyMedium),
                    );
                  }).toList();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
