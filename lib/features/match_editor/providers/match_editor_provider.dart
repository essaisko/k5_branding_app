import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/constants/asset_paths.dart';
import 'package:k5_branding_app/data/repositories/match_repository_impl.dart';
import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/domain/entities/team.dart';
import 'package:k5_branding_app/domain/usecases/get_match_details.dart';
import 'package:k5_branding_app/domain/usecases/update_match.dart';
import 'package:k5_branding_app/features/match_editor/providers/design_pattern_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/theme_color_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/sample_data_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/goal_scorers_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/team_details_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import 'dart:async';

final _uuidForDefaults = Uuid();

// 화려한 기본 템플릿 값 (참고용으로 남겨둘 수 있음)
Match get populatedDefaultMatchTemplate {
  const defaultHomeTeamName = 'K5 드림팀 FC';
  const defaultAwayTeamName = '챌린저스 유나이티드';
  return Match(
    id: _uuidForDefaults.v4(),
    homeTeamName: defaultHomeTeamName,
    awayTeamName: defaultAwayTeamName,
    homeLogoPath: AssetPaths.defaultCrest,
    awayLogoPath: AssetPaths.defaultCrest,
    homeScore: 3,
    awayScore: 2,
    matchDateTime: DateTime.now().add(const Duration(days: 7)),
    venueLocation: 'K5 판타지 스타디움',
    roundInfo: 'GRAND FINAL',
    leagueName: 'K5 슈퍼 챔피언스 리그 2025',
    goalScorers:
        "$defaultHomeTeamName: 10' 마법사킴, 25' 판타지박 (PK), 77' 레전드리\\n$defaultAwayTeamName: 30' 슈퍼스타최, 60' 원더골이",
    scorers: [
      ScorerInfo(
          id: _uuidForDefaults.v4(),
          isHomeTeam: true,
          time: '10',
          name: '마법사킴'),
      ScorerInfo(
          id: _uuidForDefaults.v4(),
          isHomeTeam: true,
          time: '25',
          name: '판타지박 (PK)'),
      ScorerInfo(
          id: _uuidForDefaults.v4(),
          isHomeTeam: true,
          time: '77',
          name: '레전드리'),
      ScorerInfo(
          id: _uuidForDefaults.v4(),
          isHomeTeam: false,
          time: '30',
          name: '슈퍼스타최'),
      ScorerInfo(
          id: _uuidForDefaults.v4(),
          isHomeTeam: false,
          time: '60',
          name: '원더골이'),
    ],
  );
}

// 사용자가 요청한 완전히 비어있는 기본 템플릿
Match get emptyMatchTemplate {
  return Match(
    id: _uuidForDefaults.v4(), // 새 ID는 유지
    homeTeamName: '', // 빈 값
    awayTeamName: '', // 빈 값
    homeLogoPath: '', // 로고 없음 -> 빈 문자열로 임시 처리 (원래는 String?이어야 함)
    awayLogoPath: '', // 로고 없음 -> 빈 문자열로 임시 처리 (원래는 String?이어야 함)
    homeScore: null, // 점수 없음
    awayScore: null, // 점수 없음
    matchDateTime: null, // 현재 시간 또는 null (여기서는 현재 시간)
    venueLocation: '', // 빈 값
    roundInfo: '', // 빈 값
    leagueName: '', // 빈 값
    goalScorers: '', // 빈 값
    scorers: [], // 빈 리스트
  );
}

/// Provider for the current match being edited
///
/// This follows the state management pattern with Riverpod:
/// - State is immutable
/// - State is modified through a notifier
/// - Clear separation between UI and business logic
final matchEditorProvider = NotifierProvider<MatchEditorNotifier, Match>(() {
  return MatchEditorNotifier();
});

/// Notifier for match editor state
class MatchEditorNotifier extends Notifier<Match> {
  late final GetMatchDetails _getMatchDetails;
  late final UpdateMatch _updateMatch;
  static const _uuid = Uuid();

  // 성능 최적화를 위한 캐싱 변수 - REMOVED
  // String? _lastGoalScorersProcessed;
  bool _updateInProgress = false;
  DateTime? _lastUpdateTime;

