import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart'; // 초기값 참조 및 defaultMatchTemplate 사용
import 'dart:developer' as dev;
import 'package:k5_branding_app/core/constants/asset_paths.dart'; // AssetPaths 임포트 추가

// Provider 정의
final teamDetailsProvider =
    NotifierProvider<TeamDetailsNotifier, TeamDetailsState>(() {
  return TeamDetailsNotifier();
});

// 상태 클래스 정의
class TeamDetailsState {
  final String homeTeamName;
  final String awayTeamName;
  final String? homeLogoPath;
  final String? awayLogoPath;
  final int? homeScore;
  final int? awayScore;

  const TeamDetailsState({
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeLogoPath,
    this.awayLogoPath,
    this.homeScore,
    this.awayScore,
  });

  TeamDetailsState copyWith({
    String? homeTeamName,
    String? awayTeamName,
    String? homeLogoPath,
    String? awayLogoPath,
    int? homeScore,
    int? awayScore,
    bool clearHomeLogo = false,
    bool clearAwayLogo = false,
    bool clearHomeScore = false,
    bool clearAwayScore = false,
  }) {
    return TeamDetailsState(
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homeLogoPath: clearHomeLogo ? null : (homeLogoPath ?? this.homeLogoPath),
      awayLogoPath: clearAwayLogo ? null : (awayLogoPath ?? this.awayLogoPath),
      homeScore: clearHomeScore ? null : (homeScore ?? this.homeScore),
      awayScore: clearAwayScore ? null : (awayScore ?? this.awayScore),
    );
  }
}

// Notifier 클래스 정의
class TeamDetailsNotifier extends Notifier<TeamDetailsState> {
  @override
  TeamDetailsState build() {
    // MatchEditorNotifier의 초기 Match 상태를 참조하여 TeamDetailsState 초기화
    final initialMatch = ref.watch(matchEditorProvider);
    return TeamDetailsState(
      homeTeamName: initialMatch.homeTeamName,
      awayTeamName: initialMatch.awayTeamName,
      homeLogoPath: initialMatch.homeLogoPath,
      awayLogoPath: initialMatch.awayLogoPath,
      homeScore: initialMatch.homeScore,
      awayScore: initialMatch.awayScore,
    );
  }

  void resetToDefault(Match defaultMatch) {
    state = TeamDetailsState(
      homeTeamName: defaultMatch.homeTeamName,
      awayTeamName: defaultMatch.awayTeamName,
      homeLogoPath: defaultMatch.homeLogoPath,
      awayLogoPath: defaultMatch.awayLogoPath,
      homeScore: defaultMatch.homeScore,
      awayScore: defaultMatch.awayScore,
    );
    dev.log('TeamDetailsNotifier: 상태가 기본값으로 초기화되었습니다.', name: 'TeamDetails');
  }

  // 홈팀 이름 업데이트
  void updateHomeTeamName(String name) {
    if (state.homeTeamName == name &&
        name == ref.read(matchEditorProvider).homeTeamName) return;
    ref.read(matchEditorProvider.notifier).updateHomeTeamName(name);
  }

  // 원정팀 이름 업데이트
  void updateAwayTeamName(String name) {
    if (state.awayTeamName == name &&
        name == ref.read(matchEditorProvider).awayTeamName) return;
    ref.read(matchEditorProvider.notifier).updateAwayTeamName(name);
  }

  // 홈팀 로고 업데이트
  void updateHomeLogo(String? path) {
    if (state.homeLogoPath == path &&
        path == ref.read(matchEditorProvider).homeLogoPath) return;
    if (path == null) {
      ref
          .read(matchEditorProvider.notifier)
          .updateHomeLogo(AssetPaths.defaultCrest);
    } else {
      ref.read(matchEditorProvider.notifier).updateHomeLogo(path);
    }
  }

  // 원정팀 로고 업데이트
  void updateAwayLogo(String? path) {
    if (state.awayLogoPath == path &&
        path == ref.read(matchEditorProvider).awayLogoPath) return;
    if (path == null) {
      ref
          .read(matchEditorProvider.notifier)
          .updateAwayLogo(AssetPaths.defaultCrest);
    } else {
      ref.read(matchEditorProvider.notifier).updateAwayLogo(path);
    }
  }

  // 홈팀 점수 업데이트
  void updateHomeScore(int? score) {
    if (state.homeScore == score &&
        score == ref.read(matchEditorProvider).homeScore) return;
    ref.read(matchEditorProvider.notifier).updateHomeScore(score);
  }

  // 원정팀 점수 업데이트
  void updateAwayScore(int? score) {
    if (state.awayScore == score &&
        score == ref.read(matchEditorProvider).awayScore) return;
    ref.read(matchEditorProvider.notifier).updateAwayScore(score);
  }
}
