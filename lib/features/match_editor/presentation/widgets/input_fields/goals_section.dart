import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/theme/app_colors.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/features/match_editor/providers/providers.dart';
import 'package:k5_branding_app/features/match_editor/providers/goal_scorers_provider.dart';
import 'dart:developer' as dev;
import 'package:uuid/uuid.dart';
import 'package:k5_branding_app/features/match_editor/providers/team_details_provider.dart';

/// Goal scorer management section - 컴팩트한 개별 입력 필드 버전
class GoalsSection extends ConsumerStatefulWidget {
  const GoalsSection({super.key});

  @override
  ConsumerState<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends ConsumerState<GoalsSection> {
  final Uuid _uuid = const Uuid();

  final Map<String, FocusNode> _scorerTimeFocusNodes = {};
  final Map<String, FocusNode> _scorerNameFocusNodes = {};
  final Map<String, TextEditingController> _scorerTimeControllers = {};
  final Map<String, TextEditingController> _scorerNameControllers = {};

  late TextEditingController _homeScoreController;
  late TextEditingController _awayScoreController;
  final FocusNode _homeScoreFocusNode = FocusNode();
  final FocusNode _awayScoreFocusNode = FocusNode();

  String? _lastProcessedScorersString;
  bool _isUpdating = false;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    final initialTeamDetails = ref.read(teamDetailsProvider);
    _homeScoreController = TextEditingController(
        text: initialTeamDetails.homeScore?.toString() ?? '');
    _awayScoreController = TextEditingController(
        text: initialTeamDetails.awayScore?.toString() ?? '');

    // 초기 득점자 목록에 대한 컨트롤러 및 포커스 노드 설정
    final initialScorers = ref.read(matchEditorProvider).scorers;
    for (var scorer in initialScorers) {
      _initControllersAndFocusNodes(scorer);
    }
  }

