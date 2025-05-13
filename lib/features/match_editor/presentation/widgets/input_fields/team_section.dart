import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/constants/asset_paths.dart';
import 'package:k5_branding_app/core/theme/app_typography.dart';
import 'package:k5_branding_app/core/utils/color_utils.dart';
import 'package:k5_branding_app/domain/entities/team.dart';
import 'package:k5_branding_app/features/match_editor/providers/providers.dart';
import 'dart:developer' as dev;
import 'package:k5_branding_app/features/match_editor/presentation/widgets/shared/compact_logo_button.dart';
import 'package:k5_branding_app/features/match_editor/providers/sample_data_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/team_details_provider.dart';

/// Team section input widget
///
/// Contains:
/// - Team name selection fields
/// - Logo selection
class TeamSection extends ConsumerStatefulWidget {
  const TeamSection({super.key});

  @override
  ConsumerState<TeamSection> createState() => _TeamSectionState();
}

class _TeamSectionState extends ConsumerState<TeamSection> {
  late TextEditingController _homeTeamController;
  late TextEditingController _awayTeamController;

  final FocusNode _homeTeamFocusNode = FocusNode();
  final FocusNode _awayTeamFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialDetails = ref.read(teamDetailsProvider);
    _homeTeamController =
        TextEditingController(text: initialDetails.homeTeamName);
    _awayTeamController =
        TextEditingController(text: initialDetails.awayTeamName);
  }

  @override
  void dispose() {
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    _homeTeamFocusNode.dispose();
    _awayTeamFocusNode.dispose();
    super.dispose();
  }

  void _selectHomeTeam(String teamName) {
    dev.log(
        '[TeamSection] _selectHomeTeam called. Selected teamName: $teamName',
        name: 'TeamSelection');
    final teamDetailsNotifier = ref.read(teamDetailsProvider.notifier);
    final colorNotifier = ref.read(teamColorProvider.notifier);
    final sampleTeams = ref.read(sampleTeamsProvider);

    teamDetailsNotifier.updateHomeTeamName(teamName);
    dev.log('[TeamSection] Home team name updated in provider: $teamName',
        name: 'TeamSelection');

    final selectedTeam = sampleTeams.firstWhere(
      (team) => team.name == teamName,
      orElse: () {
        dev.log(
            '[TeamSection] Home team "$teamName" not found in sampleTeams. Using default.',
            name: 'TeamSelection');
        return Team(
            id: '',
            name: teamName,
            logoPath: AssetPaths.defaultCrest,
            primaryColor: Colors.grey);
      },
    );
    dev.log(
        '[TeamSection] Found selected home team: ${selectedTeam.name}, logo: ${selectedTeam.logoPath}',
        name: 'TeamSelection');

    teamDetailsNotifier.updateHomeLogo(selectedTeam.logoPath);
    dev.log('[TeamSection] Home logo updated. Path: ${selectedTeam.logoPath}',
        name: 'TeamSelection');

    final teamColor = ColorUtils.getColorFromTeamLogo(selectedTeam.logoPath);
    colorNotifier.updateHomeTeamColor(teamColor);
    if (!ref.read(teamColorProvider).isCustomColor) {
      colorNotifier.useCustomTeamColorForTheme(ColorThemeSource.home);
    }
    dev.log('[TeamSection] _selectHomeTeam finished.', name: 'TeamSelection');
  }

  void _selectAwayTeam(String teamName) {
    dev.log(
        '[TeamSection] _selectAwayTeam called. Selected teamName: $teamName',
        name: 'TeamSelection');
    final teamDetailsNotifier = ref.read(teamDetailsProvider.notifier);
    final colorNotifier = ref.read(teamColorProvider.notifier);
    final sampleTeams = ref.read(sampleTeamsProvider);

    teamDetailsNotifier.updateAwayTeamName(teamName);
    dev.log('[TeamSection] Away team name updated in provider: $teamName',
        name: 'TeamSelection');

    final selectedTeam = sampleTeams.firstWhere(
      (team) => team.name == teamName,
      orElse: () {
        dev.log(
            '[TeamSection] Away team "$teamName" not found in sampleTeams. Using default.',
            name: 'TeamSelection');
        return Team(
            id: '',
            name: teamName,
            logoPath: AssetPaths.defaultCrest,
            primaryColor: Colors.grey);
      },
    );
    dev.log(
        '[TeamSection] Found selected away team: ${selectedTeam.name}, logo: ${selectedTeam.logoPath}',
        name: 'TeamSelection');

    teamDetailsNotifier.updateAwayLogo(selectedTeam.logoPath);
    dev.log('[TeamSection] Away logo updated. Path: ${selectedTeam.logoPath}',
        name: 'TeamSelection');

    final teamColor = ColorUtils.getColorFromTeamLogo(selectedTeam.logoPath);
    colorNotifier.updateAwayTeamColor(teamColor);
    if (ref.read(teamColorProvider).colorThemeSource == ColorThemeSource.away) {
      colorNotifier.useCustomTeamColorForTheme(ColorThemeSource.away);
    }
    dev.log('[TeamSection] _selectAwayTeam finished.', name: 'TeamSelection');
  }

  void _updateControllerTextIfNotFocused(
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

  @override
  Widget build(BuildContext context) {
    final teamDetails = ref.watch(teamDetailsProvider);
    final sampleTeams = ref.watch(sampleTeamsProvider);

    _updateControllerTextIfNotFocused(
        _homeTeamController, teamDetails.homeTeamName, _homeTeamFocusNode);
    _updateControllerTextIfNotFocused(
        _awayTeamController, teamDetails.awayTeamName, _awayTeamFocusNode);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('팀 정보', style: AppTypography.heading3.copyWith(fontSize: 20.0)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTeamRow(
                  context: context,
                  isHomeTeam: true,
                  teamNameController: _homeTeamController,
                  teamFocusNode: _homeTeamFocusNode,
                  currentTeamName: teamDetails.homeTeamName,
                  currentLogoPath: teamDetails.homeLogoPath,
                  onTeamSelected: _selectHomeTeam,
                  sampleTeams: sampleTeams,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTeamRow(
                  context: context,
                  isHomeTeam: false,
                  teamNameController: _awayTeamController,
                  teamFocusNode: _awayTeamFocusNode,
                  currentTeamName: teamDetails.awayTeamName,
                  currentLogoPath: teamDetails.awayLogoPath,
                  onTeamSelected: _selectAwayTeam,
                  sampleTeams: sampleTeams,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required BuildContext context,
    required bool isHomeTeam,
    required TextEditingController teamNameController,
    required FocusNode teamFocusNode,
    required String currentTeamName,
    required String? currentLogoPath,
    required ValueChanged<String> onTeamSelected,
    required List<Team> sampleTeams,
  }) {
    final teamDetailsNotifier = ref.read(teamDetailsProvider.notifier);
    final verySmallTextStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11);
    const smallPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Autocomplete<Team>(
            fieldViewBuilder: (BuildContext context,
                TextEditingController fieldTextEditingController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted) {
              if (!teamFocusNode.hasFocus &&
                  teamNameController.text != currentTeamName) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  teamNameController.text = currentTeamName;
                });
              }
              if (!fieldFocusNode.hasFocus &&
                  fieldTextEditingController.text != currentTeamName) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  fieldTextEditingController.text = currentTeamName;
                });
              }

              return TextFormField(
                  controller: teamNameController,
                  focusNode: teamFocusNode,
                  style: verySmallTextStyle,
                  decoration: InputDecoration(
                    labelText: isHomeTeam ? '홈' : '원정',
                    hintText: '팀명',
                    isDense: true,
                    contentPadding: smallPadding,
                    border: const OutlineInputBorder(),
                    suffixIcon: PopupMenuButton<Team>(
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      tooltip: '팀 선택',
                      onSelected: (Team team) {
                        onTeamSelected(team.name);
                        teamFocusNode.unfocus();
                        fieldFocusNode.unfocus();
                      },
                      itemBuilder: (BuildContext context) {
                        return sampleTeams.map((Team team) {
                          return PopupMenuItem<Team>(
                              value: team,
                              child: Row(
                                children: [
                                  Image.asset(
                                    team.logoPath,
                                    width: 24,
                                    height: 24,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(team.name, style: verySmallTextStyle),
                                ],
                              ));
                        }).toList();
                      },
                    ),
                  ),
                  onChanged: (value) {
                    if (isHomeTeam) {
                      teamDetailsNotifier.updateHomeTeamName(value);
                    } else {
                      teamDetailsNotifier.updateAwayTeamName(value);
                    }
                  },
                  onFieldSubmitted: (_) {
                    teamFocusNode.unfocus();
                    fieldFocusNode.unfocus();
                  });
            },
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Team>.empty();
              }
              return sampleTeams.where((Team option) {
                return option.name
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            displayStringForOption: (Team option) => option.name,
            onSelected: (Team selection) {
              onTeamSelected(selection.name);
              teamFocusNode.unfocus();
            },
          ),
        ),
        const SizedBox(width: 4),
        CompactLogoButton(
          currentPath: currentLogoPath ?? AssetPaths.defaultCrest,
          isHomeTeam: isHomeTeam,
          onLogoSelected: (String newLogoPath) {
            if (isHomeTeam) {
              teamDetailsNotifier.updateHomeLogo(newLogoPath);
            } else {
              teamDetailsNotifier.updateAwayLogo(newLogoPath);
            }
          },
          size: 30,
        ),
      ],
    );
  }
}
