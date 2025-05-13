import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/core/constants/asset_paths.dart';
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/focus_manager_provider.dart';
import 'dart:developer' as dev;

/// 팀 정보 관리 프로바이더
final teamInfoProvider = Provider<TeamInfoManager>((ref) {
  final matchNotifier = ref.watch(matchEditorProvider.notifier);
  final focusManager = ref.watch(focusManagerProvider);
  return TeamInfoManager(matchNotifier, focusManager);
});

/// 팀 정보 관리 클래스
class TeamInfoManager {
  final MatchEditorNotifier _matchNotifier;
  final FocusManagerService _focusManager;

  // 텍스트 필드의 더 짧은 디바운스 시간 (텍스트 필드 UI 응답성 최적화)
  static const _textDebounceTime = Duration(milliseconds: 500);

  // 최근 작업 캐싱을 위한 변수
  DateTime? _lastUpdateTime;

  TeamInfoManager(this._matchNotifier, this._focusManager);

  /// 디바운스 타이머 설정 (UI 응답성 최적화)
  void _debounce(String fieldId, Function() callback) {
    final now = DateTime.now();

    // 마지막 업데이트 후 100ms 이내에는 새 요청을 스로틀링
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inMilliseconds < 100) {
      dev.log('빠른 중복 요청 방지: $fieldId', name: 'TeamInfoManager');
      return;
    }

    _lastUpdateTime = now;
    _focusManager.setDebounce(fieldId, callback);
  }

  /// 홈팀 이름 업데이트
  void updateHomeTeamName(String name) {
    try {
      final fieldId = 'homeTeamName';

      // 이미 같은 필드를 업데이트 중이면 리턴
      if (_focusManager.isUpdating(fieldId)) return;

      // 디바운싱 적용 (응답성 향상을 위해 시간 단축)
      _debounce(fieldId, () {
        try {
          _focusManager.setUpdating(fieldId);
          _matchNotifier.updateHomeTeamName(name);
          _focusManager.clearUpdating();
        } catch (e, stackTrace) {
          _focusManager.clearUpdating();
          dev.log('홈팀 이름 업데이트 오류: $e', name: 'TeamInfoManager');
          dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
        }
      });
    } catch (e, stackTrace) {
      dev.log('홈팀 이름 업데이트 처리 오류: $e', name: 'TeamInfoManager');
      dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
    }
  }

  /// 원정팀 이름 업데이트
  void updateAwayTeamName(String name) {
    try {
      final fieldId = 'awayTeamName';

      // 이미 같은 필드를 업데이트 중이면 리턴
      if (_focusManager.isUpdating(fieldId)) return;

      // 디바운싱 적용 (응답성 향상을 위해 시간 단축)
      _debounce(fieldId, () {
        try {
          _focusManager.setUpdating(fieldId);
          _matchNotifier.updateAwayTeamName(name);
          _focusManager.clearUpdating();
        } catch (e, stackTrace) {
          _focusManager.clearUpdating();
          dev.log('원정팀 이름 업데이트 오류: $e', name: 'TeamInfoManager');
          dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
        }
      });
    } catch (e, stackTrace) {
      dev.log('원정팀 이름 업데이트 처리 오류: $e', name: 'TeamInfoManager');
      dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
    }
  }

  /// 홈팀 로고 업데이트
  void updateHomeLogo(String path) {
    try {
      // 경로 유효성 검사 - 안전한 경로만 사용
      if (!AssetPaths.isValidLogoPath(path)) {
        dev.log('유효하지 않은 로고 경로: $path, 기본 로고로 대체합니다', name: 'TeamInfoManager');
        path = AssetPaths.defaultCrest;
      }

      // 마지막 업데이트 후 100ms 이내에는 새 요청을 스로틀링
      final now = DateTime.now();
      if (_lastUpdateTime != null &&
          now.difference(_lastUpdateTime!).inMilliseconds < 100) {
        return;
      }
      _lastUpdateTime = now;

      _matchNotifier.updateHomeLogo(path);
    } catch (e, stackTrace) {
      dev.log('홈팀 로고 업데이트 오류: $e', name: 'TeamInfoManager');
      dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
    }
  }

  /// 원정팀 로고 업데이트
  void updateAwayLogo(String path) {
    try {
      // 경로 유효성 검사 - 안전한 경로만 사용
      if (!AssetPaths.isValidLogoPath(path)) {
        dev.log('유효하지 않은 로고 경로: $path, 기본 로고로 대체합니다', name: 'TeamInfoManager');
        path = AssetPaths.defaultCrest;
      }

      // 마지막 업데이트 후 100ms 이내에는 새 요청을 스로틀링
      final now = DateTime.now();
      if (_lastUpdateTime != null &&
          now.difference(_lastUpdateTime!).inMilliseconds < 100) {
        return;
      }
      _lastUpdateTime = now;

      _matchNotifier.updateAwayLogo(path);
    } catch (e, stackTrace) {
      dev.log('원정팀 로고 업데이트 오류: $e', name: 'TeamInfoManager');
      dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
    }
  }

  /// 홈팀 점수 업데이트
  void updateHomeScore(String score) {
    try {
      final fieldId = 'homeScore';

      // 디바운싱 적용 (응답성 향상을 위해 시간 단축)
      _debounce(fieldId, () {
        try {
          _focusManager.setUpdating(fieldId);

          // 비어있으면 null로 설정
          final trimmedScore = score.trim();
          final newScore =
              trimmedScore.isEmpty ? null : int.tryParse(trimmedScore);

          // 숫자가 아닌 입력일 경우 로그 기록
          if (trimmedScore.isNotEmpty && newScore == null) {
            dev.log('유효하지 않은 점수 값: $trimmedScore (숫자만 허용됨)',
                name: 'TeamInfoManager');
          }

          _matchNotifier.updateHomeScore(newScore);
          _focusManager.clearUpdating();
        } catch (e, stackTrace) {
          _focusManager.clearUpdating();
          dev.log('홈팀 점수 업데이트 오류: $e', name: 'TeamInfoManager');
          dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
        }
      });
    } catch (e, stackTrace) {
      dev.log('홈팀 점수 업데이트 처리 오류: $e', name: 'TeamInfoManager');
      dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
    }
  }

  /// 원정팀 점수 업데이트
  void updateAwayScore(String score) {
    try {
      final fieldId = 'awayScore';

      // 디바운싱 적용 (응답성 향상을 위해 시간 단축)
      _debounce(fieldId, () {
        try {
          _focusManager.setUpdating(fieldId);

          // 비어있으면 null로 설정
          final trimmedScore = score.trim();
          final newScore =
              trimmedScore.isEmpty ? null : int.tryParse(trimmedScore);

          // 숫자가 아닌 입력일 경우 로그 기록
          if (trimmedScore.isNotEmpty && newScore == null) {
            dev.log('유효하지 않은 점수 값: $trimmedScore (숫자만 허용됨)',
                name: 'TeamInfoManager');
          }

          _matchNotifier.updateAwayScore(newScore);
          _focusManager.clearUpdating();
        } catch (e, stackTrace) {
          _focusManager.clearUpdating();
          dev.log('원정팀 점수 업데이트 오류: $e', name: 'TeamInfoManager');
          dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
        }
      });
    } catch (e, stackTrace) {
      dev.log('원정팀 점수 업데이트 처리 오류: $e', name: 'TeamInfoManager');
      dev.log('스택 트레이스: $stackTrace', name: 'TeamInfoManager');
    }
  }
}
