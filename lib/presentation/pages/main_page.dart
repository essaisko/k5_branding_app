import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chukshin_app/presentation/pages/feed_page.dart';
import 'package:chukshin_app/presentation/pages/my_team_page.dart';
import 'package:chukshin_app/presentation/pages/records_page.dart';
import 'package:chukshin_app/presentation/pages/search_page.dart';
import 'package:chukshin_app/presentation/pages/profile_page.dart';

/// 축신 앱의 메인 페이지
/// 바텀 네비게이션 바가 있는 메인 레이아웃
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
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
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
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
      ),
    );
  }
}