  // 디바운싱을 위한 최소 시간 간격 (밀리초)
  static const _minUpdateInterval = 100;

  @override
  Match build() {
    // Initialize use cases with repository
    final repository = ref.watch(matchRepositoryProvider);
    _getMatchDetails = GetMatchDetails(repository);
    _updateMatch = UpdateMatch(repository);

    final match = _getMatchDetails.getCurrentEditingMatch();
    Match updatedMatch = match;

    if ((updatedMatch.goalScorers?.isNotEmpty ?? false) &&
        updatedMatch.scorers.isEmpty) {
      updatedMatch = _parseGoalScorersString(updatedMatch);
    }

    // MatchEditorNotifier 초기화 후 GoalScorersNotifier를 Match의 scorers로 초기화
    Future.microtask(() {
      ref
          .read(goalScorersProvider.notifier)
          .resetToDefault(updatedMatch.scorers);
      dev.log(
          'MatchEditorNotifier: GoalScorersProvider state initialized via microtask with ${updatedMatch.scorers.length} scorers after parsing.',
          name: 'MatchEditor');
    });

    return updatedMatch;
  }

  /// 문자열 형식의 득점자 정보를 파싱하여 ScorerInfo 객체 리스트로 변환
  Match _parseGoalScorersString(Match matchToParse) {
    try {
      final goalScorersText = matchToParse.goalScorers;
      dev.log('득점자 문자열 파싱 시작: [$goalScorersText]', name: 'MatchEditor');

      if (goalScorersText == null || goalScorersText.isEmpty) {
        // 득점자 문자열이 비어있으면, scorers 리스트도 비워야 함
        if (matchToParse.scorers.isNotEmpty) {
          dev.log('득점자 문자열이 비어있어 빈 리스트로 초기화', name: 'MatchEditor');
          return matchToParse.copyWith(scorers: []);
        }
        dev.log('득점자 문자열이 비어있고 이미 scorers가 비어있음', name: 'MatchEditor');
        return matchToParse;
      }

      final List<ScorerInfo> parsedScorers = [];
      final lines = goalScorersText.split('\n');
      dev.log('파싱할 라인 수: ${lines.length}', name: 'MatchEditor');

      for (final line in lines) {
        dev.log('라인 파싱: [$line]', name: 'MatchEditor');
        final teamSplit = line.split(':');
        if (teamSplit.length != 2) {
          dev.log('팀 구분이 없음, 건너뜀: $line', name: 'MatchEditor');
          continue;
        }

        final teamName = teamSplit[0].trim();
        final scorersText = teamSplit[1].trim();
        dev.log('팀명: [$teamName], 득점자 텍스트: [$scorersText]',
            name: 'MatchEditor');

        final isHomeTeam = teamName == matchToParse.homeTeamName ||
            (matchToParse.homeTeamName.isEmpty &&
                teamName == '홈팀'); // 홈팀 이름이 비었을 경우 '홈팀' 키워드 사용

        dev.log(
            'isHomeTeam: $isHomeTeam (현재 홈팀명: ${matchToParse.homeTeamName})',
            name: 'MatchEditor');

        if (scorersText.isEmpty) {
          dev.log('득점자 텍스트가 비어있음, 건너뜀', name: 'MatchEditor');
          continue;
        }

        final scorerItems = scorersText.split(',');
        dev.log('득점자 항목 수: ${scorerItems.length}', name: 'MatchEditor');

        for (final item in scorerItems) {
          final trimmedItem = item.trim();
          if (trimmedItem.isEmpty) {
            dev.log('빈 득점자 항목, 건너뜀', name: 'MatchEditor');
            continue;
          }

          dev.log('득점자 항목 파싱: [$trimmedItem]', name: 'MatchEditor');

          // 정규식 패턴을 완화하여 다양한 형식을 지원하도록 수정
          final timeNameRegex =
              RegExp(r"(\d+(?:\+\d+)?)\'?\s+(.+?)(\s*\(자책골\))?$");
          final regexMatch = timeNameRegex.firstMatch(trimmedItem);

          if (regexMatch != null) {
            final time = regexMatch.group(1) ?? '';
            final name = regexMatch.group(2)?.trim() ?? '';
            final isOwnGoal = regexMatch.group(3) != null;

            dev.log('파싱 결과 - 시간: [$time], 이름: [$name], 자책골: $isOwnGoal',
                name: 'MatchEditor');

            if (time.isNotEmpty && name.isNotEmpty) {
              parsedScorers.add(ScorerInfo(
                id: _uuid.v4(),
                isHomeTeam: isHomeTeam,
                time: time,
                name: name,
                isOwnGoal: isOwnGoal,
              ));
              dev.log('ScorerInfo 객체 추가됨', name: 'MatchEditor');
            } else {
              dev.log('시간 또는 이름이 비어있어 추가하지 않음', name: 'MatchEditor');
            }
          } else {
            // 득점자 항목에 시간 정보가 없는 경우에도 추가
            dev.log('정규식 매치 실패, 임의로 득점자 추가: [$trimmedItem]',
                name: 'MatchEditor');
            parsedScorers.add(ScorerInfo(
              id: _uuid.v4(),
              isHomeTeam: isHomeTeam,
              time: '',
              name: trimmedItem,
              isOwnGoal: false,
            ));
          }
        }
      }

      dev.log('파싱 완료: ${parsedScorers.length}개의 득점자 정보 추가됨',
          name: 'MatchEditor');
      // 파싱된 결과로 scorers 리스트를 업데이트한 새로운 Match 객체 반환
      return matchToParse.copyWith(scorers: parsedScorers);
    } catch (e, stackTrace) {
      dev.log('득점자 문자열 파싱 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
      return matchToParse.copyWith(scorers: []); // 오류 발생 시 빈 리스트로 초기화
    }
  }

  /// 득점자 문자열 직접 업데이트 및 파싱
  /// IMPORTANT: This method should primarily be used for initial loading or explicit external string updates.
  /// UI updates from GoalsSection should use updateScorers(List<ScorerInfo>).
  void updateGoalScorersDirectly(String text) {
    // This check might still be useful if this method is called repeatedly with the same string externally
    if (state.goalScorers == text) {
      dev.log('득점자 문자열이 동일하여 업데이트 무시 (updateGoalScorersDirectly): $text',
          name: 'MatchEditor');
      return;
    }

    dev.log('득점자 문자열 직접 업데이트 시작 (updateGoalScorersDirectly): [$text]',
        name: 'MatchEditor');
    Match tempState = state.copyWith(goalScorers: text);
    dev.log('goalScorers 업데이트 완료 (updateGoalScorersDirectly). 이제 파싱 시작',
        name: 'MatchEditor');

    final beforeCount = tempState.scorers.length;
    tempState =
        _parseGoalScorersString(tempState); // Parse the new string into scorers
    final afterCount = tempState.scorers.length;

    // Now, update the actual state
    state = tempState;

    dev.log(
        '파싱 완료 (updateGoalScorersDirectly) - 득점자 수 변경: $beforeCount → $afterCount',
        name: 'MatchEditor');

    _updateMatch.updateCurrentEditingMatch(state);

    // Update GoalScorersProvider with the newly parsed scorers
    ref.read(goalScorersProvider.notifier).resetToDefault(state.scorers);

    dev.log(
        'ID 확인 (updateGoalScorersDirectly): ${state.scorers.map((s) => s.id).join(", ")}',
        name: 'MatchEditor');
    dev.log(
        '득점자 문자열 직접 업데이트 완료 (updateGoalScorersDirectly). 총 득점자 수: ${state.scorers.length}',
        name: 'MatchEditor');
  }

  /// 전체 매치 업데이트 디바운싱 확인
  bool _shouldDebounceUpdate() {
    final now = DateTime.now();

    // 이미 업데이트 중이거나 마지막 업데이트 후 최소 간격이 지나지 않은 경우
    if (_updateInProgress ||
        (_lastUpdateTime != null &&
            now.difference(_lastUpdateTime!).inMilliseconds <
                _minUpdateInterval)) {
      return true;
    }

    _updateInProgress = true;
    _lastUpdateTime = now;
    return false;
  }

  /// 업데이트 완료 표시
  void _markUpdateComplete() {
    _updateInProgress = false;
  }

  /// 홈팀 이름 업데이트
  void updateHomeTeamName(String name) {
    if (state.homeTeamName == name) return;
    if (_shouldDebounceUpdate()) return;

    try {
      state = state.copyWith(homeTeamName: name);
      _updateMatch.updateHomeTeamName(name);
    } catch (e, stackTrace) {
      dev.log('홈팀 이름 업데이트 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
    } finally {
      _markUpdateComplete();
    }
  }

  /// 원정팀 이름 업데이트
  void updateAwayTeamName(String name) {
    if (state.awayTeamName == name) return;
    if (_shouldDebounceUpdate()) return;

    try {
      state = state.copyWith(awayTeamName: name);
      _updateMatch.updateAwayTeamName(name);
    } catch (e, stackTrace) {
      dev.log('원정팀 이름 업데이트 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
    } finally {
      _markUpdateComplete();
    }
  }

  // 내부 로고 업데이트 헬퍼 메소드
  void _updateLogo(String path, bool isHomeTeam) {
    if (isHomeTeam) {
      if (state.homeLogoPath == path) return;
      state = state.copyWith(homeLogoPath: path);
      _updateMatch.updateHomeLogo(path);
      dev.log(
          '[MatchEditorNotifier] Home logo updated to: $path. Current state logo: ${state.homeLogoPath}',
          name: 'MatchEditor');
    } else {
      if (state.awayLogoPath == path) return;
      state = state.copyWith(awayLogoPath: path);
      _updateMatch.updateAwayLogo(path);
      dev.log(
          '[MatchEditorNotifier] Away logo updated to: $path. Current state logo: ${state.awayLogoPath}',
          name: 'MatchEditor');
    }
  }

  /// 홈팀 로고 업데이트
  void updateHomeLogo(String path) {
    _updateLogo(path, true);
  }

  /// 원정팀 로고 업데이트
  void updateAwayLogo(String path) {
    _updateLogo(path, false);
  }

  /// 홈팀 점수 업데이트
  void updateHomeScore(int? score) {
    if (state.homeScore == score) return;
    if (_shouldDebounceUpdate()) return;

    try {
      state = state.copyWith(
        homeScore: score,
        clearHomeScore: score == null,
      );
      _updateMatch.updateHomeScore(score);
    } catch (e, stackTrace) {
      dev.log('홈팀 점수 업데이트 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
    } finally {
      _markUpdateComplete();
    }
  }

  /// 원정팀 점수 업데이트
  void updateAwayScore(int? score) {
    if (state.awayScore == score) return;
    if (_shouldDebounceUpdate()) return;

    try {
      state = state.copyWith(
        awayScore: score,
        clearAwayScore: score == null,
      );
      _updateMatch.updateAwayScore(score);
    } catch (e, stackTrace) {
      dev.log('원정팀 점수 업데이트 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
    } finally {
      _markUpdateComplete();
    }
  }

  /// 경기 일시 업데이트
  void updateMatchDateTime(DateTime dateTime) {
    if (state.matchDateTime == dateTime) return;
    if (_shouldDebounceUpdate()) return;

    try {
      state = state.copyWith(matchDateTime: dateTime);
      _updateCurrentEditingMatch();
    } catch (e, stackTrace) {
      dev.log('경기 일시 업데이트 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
    } finally {
      _markUpdateComplete();
    }
  }

  /// 경기장 위치 업데이트
  void updateVenueLocation(String location) {
    if (state.venueLocation == location) return;
    if (_shouldDebounceUpdate()) return;

    try {
      state = state.copyWith(venueLocation: location);
      _updateCurrentEditingMatch();
    } catch (e, stackTrace) {
      dev.log('경기장 위치 업데이트 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
    } finally {
      _markUpdateComplete();
    }
  }

  /// 라운드 정보 업데이트
  void updateRoundInfo(String roundInfo) {
    if (state.roundInfo == roundInfo) return;
    if (_shouldDebounceUpdate()) return;

    try {
      state = state.copyWith(roundInfo: roundInfo);
      _updateCurrentEditingMatch();
    } catch (e, stackTrace) {
      dev.log('라운드 정보 업데이트 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
    } finally {
      _markUpdateComplete();
    }
  }

  /// 리그 이름 업데이트
  void updateLeagueName(String leagueName) {
    if (state.leagueName == leagueName) return;
    if (_shouldDebounceUpdate()) return;

    try {
      state = state.copyWith(leagueName: leagueName);
      _updateCurrentEditingMatch();
    } catch (e, stackTrace) {
      dev.log('리그 이름 업데이트 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
    } finally {
      _markUpdateComplete();
    }
  }

  /// 현재 편집 중인 매치 정보 업데이트
  void _updateCurrentEditingMatch() {
    try {
      _updateMatch.updateCurrentEditingMatch(state);
    } catch (e, stackTrace) {
      dev.log('현재 편집 중인 경기 업데이트 오류: $e', name: 'MatchEditor');
      dev.log('스택 트레이스: $stackTrace', name: 'MatchEditor');
    }
  }

  /// 경기 정보 저장
  void saveMatch() {
    dev.log('매치 저장 시도', name: 'MatchEditor');
    // GoalScorersNotifier에서 최종 득점자 목록을 가져와 문자열로 변환 후 state에 반영
    final currentScorers = ref.read(goalScorersProvider);
    final goalScorersString = _generateGoalScorersString(
        currentScorers, state.homeTeamName, state.awayTeamName);

    // TeamDetailsNotifier에서 최신 팀 정보를 가져와 state에 반영
    final currentTeamDetails = ref.read(teamDetailsProvider);

    state = state.copyWith(
      goalScorers: goalScorersString,
      scorers: currentScorers, // Scorers 리스트도 동기화
      homeTeamName: currentTeamDetails.homeTeamName,
      awayTeamName: currentTeamDetails.awayTeamName,
      homeLogoPath: currentTeamDetails.homeLogoPath,
      awayLogoPath: currentTeamDetails.awayLogoPath,
      homeScore: currentTeamDetails.homeScore,
      awayScore: currentTeamDetails.awayScore,
    );

    _updateMatch.updateCurrentEditingMatch(state);
    dev.log('매치 저장 완료: $state', name: 'MatchEditor');
  }

  /// 템플릿을 화려한 기본값으로 초기화합니다.
  /// 이 메소드는 Match 상태와 GoalScorers 상태만 초기화합니다.
  /// DesignPatternProvider 및 TeamColorProvider 초기화는 UI 레이어에서 별도로 처리합니다.
  void resetToDefaultTemplate() {
    final defaultTemplate = emptyMatchTemplate; // 여기를 emptyMatchTemplate으로 변경
    dev.log('템플릿 초기화 시작 (빈 템플릿 사용): MatchEditorNotifier', name: 'MatchEditor');

    // 각 Provider의 resetToDefault 메소드 호출
    ref.read(teamDetailsProvider.notifier).resetToDefault(defaultTemplate);
    ref
        .read(goalScorersProvider.notifier)
        .resetToDefault(defaultTemplate.scorers); // 빈 리스트가 전달됨
    ref.read(designPatternProvider.notifier).resetToDefault(); // 자체 기본값 사용
    ref.read(teamColorProvider.notifier).resetToDefault(
        defaultTemplate, ref.read(sampleTeamsProvider)); // 빈 Match 전달

    state = defaultTemplate.copyWith();

    // _lastGoalScorersProcessed = null; // REMOVED
    _updateMatch.updateCurrentEditingMatch(state);

    dev.log('MatchEditorNotifier: 상태가 빈 기본값으로 초기화되었습니다.', name: 'MatchEditor');
    dev.log('초기화된 Match 상태: $state', name: 'MatchEditor');
  }

  /// 득점자 목록 직접 업데이트 (UI에서 직접 호출용)
  void updateScorers(List<ScorerInfo> scorers) {
    // Optional: Add a deep equality check if performance becomes an issue
    // due to frequent calls with identical lists.
    // For now, this direct update approach is simpler.
    // if (listEquals(state.scorers, scorers)) {
    //   dev.log('득점자 목록이 동일하여 업데이트 무시 (updateScorers)', name: 'MatchEditor');
    //   return;
    // }

    dev.log('득점자 목록 업데이트 시작 (updateScorers), 총 ${scorers.length}개',
        name: 'MatchEditor');
    state = state.copyWith(scorers: scorers);

    // Regenerate the goalScorers string from the authoritative scorers list
    final newGoalScorersString = _generateGoalScorersString(
        scorers, state.homeTeamName, state.awayTeamName);

    // Update goalScorers string in the state
    // Only update if it actually changed to prevent unnecessary rebuilds if stringification is stable.
    if (state.goalScorers != newGoalScorersString) {
      state = state.copyWith(goalScorers: newGoalScorersString);
      dev.log(
          'GoalScorers string regenerated and updated: $newGoalScorersString',
          name: 'MatchEditor');
    } else {
      dev.log(
          'GoalScorers string regenerated but was identical, no update to string.',
          name: 'MatchEditor');
    }

    // GoalScorersNotifier 상태도 함께 업데이트
    ref.read(goalScorersProvider.notifier).resetToDefault(scorers);

    // DB에 현재 상태 저장
    _updateMatch.updateCurrentEditingMatch(state);
    dev.log('득점자 목록 업데이트 완료 (updateScorers), 최종 득점자 수: ${state.scorers.length}',
        name: 'MatchEditor');
  }

  /// 범용 업데이트 메소드 (필드명과 값을 받아 Match 상태 업데이트)
  void updateMatchField(String fieldName, dynamic value) {
    // ... existing code ...
  }
}

// 득점자 리스트를 문자열로 변환하는 헬퍼 함수 (기존 _syncScorersToString 로직 기반)
String _generateGoalScorersString(
    List<ScorerInfo> scorers, String homeTeamName, String awayTeamName) {
  final homeScorers = scorers.where((s) => s.isHomeTeam).toList();
  final awayScorers = scorers.where((s) => !s.isHomeTeam).toList();

  homeScorers.sort((a, b) {
    final aTime = int.tryParse(a.time.replaceAll('+', '')) ?? 0;
    final bTime = int.tryParse(b.time.replaceAll('+', '')) ?? 0;
    return aTime.compareTo(bTime);
  });

  awayScorers.sort((a, b) {
    final aTime = int.tryParse(a.time.replaceAll('+', '')) ?? 0;
    final bTime = int.tryParse(b.time.replaceAll('+', '')) ?? 0;
    return aTime.compareTo(bTime);
  });

  final buffer = StringBuffer();
  final currentHomeTeamName = homeTeamName.isEmpty ? '홈팀' : homeTeamName;
  final currentAwayTeamName = awayTeamName.isEmpty ? '원정팀' : awayTeamName;

  if (homeScorers.isNotEmpty) {
    buffer.write('$currentHomeTeamName: ');
    for (int i = 0; i < homeScorers.length; i++) {
      final s = homeScorers[i];
      buffer.write("${s.time}' ${s.name}");
      if (s.isOwnGoal) buffer.write(' (자책골)');
      if (i < homeScorers.length - 1) buffer.write(', ');
    }
  }

  if (awayScorers.isNotEmpty) {
    if (buffer.isNotEmpty) buffer.write('\n');
    buffer.write('$currentAwayTeamName: ');
    for (int i = 0; i < awayScorers.length; i++) {
      final s = awayScorers[i];
      buffer.write("${s.time}' ${s.name}");
      if (s.isOwnGoal) buffer.write(' (자책골)');
      if (i < awayScorers.length - 1) buffer.write(', ');
    }
  }
  return buffer.toString();
}

// firstWhereOrNull 확장 메소드 (List<Team>에 적용하기 위함)
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
