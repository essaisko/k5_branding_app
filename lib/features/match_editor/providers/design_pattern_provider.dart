import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:developer' as developer;

/// 디자인 패턴 유형 정의
enum DesignPatternType {
  none,
  diagonal, // 대각선 패턴만 남김
  dots, // 도트 패턴만 남김
  image, // 이미지 배경 추가
}

/// 기본 이미지 배경 목록
class BackgroundImageAsset {
  final String id;
  final String path;
  final String name;

  const BackgroundImageAsset({
    required this.id,
    required this.path,
    required this.name,
  });
}

/// 샘플 배경 이미지 리스트
final List<BackgroundImageAsset> sampleBackgroundImages = [
  const BackgroundImageAsset(
    id: 'sample_1',
    path: 'assets/images/backgrounds/soccer_celebration_1.jpg',
    name: '골 세리머니 1',
  ),
  const BackgroundImageAsset(
    id: 'sample_2',
    path: 'assets/images/backgrounds/soccer_celebration_2.jpg',
    name: '골 세리머니 2',
  ),
  const BackgroundImageAsset(
    id: 'sample_3',
    path: 'assets/images/backgrounds/soccer_celebration_3.jpg',
    name: '골 세리머니 3',
  ),
];

/// 디자인 패턴 상태 클래스
class DesignPatternState {
  final DesignPatternType selectedPattern;
  final double patternOpacity;
  final Color? patternColor;
  final String? selectedImageId;
  final File? customImageFile;
  final bool isCustomImage;

  const DesignPatternState({
    this.selectedPattern = DesignPatternType.none,
    this.patternOpacity = 0.15,
    this.patternColor,
    this.selectedImageId,
    this.customImageFile,
    this.isCustomImage = false,
  });

  /// 상태 복사본 생성
  DesignPatternState copyWith({
    DesignPatternType? selectedPattern,
    double? patternOpacity,
    Color? patternColor,
    String? selectedImageId,
    File? customImageFile,
    bool? isCustomImage,
  }) {
    return DesignPatternState(
      selectedPattern: selectedPattern ?? this.selectedPattern,
      patternOpacity: patternOpacity ?? this.patternOpacity,
      patternColor: patternColor ?? this.patternColor,
      selectedImageId: selectedImageId ?? this.selectedImageId,
      customImageFile: customImageFile ?? this.customImageFile,
      isCustomImage: isCustomImage ?? this.isCustomImage,
    );
  }

  /// 패턴이 선택되었는지 확인
  bool get hasPattern => selectedPattern != DesignPatternType.none;

  /// 이미지가 선택되었는지 확인
  bool get hasImageBackground =>
      selectedPattern == DesignPatternType.image &&
      (selectedImageId != null || customImageFile != null);

  /// 선택된 샘플 이미지 가져오기
  BackgroundImageAsset? get selectedSampleImage {
    if (selectedImageId == null || isCustomImage) return null;

    try {
      return sampleBackgroundImages.firstWhere(
        (image) => image.id == selectedImageId,
        orElse: () => sampleBackgroundImages.isNotEmpty
            ? sampleBackgroundImages.first
            : throw Exception('No sample images available'),
      );
    } catch (e) {
      print('샘플 이미지 가져오기 오류: $e');
      return null;
    }
  }
}

/// 디자인 패턴 프로바이더
final designPatternProvider =
    NotifierProvider<DesignPatternNotifier, DesignPatternState>(
  () => DesignPatternNotifier(),
);

/// 디자인 패턴 상태 관리 노티파이어
class DesignPatternNotifier extends Notifier<DesignPatternState> {
  @override
  DesignPatternState build() {
    return const DesignPatternState();
  }

  /// 패턴 선택
  void selectPattern(DesignPatternType patternType) {
    if (state.selectedPattern == patternType) {
      state = state.copyWith(selectedPattern: DesignPatternType.none);
    } else {
      state = state.copyWith(selectedPattern: patternType);
    }

    print('패턴 선택: ${state.selectedPattern}, 투명도: ${state.patternOpacity}');
  }

  /// 패턴 투명도 설정
  void setPatternOpacity(double opacity) {
    if (opacity >= 0.0 && opacity <= 1.0) {
      state = state.copyWith(patternOpacity: opacity);
      print('투명도 설정: ${state.patternOpacity}');
    }
  }

  /// 샘플 이미지 선택
  void selectSampleImage(String imageId) {
    if (state.selectedImageId == imageId &&
        state.selectedPattern == DesignPatternType.image) {
      // 같은 이미지를 다시 선택하면 패턴 없음으로 변경
      state = state.copyWith(
        selectedPattern: DesignPatternType.none,
        selectedImageId: null,
      );
    } else {
      state = state.copyWith(
        selectedPattern: DesignPatternType.image,
        selectedImageId: imageId,
        isCustomImage: false,
        customImageFile: null,
      );
    }

    print('샘플 이미지 선택: $imageId');
  }

  /// 커스텀 이미지 선택
  void selectCustomImage(File imageFile) {
    state = state.copyWith(
      selectedPattern: DesignPatternType.image,
      customImageFile: imageFile,
      isCustomImage: true,
      selectedImageId: null,
    );

    print('커스텀 이미지 선택: ${imageFile.path}');
  }

  /// 이미지 배경 제거
  void clearImageBackground() {
    state = state.copyWith(
      selectedPattern: DesignPatternType.none,
      selectedImageId: null,
      customImageFile: null,
      isCustomImage: false,
    );

    print('이미지 배경 제거');
  }

  void setPatternColor(Color color) {
    state = state.copyWith(patternColor: color);
  }

  void resetToDefault() {
    state = const DesignPatternState();
    developer.log('DesignPatternNotifier: 패턴이 기본값(앱 최초 상태)으로 초기화되었습니다.',
        name: 'DesignPattern');
  }
}
