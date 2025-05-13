import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k5_branding_app/domain/entities/match.dart'; // Match 엔티티 import
import 'package:k5_branding_app/domain/entities/team.dart'; // Team 엔티티 import
import 'package:k5_branding_app/features/match_editor/providers/sample_data_provider.dart'; // sampleTeamsProvider import
import 'dart:developer' as developer; // dart:developer import
import 'package:k5_branding_app/features/match_editor/providers/match_editor_provider.dart'; // FirstWhereOrNullExtension 사용을 위해 추가
// import 'package:k5_branding_app/domain/repositories/team_repository.dart'; // 현재 미사용으로 주석 처리

/// 팀 컬러 테마 상태를 관리하는 프로바이더
///
/// 홈팀 색상 및 현재 선택된 테마 색상을 관리합니다.
final teamColorProvider = NotifierProvider<TeamColorNotifier, TeamColorState>(
  () => TeamColorNotifier(),
);

/// 어떤 팀의 색상을 테마에 사용할지 정의
enum ColorThemeSource { home, away, custom }

/// 팀 컬러 상태 클래스
class TeamColorState {
  /// 홈팀 색상
  final Color homeTeamColor;

  /// 원정팀 색상
  final Color awayTeamColor;

  /// 현재 선택된 색상 (홈팀 또는 커스텀)
  final Color selectedColor;

  /// 커스텀 색상 사용 여부
  final bool isCustomColor;

  /// 어떤 팀/커스텀 색상을 테마로 사용하는지
  final ColorThemeSource colorThemeSource;

  /// 기본 팀 색상 팔레트 (K리그 및 K5 리그 팀 컬러)
  static final Map<String, Color> predefinedColors = {
    // K리그 팀
    '전북현대': const Color(0xFF1A9B42), // 다크 그린
    '울산현대': const Color(0xFF0A4C9F), // 블루
    'FC서울': const Color(0xFFE60012), // 레드
    '포항스틸러스': const Color(0xFFD04836), // 오렌지
    '수원삼성': const Color(0xFF005BAC), // 블루
    '대구FC': const Color(0xFF0E4C92), // 스카이 블루
    '인천유나이티드': const Color(0xFF08348C), // 인디고
    '강원FC': const Color(0xFFE95513), // 오렌지
    '성남FC': const Color(0xFFFFCC00), // 옐로우
    '광주FC': const Color(0xFFFFD800), // 옐로우
    '제주유나이티드': const Color(0xFFE83828), // 오렌지-레드
    '수원FC': const Color(0xFF1245AB), // 네이비 블루
    'FC안양': const Color(0xFF7F2AFF), // 퍼플
    '부산아이파크': const Color(0xFFE73904), // 레드
    '경남FC': const Color(0xFF009944), // 그린
    '서울이랜드': const Color(0xFF41BEE9), // 스카이 블루
    '안산그리너스': const Color(0xFF1F5A33), // 다크 그린
    '충남아산': const Color(0xFF006BB4), // 블루
    '부천FC': const Color(0xFF0046B9), // 블루
    '대전하나시티즌': const Color(0xFF8A1E26), // 버건디
    '김천상무': const Color(0xFF003B90), // 네이비 블루
    // K5 리그 팀 컬러
    '양산유나이티드': const Color.fromRGBO(205, 163, 3, 1),
    '플러즈FC': const Color.fromRGBO(236, 183, 34, 1),
    '재믹스축구클럽': const Color.fromRGBO(237, 28, 36, 1),
    '거제FCMOVV': const Color.fromARGB(255, 0, 121, 122),
    '원터치FC': const Color.fromRGBO(0, 101, 163, 1),
    '진주대성축구클럽': const Color.fromRGBO(255, 0, 0, 1),
    // 기본 색상
    '기본 블루': const Color(0xFF1A73E8), // 기본 블루 색상
    '기본 레드': const Color(0xFFE53935), // 기본 레드 색상
  };

  TeamColorState({
    this.homeTeamColor = const Color(0xFF1A73E8), // 기본 블루
    this.awayTeamColor = const Color(0xFFE53935), // 기본 레드 (원정팀 기본값 예시)
    this.selectedColor = const Color(0xFF1A73E8), // 초기에는 홈팀 색상을 따름
    this.isCustomColor = false,
    this.colorThemeSource = ColorThemeSource.home, // 초기에는 홈팀 색상 사용
  });

  /// 상태 복사본 생성
  TeamColorState copyWith({
    Color? homeTeamColor,
    Color? awayTeamColor,
    Color? selectedColor,
    bool? isCustomColor,
    ColorThemeSource? colorThemeSource,
  }) {
    return TeamColorState(
      homeTeamColor: homeTeamColor ?? this.homeTeamColor,
      awayTeamColor: awayTeamColor ?? this.awayTeamColor,
      selectedColor: selectedColor ?? this.selectedColor,
      isCustomColor: isCustomColor ?? this.isCustomColor,
      colorThemeSource: colorThemeSource ?? this.colorThemeSource,
    );
  }
}

