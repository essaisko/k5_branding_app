import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart';
import 'package:k5_branding_app/features/match_editor/providers/focus_manager_provider.dart';
import 'dart:developer' as dev;

/// 경기 세부 정보 관리 프로바이더
final matchDetailsProvider = Provider<MatchDetailsManager>((ref) {
  final matchNotifier = ref.watch(matchEditorProvider.notifier);
  final focusManager = ref.watch(focusManagerProvider);
  return MatchDetailsManager(matchNotifier, focusManager);
});

/// 경기 세부 정보 관리 클래스
class MatchDetailsManager {
  final MatchEditorNotifier _matchNotifier;
  final FocusManagerService _focusManager;

  MatchDetailsManager(this._matchNotifier, this._focusManager);

  /// 경기 일시 업데이트
  void updateMatchDateTime(DateTime dateTime) {
    try {
      _matchNotifier.updateMatchDateTime(dateTime);
    } catch (e) {
      dev.log('경기 일시 업데이트 오류: $e', name: 'MatchDetailsManager');
    }
  }

  /// 경기장 위치 업데이트
  void updateVenueLocation(String location) {
    try {
      final fieldId = 'venueLocation';

      // 디바운싱 적용
      _focusManager.setDebounce(fieldId, () {
        try {
          _focusManager.setUpdating(fieldId);
          _matchNotifier.updateVenueLocation(location);
          _focusManager.clearUpdating();
        } catch (e) {
          _focusManager.clearUpdating();
          dev.log('경기장 위치 업데이트 오류: $e', name: 'MatchDetailsManager');
        }
      });
    } catch (e) {
      dev.log('경기장 위치 업데이트 처리 오류: $e', name: 'MatchDetailsManager');
    }
  }

  /// 라운드 정보 업데이트
  void updateRoundInfo(String roundInfo) {
    try {
      final fieldId = 'roundInfo';

      // 이미 같은 필드를 업데이트 중이면 리턴
      if (_focusManager.isUpdating(fieldId)) return;

      // 디바운싱 적용
      _focusManager.setDebounce(fieldId, () {
        try {
          _focusManager.setUpdating(fieldId);
          _matchNotifier.updateRoundInfo(roundInfo);
          _focusManager.clearUpdating();
        } catch (e) {
          _focusManager.clearUpdating();
          dev.log('라운드 정보 업데이트 오류: $e', name: 'MatchDetailsManager');
        }
      });
    } catch (e) {
      dev.log('라운드 정보 업데이트 처리 오류: $e', name: 'MatchDetailsManager');
    }
  }

  /// 리그 이름 업데이트
  void updateLeagueName(String leagueName) {
    try {
      final fieldId = 'leagueName';

      // 이미 같은 필드를 업데이트 중이면 리턴
      if (_focusManager.isUpdating(fieldId)) return;

      // 디바운싱 적용
      _focusManager.setDebounce(fieldId, () {
        try {
          _focusManager.setUpdating(fieldId);
          _matchNotifier.updateLeagueName(leagueName);
          _focusManager.clearUpdating();
        } catch (e) {
          _focusManager.clearUpdating();
          dev.log('리그 이름 업데이트 오류: $e', name: 'MatchDetailsManager');
        }
      });
    } catch (e) {
      dev.log('리그 이름 업데이트 처리 오류: $e', name: 'MatchDetailsManager');
    }
  }
}
