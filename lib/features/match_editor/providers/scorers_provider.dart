import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/domain/entities/match.dart';
import 'package:k5_branding_app/features/match_editor/providers/goal_scorers_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/focus_manager_provider.dart';
import 'dart:developer' as dev;
import 'package:uuid/uuid.dart';

/// 득점자 관리 프로바이더
final scorersProvider = Provider<ScorersManager>((ref) {
  final goalScorersNotifier = ref.watch(goalScorersProvider.notifier);
  final focusManager = ref.watch(focusManagerProvider);
  return ScorersManager(goalScorersNotifier, focusManager);
});

/// 득점자 관리 클래스
class ScorersManager {
  final GoalScorersNotifier _goalScorersNotifier;
  final FocusManagerService _focusManager;
  static const _uuid = Uuid();

  // 최근 작업 캐싱용 변수
  String? _lastProcessedId;
  DateTime? _lastOperationTime;

  ScorersManager(this._goalScorersNotifier, this._focusManager);

  /// 득점자 추가
  void addScorer(bool isHomeTeam) {
    try {
      final now = DateTime.now();
      if (_lastOperationTime != null &&
          now.difference(_lastOperationTime!).inMilliseconds < 300) {
        dev.log('중복 요청 방지: 득점자 추가 요청이 너무 빠름', name: 'ScorersManager');
        return;
      }
      _lastOperationTime = now;

      // GoalScorersNotifier.addScorer는 ScorerInfo 객체를 인자로 받음
      final newScorer = ScorerInfo(
        id: _uuid.v4(), // ID는 여기서 생성 또는 GoalScorersNotifier 내부에서 처리 (현재는 내부 처리)
        isHomeTeam: isHomeTeam,
        name: '', // 기본 빈 이름
        time: '', // 기본 빈 시간
        isOwnGoal: false,
      );
      _goalScorersNotifier.addScorer(newScorer);
    } catch (e, stackTrace) {
      dev.log('득점자 추가 오류: $e', name: 'ScorersManager');
      dev.log('스택 트레이스: $stackTrace', name: 'ScorersManager');
    }
  }

  /// 득점자 제거
  void removeScorer(String id) {
    try {
      if (id.isEmpty) {
        dev.log('득점자 제거 실패: 빈 ID', name: 'ScorersManager');
        return;
      }

      // 같은 ID에 대한 중복 삭제 작업 방지
      if (_lastProcessedId == id) {
        final now = DateTime.now();
        if (_lastOperationTime != null &&
            now.difference(_lastOperationTime!).inMilliseconds < 300) {
          dev.log('중복 요청 방지: 같은 득점자 삭제 요청이 너무 빠름', name: 'ScorersManager');
          return;
        }
      }

      _lastProcessedId = id;
      _lastOperationTime = DateTime.now();
      _goalScorersNotifier.removeScorer(id);
    } catch (e, stackTrace) {
      dev.log('득점자 제거 오류: $e', name: 'ScorersManager');
      dev.log('스택 트레이스: $stackTrace', name: 'ScorersManager');
    }
  }

  /// 득점자 시간 업데이트 - 디바운싱 적용
  void updateScorerTime(String id, String time) {
    try {
      if (id.isEmpty) {
        dev.log('득점자 시간 업데이트 실패: 빈 ID', name: 'ScorersManager');
        return;
      }

      final fieldId = 'scorer_time_$id';

      // 디바운싱 적용
      _focusManager.setDebounce(fieldId, () {
        try {
          _focusManager.setUpdating(fieldId);

          final validTime = time.isEmpty ? '' : time;

          if (validTime.isNotEmpty && int.tryParse(validTime) == null) {
            dev.log('득점자 시간 업데이트: 숫자 형식이 아닌 값 ($validTime)',
                name: 'ScorersManager');
          }

          _goalScorersNotifier.updateScorerTime(id, validTime);
          _focusManager.clearUpdating();
        } catch (e, stackTrace) {
          _focusManager.clearUpdating();
          dev.log('득점자 시간 업데이트 오류: $e', name: 'ScorersManager');
          dev.log('스택 트레이스: $stackTrace', name: 'ScorersManager');
        }
      });
    } catch (e, stackTrace) {
      dev.log('득점자 시간 업데이트 처리 오류: $e', name: 'ScorersManager');
      dev.log('스택 트레이스: $stackTrace', name: 'ScorersManager');
    }
  }

  /// 득점자 이름 업데이트 - 디바운싱 적용
  void updateScorerName(String id, String name) {
    try {
      if (id.isEmpty) {
        dev.log('득점자 이름 업데이트 실패: 빈 ID', name: 'ScorersManager');
        return;
      }

      final fieldId = 'scorer_name_$id';

      // 디바운싱 적용
      _focusManager.setDebounce(fieldId, () {
        try {
          _focusManager.setUpdating(fieldId);
          _goalScorersNotifier.updateScorerName(id, name);
          _focusManager.clearUpdating();
        } catch (e, stackTrace) {
          _focusManager.clearUpdating();
          dev.log('득점자 이름 업데이트 오류: $e', name: 'ScorersManager');
          dev.log('스택 트레이스: $stackTrace', name: 'ScorersManager');
        }
      });
    } catch (e, stackTrace) {
      dev.log('득점자 이름 업데이트 처리 오류: $e', name: 'ScorersManager');
      dev.log('스택 트레이스: $stackTrace', name: 'ScorersManager');
    }
  }

  /// 자책골 여부 토글
  void toggleOwnGoal(String id) {
    try {
      if (id.isEmpty) {
        dev.log('자책골 토글 실패: 빈 ID', name: 'ScorersManager');
        return;
      }

      if (_lastProcessedId == id) {
        final now = DateTime.now();
        if (_lastOperationTime != null &&
            now.difference(_lastOperationTime!).inMilliseconds < 300) {
          dev.log('중복 요청 방지: 같은 자책골 토글 요청이 너무 빠름', name: 'ScorersManager');
          return;
        }
      }

      _lastProcessedId = id;
      _lastOperationTime = DateTime.now();
      _goalScorersNotifier.toggleScorerOwnGoal(id);
    } catch (e, stackTrace) {
      dev.log('자책골 토글 오류: $e', name: 'ScorersManager');
      dev.log('스택 트레이스: $stackTrace', name: 'ScorersManager');
    }
  }

  /// 홈/원정팀 여부 토글
  void toggleTeam(String id) {
    try {
      if (id.isEmpty) {
        dev.log('득점자 팀 토글 실패: 빈 ID', name: 'ScorersManager');
        return;
      }

      if (_lastProcessedId == id) {
        final now = DateTime.now();
        if (_lastOperationTime != null &&
            now.difference(_lastOperationTime!).inMilliseconds < 300) {
          dev.log('중복 요청 방지: 같은 팀 토글 요청이 너무 빠름', name: 'ScorersManager');
          return;
        }
      }

      _lastProcessedId = id;
      _lastOperationTime = DateTime.now();
      _goalScorersNotifier.toggleScorerTeam(id);
    } catch (e, stackTrace) {
      dev.log('득점자 팀 토글 오류: $e', name: 'ScorersManager');
      dev.log('스택 트레이스: $stackTrace', name: 'ScorersManager');
    }
  }
}
