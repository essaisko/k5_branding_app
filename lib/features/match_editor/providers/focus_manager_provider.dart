import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:developer' as dev;

/// 텍스트 업데이트 디바운싱 시간 - 800ms로 설정
const _debounceTime = Duration(milliseconds: 800);

/// 포커스 상태 관리를 위한 프로바이더
/// FocusManagerService의 생명주기를 Riverpod이 관리함
final focusManagerProvider = Provider<FocusManagerService>((ref) {
  final service = FocusManagerService();

  // dispose 될 때 자원 해제
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// 포커스 노드 관리 프로바이더 (텍스트 필드 포커스 관리)
final focusNodesProvider = Provider<FocusNodeManager>((ref) {
  final manager = FocusNodeManager();

  // dispose 될 때 포커스 노드 정리
  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

/// 텍스트 필드용 포커스 노드 관리자
class FocusNodeManager {
  final Map<String, FocusNode> _focusNodes = {};

  /// 특정 ID에 해당하는 포커스 노드 가져오기 (없으면 생성)
  FocusNode getFocusNode(String id) {
    if (!_focusNodes.containsKey(id)) {
      _focusNodes[id] = FocusNode();
    }
    return _focusNodes[id]!;
  }

  /// 포커스 노드 존재 여부 확인
  bool hasFocusNode(String id) {
    return _focusNodes.containsKey(id);
  }

  /// 포커스 노드 제거 (더 이상 사용하지 않을 경우)
  void removeFocusNode(String id) {
    if (_focusNodes.containsKey(id)) {
      _focusNodes[id]!.dispose();
      _focusNodes.remove(id);
    }
  }

  /// 모든 포커스 노드 해제
  void dispose() {
    try {
      for (final node in _focusNodes.values) {
        node.dispose();
      }
      _focusNodes.clear();
    } catch (e, stackTrace) {
      dev.log('포커스 노드 해제 오류: $e', name: 'FocusNodeManager');
      dev.log('스택 트레이스: $stackTrace', name: 'FocusNodeManager');
    }
  }
}

/// 포커스 상태 관리 서비스 - 여러 TextField 간 포커스 충돌 방지
class FocusManagerService {
  /// 현재 업데이트 중인 필드 (순환 업데이트 방지)
  String _currentlyUpdatingField = '';

  /// 업데이트 디바운싱
  final Map<String, Timer> _debounceTimers = {};

  /// 현재 입력 커서 위치 저장
  final Map<String, TextEditingValue> _textValues = {};

  /// 마지막 활성화 시간 (메모리 최적화용)
  final Map<String, DateTime> _lastActivityTime = {};

  /// 비활성화된 필드를 정리하는 주기 (30초마다)
  static const _cleanupInterval = Duration(seconds: 30);
  Timer? _cleanupTimer;

  FocusManagerService() {
    // 주기적으로 비활성화된 필드 정리
    _startCleanupTimer();
  }

  /// 메모리 최적화를 위한 정리 타이머 시작
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupInactiveFields();
    });
  }

  /// 일정 시간 동안 비활성화된 필드 데이터 정리
  void _cleanupInactiveFields() {
    try {
      final now = DateTime.now();
      final inactiveThreshold = Duration(minutes: 3); // 3분 이상 사용하지 않은 필드

      // 오래된 활동 정보 삭제
      final keysToRemove = <String>[];
      for (final entry in _lastActivityTime.entries) {
        if (now.difference(entry.value) > inactiveThreshold) {
          keysToRemove.add(entry.key);
        }
      }

      // 필드 데이터 정리
      for (final key in keysToRemove) {
        _lastActivityTime.remove(key);
        _textValues.remove(key);
        // 타이머가 있으면 취소하고 제거
        _debounceTimers[key]?.cancel();
        _debounceTimers.remove(key);
      }

      if (keysToRemove.isNotEmpty) {
        dev.log('${keysToRemove.length}개의 비활성 필드 정리됨',
            name: 'FocusManagerService');
      }
    } catch (e, stackTrace) {
      dev.log('비활성 필드 정리 오류: $e', name: 'FocusManagerService');
      dev.log('스택 트레이스: $stackTrace', name: 'FocusManagerService');
    }
  }

  /// 새 디바운스 타이머 설정
  void setDebounce(String fieldId, VoidCallback callback) {
    try {
      // 이전 타이머 취소
      _debounceTimers[fieldId]?.cancel();

      // 새 타이머 설정
      _debounceTimers[fieldId] = Timer(_debounceTime, callback);

      // 필드 활성화 시간 업데이트
      _lastActivityTime[fieldId] = DateTime.now();
    } catch (e, stackTrace) {
      dev.log('디바운스 타이머 설정 오류: $e', name: 'FocusManagerService');
      dev.log('스택 트레이스: $stackTrace', name: 'FocusManagerService');
    }
  }

  /// 필드 업데이트 잠금 (순환 업데이트 방지)
  bool isUpdating(String fieldId) {
    return _currentlyUpdatingField == fieldId;
  }

  /// 필드 업데이트 잠금 설정
  void setUpdating(String fieldId) {
    _currentlyUpdatingField = fieldId;
    _lastActivityTime[fieldId] = DateTime.now();
  }

  /// 필드 업데이트 잠금 해제
  void clearUpdating() {
    _currentlyUpdatingField = '';
  }

  /// 텍스트 필드의 현재 값과 커서 위치 저장
  void saveTextFieldValue(String fieldId, TextEditingValue value) {
    try {
      _textValues[fieldId] = value;
      _lastActivityTime[fieldId] = DateTime.now();
    } catch (e, stackTrace) {
      dev.log('텍스트 필드 값 저장 오류: $e', name: 'FocusManagerService');
      dev.log('스택 트레이스: $stackTrace', name: 'FocusManagerService');
    }
  }

  /// 저장된 텍스트 필드 값 가져오기
  TextEditingValue? getTextFieldValue(String fieldId) {
    _lastActivityTime[fieldId] = DateTime.now();
    return _textValues[fieldId];
  }

  /// 모든 디바운스 타이머 정리 (위젯 dispose 시 호출)
  void dispose() {
    try {
      // 정리 타이머 취소
      _cleanupTimer?.cancel();

      // 디바운스 타이머 모두 취소
      for (final timer in _debounceTimers.values) {
        timer.cancel();
      }
      _debounceTimers.clear();
      _textValues.clear();
      _lastActivityTime.clear();
      _currentlyUpdatingField = '';
    } catch (e, stackTrace) {
      dev.log('FocusManagerService 정리 오류: $e', name: 'FocusManagerService');
      dev.log('스택 트레이스: $stackTrace', name: 'FocusManagerService');
    }
  }
}
