import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 축신 앱의 피드 페이지
/// 좌우 스크롤 가능한 카드뉴스 형태의 메인 피드
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 임시 카드뉴스 데이터
  final List<NewsCard> _newsCards = [
    NewsCard(
      title: '축신 앱에 오신 것을 환영합니다!',
      subtitle: '축구 소식과 커뮤니티를 한 곳에서',
      imageUrl: 'assets/images/default_crest.png',
      content: '축신에서 최신 축구 소식을 확인하고\n나만의 팀을 관리해보세요.',
      category: '공지사항',
    ),
    NewsCard(
      title: '오늘의 경기 결과',
      subtitle: 'K리그 주요 경기 결과',
      imageUrl: 'assets/images/default_crest.png',
      content: '오늘 진행된 주요 경기들의\n결과를 확인해보세요.',
      category: '경기 결과',
    ),
    NewsCard(
      title: '이주의 베스트 플레이어',
      subtitle: '뛰어난 활약을 보인 선수들',
      imageUrl: 'assets/images/default_crest.png',
      content: '이번 주 가장 인상적인\n활약을 보인 선수들을 소개합니다.',
      category: '선수 소식',
    ),
    NewsCard(
      title: '팀 매치 분석',
      subtitle: '전술과 전략 분석',
      imageUrl: 'assets/images/default_crest.png',
      content: '최근 경기의 전술적 분석과\n팀별 전략을 살펴봅니다.',
      category: '분석',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '축신',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 알림 페이지로 이동
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 필터 (선택사항)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('전체', true),
                _buildCategoryChip('경기 결과', false),
                _buildCategoryChip('선수 소식', false),
                _buildCategoryChip('분석', false),
                _buildCategoryChip('공지사항', false),
              ],
            ),
          ),

          // 메인 카드뉴스 영역
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _newsCards.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  child: _buildNewsCard(_newsCards[index]),
                );
              },
            ),
          ),

          // 페이지 인디케이터
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _newsCards.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? theme.primaryColor
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),

          // 하단 액션 버튼들
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 템플릿 편집기로 이동
                      Navigator.pushNamed(context, '/template-editor');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('템플릿 편집'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: 새 글 작성
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('새 글 작성'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // TODO: 카테고리 필터링 구현
        },
        backgroundColor: Colors.white,
        selectedColor: theme.primaryColor.withOpacity(0.2),
        checkmarkColor: theme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? theme.primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsCard card) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              theme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // 카테고리 태그
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    card.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // 메인 이미지
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: theme.primaryColor.withOpacity(0.3),
                ),
              ),
            ),

            // 콘텐츠 영역
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.subtitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Text(
                        card.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 뉴스 카드 데이터 모델
class NewsCard {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String content;
  final String category;

  NewsCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.content,
    required this.category,
  });
}