  @override
  void dispose() {
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _homeScoreFocusNode.dispose();
    _awayScoreFocusNode.dispose();

    for (final focusNode in _scorerTimeFocusNodes.values) {
      focusNode.dispose();
    }
    for (final focusNode in _scorerNameFocusNodes.values) {
      focusNode.dispose();
    }
    for (final controller in _scorerTimeControllers.values) {
      controller.dispose();
    }
    for (final controller in _scorerNameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initControllersAndFocusNodes(ScorerInfo scorer) {
    if (!_scorerTimeControllers.containsKey(scorer.id)) {
      _scorerTimeControllers[scorer.id] =
          TextEditingController(text: scorer.time);
      _scorerTimeFocusNodes[scorer.id] = FocusNode();
      _scorerTimeFocusNodes[scorer.id]?.addListener(() {
        if (!(_scorerTimeFocusNodes[scorer.id]?.hasFocus ?? false)) {
          final controller = _scorerTimeControllers[scorer.id];
          final currentScorer = ref
              .read(matchEditorProvider)
              .scorers
              .firstWhere((s) => s.id == scorer.id, orElse: () => scorer);
          if (controller != null && controller.text != currentScorer.time) {
            dev.log('Time focus lost, updating scorer: ${scorer.id}',
                name: 'GoalScorerFocus');
            _updateScorerInfo(currentScorer.copyWith(time: controller.text));
          }
        }
      });
    }
    if (!_scorerNameControllers.containsKey(scorer.id)) {
      _scorerNameControllers[scorer.id] =
          TextEditingController(text: scorer.name);
      _scorerNameFocusNodes[scorer.id] = FocusNode();
      _scorerNameFocusNodes[scorer.id]?.addListener(() {
        if (!(_scorerNameFocusNodes[scorer.id]?.hasFocus ?? false)) {
          final controller = _scorerNameControllers[scorer.id];
          final currentScorer = ref
              .read(matchEditorProvider)
              .scorers
              .firstWhere((s) => s.id == scorer.id, orElse: () => scorer);
          if (controller != null && controller.text != currentScorer.name) {
            dev.log('Name focus lost, updating scorer: ${scorer.id}',
                name: 'GoalScorerFocus');
            _updateScorerInfo(currentScorer.copyWith(name: controller.text));
          }
        }
      });
    }
  }

  void _updateScoreControllerIfNotFocused(
      TextEditingController controller, String newText, FocusNode focusNode) {
    if (!focusNode.hasFocus && controller.text != newText) {
      final oldSelection = controller.selection;
      controller.text = newText;
      try {
        if (oldSelection.start <= newText.length &&
            oldSelection.end <= newText.length) {
          controller.selection = oldSelection;
        } else {
          controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length));
        }
      } catch (e) {
        controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length));
      }
    }
  }

  void _addNewScorer(bool isHomeTeam) {
    final newScorerId = _uuid.v4();
    final newScorer = ScorerInfo(
      id: newScorerId,
      name: "",
      time: "",
      isHomeTeam: isHomeTeam,
      isOwnGoal: false,
    );
    dev.log(
        'Adding new scorer: ID=$newScorerId, ${isHomeTeam ? "Home" : "Away"}',
        name: 'GoalScorer');
    _initControllersAndFocusNodes(newScorer);

    final matchState = ref.read(matchEditorProvider);
    final updatedScorers = [...matchState.scorers, newScorer];
    ref.read(matchEditorProvider.notifier).updateScorers(updatedScorers);

    Future.microtask(() {
      if (mounted && _scorerNameFocusNodes.containsKey(newScorerId)) {
        dev.log('Requesting focus for new scorer: ID=$newScorerId',
            name: 'GoalScorer');
        // _scorerNameFocusNodes[newScorerId]!.requestFocus(); // 이전: 이름 필드 포커스
        _scorerTimeFocusNodes[newScorerId]!.requestFocus(); // 변경: 시간 필드 포커스
      }
    });
  }

  void _removeScorer(String scorerId) {
    dev.log('Removing scorer: ID=$scorerId', name: 'GoalScorer');
    _scorerTimeControllers[scorerId]?.dispose();
    _scorerNameControllers[scorerId]?.dispose();
    _scorerTimeFocusNodes[scorerId]?.dispose();
    _scorerNameFocusNodes[scorerId]?.dispose();

    _scorerTimeControllers.remove(scorerId);
    _scorerNameControllers.remove(scorerId);
    _scorerTimeFocusNodes.remove(scorerId);
    _scorerNameFocusNodes.remove(scorerId);

    final matchState = ref.read(matchEditorProvider);
    final updatedScorers =
        matchState.scorers.where((scorer) => scorer.id != scorerId).toList();
    ref.read(matchEditorProvider.notifier).updateScorers(updatedScorers);
    dev.log('Scorer removed. Count: ${updatedScorers.length}',
        name: 'GoalScorer');
  }

  void _updateScorerInfo(ScorerInfo updatedScorer) {
    dev.log(
        'Updating scorer info: ID=${updatedScorer.id}, Name=${updatedScorer.name}, Time=${updatedScorer.time}',
        name: 'GoalScorer');
    final matchState = ref.read(matchEditorProvider);
    final updatedScorers = matchState.scorers.map((scorer) {
      return scorer.id == updatedScorer.id ? updatedScorer : scorer;
    }).toList();
    ref.read(matchEditorProvider.notifier).updateScorers(updatedScorers);
  }

  Widget _buildScorerInputRow(BuildContext context, ScorerInfo scorer) {
    _initControllersAndFocusNodes(
        scorer); // Ensure controllers and focus nodes exist

    final timeController = _scorerTimeControllers[scorer.id]!;
    final nameController = _scorerNameControllers[scorer.id]!;
    final timeFocusNode = _scorerTimeFocusNodes[scorer.id]!;
    final nameFocusNode = _scorerNameFocusNodes[scorer.id]!;

    // Update controller text if it differs from scorer state and not focused
    if (!timeFocusNode.hasFocus && timeController.text != scorer.time) {
      timeController.text = scorer.time;
    }
    if (!nameFocusNode.hasFocus && nameController.text != scorer.name) {
      nameController.text = scorer.name;
    }

    final smallTextStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12);
    final borderColor = Colors.grey.shade400;
    final focusedBorderColor = Colors.grey.shade600;

    return Row(
      key: ValueKey(scorer.id), // Add ValueKey for better widget identification
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          child: TextField(
            controller: timeController,
            focusNode: timeFocusNode,
            style: smallTextStyle,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '분',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: focusedBorderColor),
              ),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              if (value != scorer.time) {
                _updateScorerInfo(scorer.copyWith(time: value));
              }
              FocusScope.of(context).requestFocus(nameFocusNode);
            },
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: nameController,
            focusNode: nameFocusNode,
            style: smallTextStyle,
            decoration: InputDecoration(
              hintText: '득점선수',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: focusedBorderColor),
              ),
            ),
            onSubmitted: (value) {
              if (value != scorer.name) {
                _updateScorerInfo(scorer.copyWith(name: value));
              }
              final matchState = ref.read(matchEditorProvider);
              final allScorers = matchState.scorers;
              final currentTeamScorersForInputOrder = allScorers
                  .where((s) => s.isHomeTeam == scorer.isHomeTeam)
                  .toList();

              int currentIndex = currentTeamScorersForInputOrder
                  .indexWhere((s) => s.id == scorer.id);

              if (currentIndex != -1 &&
                  currentIndex < currentTeamScorersForInputOrder.length - 1) {
                final nextScorer =
                    currentTeamScorersForInputOrder[currentIndex + 1];
                if (_scorerTimeFocusNodes.containsKey(nextScorer.id)) {
                  FocusScope.of(context)
                      .requestFocus(_scorerTimeFocusNodes[nextScorer.id]);
                }
              } else {
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 20,
          child: Checkbox(
            value: scorer.isOwnGoal,
            onChanged: (value) {
              if (value != null) {
                _updateScorerInfo(scorer.copyWith(isOwnGoal: value));
              }
            },
            activeColor: Colors.grey.shade700,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            splashRadius: 12,
          ),
        ),
        SizedBox(
          width: 20,
          child: IconButton(
            icon:
                Icon(Icons.remove_circle, size: 14, color: Colors.red.shade700),
            tooltip: '삭제',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeScorer(scorer.id),
          ),
        ),
      ],
    );
  }

  Widget _buildScorerPreviewItem(ScorerInfo scorer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            size: 14,
            color: scorer.isOwnGoal ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              scorer.time.isNotEmpty
                  ? "${scorer.time}' ${scorer.name}${scorer.isOwnGoal ? ' (자책골)' : ''}"
                  : "${scorer.name}${scorer.isOwnGoal ? ' (자책골)' : ''}",
              style: TextStyle(
                fontSize: 12,
                color: scorer.isOwnGoal ? Colors.red : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScorersSection(BuildContext context, bool isHomeTeam,
      List<ScorerInfo> teamScorers, String teamDefaultName) {
    final matchState = ref.watch(matchEditorProvider);
    final teamDisplayName = isHomeTeam
        ? (matchState.homeTeamName.isNotEmpty
            ? matchState.homeTeamName
            : teamDefaultName)
        : (matchState.awayTeamName.isNotEmpty
            ? matchState.awayTeamName
            : teamDefaultName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: 16,
                    color: isHomeTeam
                        ? Colors.blueGrey.shade700
                        : Colors.blueGrey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$teamDisplayName',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Text(
                '자책골',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        if (teamScorers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('득점자 없음',
                style: TextStyle(color: Colors.grey, fontSize: 10)),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: teamScorers.length,
          itemBuilder: (context, index) {
            final scorer = teamScorers[index];
            // _initControllersAndFocusNodes(scorer); // Ensure controllers are ready for existing items too
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildScorerInputRow(context, scorer),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchEditorProvider);
    final teamDetails = ref.watch(teamDetailsProvider);

    _updateScoreControllerIfNotFocused(_homeScoreController,
        teamDetails.homeScore?.toString() ?? '', _homeScoreFocusNode);
    _updateScoreControllerIfNotFocused(_awayScoreController,
        teamDetails.awayScore?.toString() ?? '', _awayScoreFocusNode);

    final allScorers = matchState.scorers;
    // Ensure all scorers have their controllers and focus nodes initialized or updated
    // This is important if scorers list is updated from outside (e.g. initial load)
    for (var scorer in allScorers) {
      _initControllersAndFocusNodes(scorer);
    }

    final homeScorersForInput = allScorers.where((s) => s.isHomeTeam).toList();
    final awayScorersForInput = allScorers.where((s) => !s.isHomeTeam).toList();

    final displayableScorers = allScorers.where((scorer) {
      final isValidName = scorer.name.isNotEmpty &&
          !scorer.name.startsWith('delete_') &&
          !RegExp(r'^\d+$').hasMatch(scorer.name);
      return isValidName;
    }).toList();

    final homeScorersForDisplay =
        displayableScorers.where((s) => s.isHomeTeam).toList();
    final awayScorersForDisplay =
        displayableScorers.where((s) => !s.isHomeTeam).toList();

    homeScorersForDisplay.sort((a, b) =>
        (int.tryParse(a.time.replaceAll('+', '')) ?? 0)
            .compareTo(int.tryParse(b.time.replaceAll('+', '')) ?? 0));
    awayScorersForDisplay.sort((a, b) =>
        (int.tryParse(a.time.replaceAll('+', '')) ?? 0)
            .compareTo(int.tryParse(b.time.replaceAll('+', '')) ?? 0));

    final scoreHintStyle = TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500);
    const smallPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0);

    final greyBorderColor = Colors.grey.shade400;
    final greyFocusColor = Colors.grey.shade600;
    final greyBgLight = Colors.grey.shade50;
    final greyBgDark = Colors.grey.shade100;
    final greyBorderLight = Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '득점 정보',
          style: AppTypography.heading3
              .copyWith(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                child: TextFormField(
                  controller: _homeScoreController,
                  focusNode: _homeScoreFocusNode,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: scoreHintStyle,
                    isDense: true,
                    contentPadding: smallPadding,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: greyBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: greyFocusColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    final score = int.tryParse(value);
                    ref
                        .read(teamDetailsProvider.notifier)
                        .updateHomeScore(score);
                  },
                  onFieldSubmitted: (_) => _homeScoreFocusNode.unfocus(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '-',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700),
                ),
              ),
              SizedBox(
                width: 50,
                child: TextFormField(
                  controller: _awayScoreController,
                  focusNode: _awayScoreFocusNode,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: scoreHintStyle,
                    isDense: true,
                    contentPadding: smallPadding,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: greyBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: greyFocusColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    final score = int.tryParse(value);
                    ref
                        .read(teamDetailsProvider.notifier)
                        .updateAwayScore(score);
                  },
                  onFieldSubmitted: (_) => _awayScoreFocusNode.unfocus(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text('홈팀 득점자 추가', style: TextStyle(fontSize: 12)),
              onPressed: () => _addNewScorer(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: greyBgDark,
                foregroundColor: Colors.grey.shade800,
                minimumSize: Size(140, 30),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                elevation: 0,
                side: BorderSide(color: greyBorderLight),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text('원정팀 득점자 추가', style: TextStyle(fontSize: 12)),
              onPressed: () => _addNewScorer(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: greyBgDark,
                foregroundColor: Colors.grey.shade800,
                minimumSize: Size(140, 30),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                elevation: 0,
                side: BorderSide(color: greyBorderLight),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: greyBgLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: greyBorderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildTeamScorersSection(
                      context, true, homeScorersForInput, "홈팀"),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: greyBgLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: greyBorderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildTeamScorersSection(
                      context, false, awayScorersForInput, "원정팀"),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