/// 팀 컬러 상태 관리 노티파이어
class TeamColorNotifier extends Notifier<TeamColorState> {
  @override
  TeamColorState build() {
    // MatchEditorProvider에서 초기 홈/어웨이 팀 정보를 가져와서 색상을 설정할 수도 있음 (향후 개선)
    return TeamColorState();
  }

  /// 홈팀 색상 업데이트 (외부에서 팀 정보 변경 시 호출됨)
  void updateHomeTeamColor(Color color) {
    state = state.copyWith(homeTeamColor: color);
    // 현재 홈팀 색상을 테마로 사용 중이었다면, selectedColor도 업데이트
    if (state.colorThemeSource == ColorThemeSource.home) {
      state = state.copyWith(selectedColor: color, isCustomColor: false);
    }
  }

  /// 원정팀 색상 업데이트 (외부에서 팀 정보 변경 시 호출됨)
  void updateAwayTeamColor(Color color) {
    state = state.copyWith(awayTeamColor: color);
    // 현재 원정팀 색상을 테마로 사용 중이었다면, selectedColor도 업데이트
    if (state.colorThemeSource == ColorThemeSource.away) {
      state = state.copyWith(selectedColor: color, isCustomColor: false);
    }
  }

  /// 특정 팀의 색상을 테마로 사용 (홈 또는 어웨이)
  void useCustomTeamColorForTheme(ColorThemeSource source) {
    if (source == ColorThemeSource.custom) return; // 이 함수는 팀 색상 전용

    Color newSelectedColor;
    if (source == ColorThemeSource.home) {
      newSelectedColor = state.homeTeamColor;
    } else {
      // ColorThemeSource.away
      newSelectedColor = state.awayTeamColor;
    }
    state = state.copyWith(
      colorThemeSource: source,
      selectedColor: newSelectedColor,
      isCustomColor: false, // 팀 색상을 사용하므로 커스텀이 아님
    );
  }

  /// 커스텀 색상을 테마로 설정
  void setCustomColorForTheme(Color color) {
    state = state.copyWith(
      selectedColor: color,
      isCustomColor: true,
      colorThemeSource: ColorThemeSource.custom,
    );
  }

  void resetToDefault(Match defaultMatch, List<Team> sampleTeams) {
    // MatchEditorNotifier의 defaultMatchTemplate과 sampleTeamsProvider를 사용하여 기본 색상 설정

    if (defaultMatch.homeTeamName.isEmpty &&
        defaultMatch.awayTeamName.isEmpty) {
      // 팀 이름이 없는 경우 (emptyMatchTemplate 사용 시), 앱의 최초 기본 색상으로 설정
      state = TeamColorState();
      developer.log('TeamColorNotifier: 팀 이름이 없어 앱 최초 기본 색상으로 초기화되었습니다.',
          name: 'TeamColor');
    } else {
      // 팀 이름이 있는 경우, 기존 로직대로 sampleTeams에서 색상 검색
      Team? defaultHomeTeamFromSamples = sampleTeams.firstWhereOrNull(
        (team) => team.name == defaultMatch.homeTeamName,
      );
      Color homeColor = defaultHomeTeamFromSamples?.primaryColor ??
          TeamColorState().homeTeamColor; // 폴백도 초기 기본 홈팀 색상으로

      Team? defaultAwayTeamFromSamples = sampleTeams.firstWhereOrNull(
        (team) => team.name == defaultMatch.awayTeamName,
      );
      Color awayColor = defaultAwayTeamFromSamples?.primaryColor ??
          TeamColorState().awayTeamColor; // 폴백도 초기 기본 원정팀 색상으로

      state = state.copyWith(
        homeTeamColor: homeColor,
        awayTeamColor: awayColor,
        selectedColor: homeColor,
        colorThemeSource: ColorThemeSource.home,
        isCustomColor: false, // 팀 색상을 사용하므로 isCustomColor는 false
      );
      developer.log(
          'TeamColorNotifier: 팀 색상이 Match 정보 기반으로 초기화되었습니다. 홈: $homeColor, 어웨이: $awayColor',
          name: 'TeamColor');
    }
  }

  // 기존 setTeamColor는 역할이 모호해지므로 주석 처리 또는 삭제 (필요시 재정의)
  /*
  void setTeamColor(String teamName, bool isHomeTeam) {
    final color = TeamColorState.predefinedColors[teamName] ??
        TeamColorState.predefinedColors['기본 블루'] ??
        const Color(0xFF1A73E8);

    if (isHomeTeam) {
      updateHomeTeamColor(color);
      // if (!state.isCustomColor) { // 이 조건은 colorThemeSource로 대체됨
      //   state = state.copyWith(selectedColor: color);
      // }
    } else {
      // 원정팀 색상 업데이트 로직이 필요하면 여기에 추가 (현재는 없음)
      // updateAwayTeamColor(color); 
    }
  }
  */
}
