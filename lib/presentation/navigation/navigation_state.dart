import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// 네비게이션 상태
class NavigationState {
  final int currentIndex;
  final Widget? overlayPage;
  final bool showBottomNav;
  final int? previousTabIndex;
  final int? teamCommunityTabIndex;

  const NavigationState({
    this.currentIndex = 0,
    this.overlayPage,
    this.showBottomNav = true,
    this.previousTabIndex,
    this.teamCommunityTabIndex,
  });

  NavigationState copyWith({
    int? currentIndex,
    Widget? overlayPage,
    bool? showBottomNav,
    int? previousTabIndex,
    int? teamCommunityTabIndex,
    bool clearOverlay = false,
    bool clearPreviousTab = false,
    bool clearTeamCommunityTab = false,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      overlayPage: clearOverlay ? null : (overlayPage ?? this.overlayPage),
      showBottomNav: showBottomNav ?? this.showBottomNav,
      previousTabIndex:
          clearPreviousTab ? null : (previousTabIndex ?? this.previousTabIndex),
      teamCommunityTabIndex: clearTeamCommunityTab
          ? null
          : (teamCommunityTabIndex ?? this.teamCommunityTabIndex),
    );
  }
}

/// 네비게이션 관리 Notifier
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  /// 바텀 네비게이션 탭 변경
  void changeTab(int index) {
    state = state.copyWith(
      currentIndex: index,
      clearOverlay: true,
    );
  }

  /// 팀 커뮤니티 탭 인덱스 저장
  void setTeamCommunityTabIndex(int tabIndex) {
    state = state.copyWith(
      teamCommunityTabIndex: tabIndex,
    );
  }

  /// 오버레이 페이지 표시 (팀 커뮤니티 등)
  void pushOverlay(Widget page, {bool showBottomNav = true}) {
    state = state.copyWith(
      overlayPage: page,
      showBottomNav: showBottomNav,
      previousTabIndex: state.currentIndex,
    );
  }

  /// 오버레이 페이지 제거
  void popOverlay() {
    final previousTab = state.previousTabIndex;
    state = state.copyWith(
      clearOverlay: true,
      showBottomNav: true,
      currentIndex: previousTab,
      clearPreviousTab: true,
      clearTeamCommunityTab: true,
    );
  }

  /// 일반 네비게이션 (바텀 네비게이션 숨김)
  void pushFullScreen(Widget page) {
    state = state.copyWith(
      overlayPage: page,
      showBottomNav: false,
      previousTabIndex: state.currentIndex,
    );
  }

  /// 풀스크린에서 뒤로가기
  void popFullScreen() {
    final previousTab = state.previousTabIndex;
    state = state.copyWith(
      clearOverlay: true,
      showBottomNav: true,
      currentIndex: previousTab,
      clearPreviousTab: true,
    );
  }

  /// 팀 커뮤니티로 돌아가기 (탭 인덱스 유지)
  void popToTeamCommunity(Widget teamCommunityPage) {
    state = state.copyWith(
      overlayPage: teamCommunityPage,
      showBottomNav: true,
      clearPreviousTab: false,
    );
  }
}

/// 네비게이션 Provider
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
  (ref) => NavigationNotifier(),
);
