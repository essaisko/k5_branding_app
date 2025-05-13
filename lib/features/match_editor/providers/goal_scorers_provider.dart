import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/domain/usecases/update_match.dart';
import 'package:k5_branding_app/data/repositories/match_repository_impl.dart'; // UpdateMatch 의존성 해결 위해 필요
// import 'package:uuid/uuid.dart'; // 직접 ID 생성 안 함
import 'dart:developer' as dev;
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart'; // MatchEditorProvider 참조
import 'package:uuid/uuid.dart';

/// Provider for goal scorers list management
final goalScorersProvider =
    NotifierProvider<GoalScorersNotifier, List<ScorerInfo>>(() {
  return GoalScorersNotifier();
});

/// Notifier for managing the list of goal scorers
class GoalScorersNotifier extends Notifier<List<ScorerInfo>> {
  // static const _uuid = Uuid(); // MatchEditorNotifier에서 ID 생성
  // late final UpdateMatch _updateMatch; // MatchEditorNotifier에서 처리

  @override
  List<ScorerInfo> build() {
    final matchScorers =
        ref.watch(matchEditorProvider.select((match) => match.scorers));
    dev.log(
        'GoalScorersNotifier built/updated. Scorers count: ${matchScorers.length}',
        name: 'GoalScorers');
    return matchScorers;
  }

  /// 득점자 목록 직접 설정 (초기화 또는 전체 교체용)
  /// 이 메소드는 MatchEditorNotifier가 초기화 시 호출
  void resetToDefault(List<ScorerInfo> scorers) {
    state = scorers;
    dev.log(
        'GoalScorersNotifier: Scorers reset to default by MatchEditorNotifier: ${scorers.length} items',
        name: 'GoalScorers');
  }

  /// 득점자 추가
  void addScorer(ScorerInfo scorer) {
    // 중요: 이 로직은 MatchEditorNotifier의 자유 형식 텍스트 입력과 충돌할 수 있음.
    // MatchEditorNotifier의 updateGoalScorersDirectly를 호출하도록 수정 필요.
    dev.log(
        '[GoalScorersNotifier] addScorer called. Current free-form input might be out of sync.',
        name: 'GoalScorers');
    // 임시로 기존 로직 유지 (MatchEditorNotifier의 _updateMatch.addScorer가 없으므로 직접 상태 변경)
    // 실제로는 MatchEditorNotifier의 goalScorers 문자열을 업데이트하고 파싱을 다시 트리거해야 함.
    final scorerWithId = scorer.id.isEmpty
        ? scorer.copyWith(id: Uuid().v4())
        : scorer; // ID 직접 생성
    state = [...state, scorerWithId];
    // TODO: MatchEditorNotifier의 상태를 업데이트하도록 변경 필요
  }

  /// 득점자 제거
  void removeScorer(String id) {
    dev.log(
        '[GoalScorersNotifier] removeScorer called. Current free-form input might be out of sync.',
        name: 'GoalScorers');
    state = state.where((s) => s.id != id).toList();
    // TODO: MatchEditorNotifier의 상태를 업데이트하도록 변경 필요
  }

  /// 득점자 업데이트 (공통 로직)
  void _updateScorerInternal(
      String id, ScorerInfo Function(ScorerInfo) updateFn) {
    dev.log(
        '[GoalScorersNotifier] _updateScorerInternal called. Current free-form input might be out of sync.',
        name: 'GoalScorers');
    final scorerIndex = state.indexWhere((s) => s.id == id);
    if (scorerIndex == -1) return;
    final originalScorer = state[scorerIndex];
    final updatedScorer = updateFn(originalScorer);
    if (originalScorer == updatedScorer) return;
    final updatedScorers = List<ScorerInfo>.from(state);
    updatedScorers[scorerIndex] = updatedScorer;
    state = updatedScorers;
    // TODO: MatchEditorNotifier의 상태를 업데이트하도록 변경 필요
  }

  /// 득점자 시간 업데이트
  void updateScorerTime(String id, String time) {
    _updateScorerInternal(id, (scorer) => scorer.copyWith(time: time));
  }

  /// 득점자 이름 업데이트
  void updateScorerName(String id, String name) {
    _updateScorerInternal(id, (scorer) => scorer.copyWith(name: name));
  }

  /// 자책골 여부 토글
  void toggleScorerOwnGoal(String id) {
    _updateScorerInternal(
        id, (scorer) => scorer.copyWith(isOwnGoal: !scorer.isOwnGoal));
  }

  /// 득점자 팀 토글 (홈/원정)
  void toggleScorerTeam(String id) {
    _updateScorerInternal(
        id, (scorer) => scorer.copyWith(isHomeTeam: !scorer.isHomeTeam));
  }
}
