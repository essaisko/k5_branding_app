import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chukshin_app/presentation/pages/feed_page.dart';
import 'package:chukshin_app/presentation/pages/my_team_page.dart';
import 'package:chukshin_app/presentation/pages/records_page.dart';
import 'package:chukshin_app/presentation/pages/search_page.dart';
import 'package:chukshin_app/presentation/pages/profile_page.dart';
import 'package:chukshin_app/presentation/navigation/navigation_state.dart';

/// 축신 앱의 메인 페이지
/// 바텀 네비게이션 바가 있는 메인 레이아웃
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late PageController _pageController;

  final List<Widget> _pages = [
    const FeedPage(),
    const MyTeamPage(),
    const RecordsPage(),
    const SearchPage(),
    const ProfilePage(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      activeIcon: Icon(Icons.home),
      label: '홈',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.groups),
      activeIcon: Icon(Icons.groups),
      label: '나의 팀',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      activeIcon: Icon(Icons.analytics),
      label: '기록',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.search),
      activeIcon: Icon(Icons.search),
      label: '검색',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      activeIcon: Icon(Icons.person),
      label: '나의 정보',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    ref.read(navigationProvider.notifier).changeTab(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationState = ref.watch(navigationProvider);

    // 네비게이션 상태가 변경되면 PageController도 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != navigationState.currentIndex) {
        _pageController.animateToPage(
          navigationState.currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 페이지 뷰
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                ref.read(navigationProvider.notifier).changeTab(index);
              },
              children: _pages,
            ),
            // 오버레이 페이지 (팀 커뮤니티 등)
            if (navigationState.overlayPage != null)
              navigationState.overlayPage!,
          ],
        ),
      ),
      bottomNavigationBar: navigationState.showBottomNav
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: navigationState.currentIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: theme.primaryColor,
                unselectedItemColor: Colors.grey[600],
                selectedFontSize: 12,
                unselectedFontSize: 12,
                elevation: 0,
                iconSize: 24,
                items: _bottomNavItems,
              ),
            )
          : null,
    );
  }
}
