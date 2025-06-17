import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 기록 페이지
class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '기록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.sports_soccer),
              text: 'K리그 (공식)',
            ),
            Tab(
              icon: Icon(Icons.wb_sunny),
              text: '조기축구',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKLeagueTab(),
          _buildMorningFootballTab(),
        ],
      ),
    );
  }

  // K리그 (공식) 탭
  Widget _buildKLeagueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // K리그 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.blue,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'K리그 공식 경기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JoinKFA 경기 데이터 연동',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // K5 리그 섹션
          _buildLeagueSection('K5 리그', Colors.red, [
            _buildDivisionCard('경상남도 디비전 리그', 'K5', '경남'),
            _buildDivisionCard('부산광역시 디비전 리그', 'K5', '부산'),
          ]),

          const SizedBox(height: 16),

          // K6 리그 섹션
          _buildLeagueSection('K6 리그', Colors.green, [
            _buildDivisionCard('경상남도 [서부권역] 디비전 리그', 'K6', '경남서부'),
            _buildDivisionCard('경상남도 [동부권역] 디비전 리그', 'K6', '경남동부'),
            _buildDivisionCard('부산광역시 디비전 리그', 'K6', '부산'),
          ]),

          const SizedBox(height: 16),

          // K7 리그 섹션
          _buildLeagueSection('K7 리그', Colors.orange, [
            _buildDivisionCard('창원특례시 디비전리그', 'K7', '창원'),
            _buildDivisionCard('사천/함안 디비전 리그', 'K7', '사천함안'),
            _buildDivisionCard('거제시 디비전리그', 'K7', '거제'),
            _buildDivisionCard('진주시 디비전리그', 'K7', '진주'),
            _buildDivisionCard('거창군 디비전리그', 'K7', '거창'),
            _buildDivisionCard('김해시 A디비전리그', 'K7', '김해A'),
            _buildDivisionCard('김해시 B디비전리그', 'K7', '김해B'),
            _buildDivisionCard('남해군 디비전 리그', 'K7', '남해'),
            _buildDivisionCard('양산시 A디비전리그', 'K7', '양산A'),
            _buildDivisionCard('양산시 B디비전리그', 'K7', '양산B'),
            _buildDivisionCard('부산시 영도구 디비전리그', 'K7', '부산영도'),
            _buildDivisionCard('부산시 북구 디비전리그', 'K7', '부산북구'),
            _buildDivisionCard('부산시 사상구 디비전리그', 'K7', '부산사상'),
            _buildDivisionCard('부산시 남구 디비전리그', 'K7', '부산남구'),
            _buildDivisionCard('부산시 부산진구 디비전리그', 'K7', '부산진'),
            _buildDivisionCard('부산시 사하구 디비전리그', 'K7', '부산사하'),
            _buildDivisionCard('부산시 동래구 디비전리그', 'K7', '부산동래'),
            _buildDivisionCard('부산시 금정구 디비전리그', 'K7', '부산금정'),
            _buildDivisionCard('부산시 해운대구 디비전 리그', 'K7', '부산해운대'),
            _buildDivisionCard('부산시 수영구 디비전리그', 'K7', '부산수영'),
          ]),

          const SizedBox(height: 24),

          // 크롤링 상태 정보
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sync,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '데이터 수집 현황',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCrawlingStatus('K5 리그', '2개 디비전', Colors.green),
                _buildCrawlingStatus('K6 리그', '3개 디비전', Colors.green),
                _buildCrawlingStatus('K7 리그', '20개 디비전', Colors.orange),
                const SizedBox(height: 8),
                Text(
                  '• 경기 데이터는 JoinKFA에서 자동 수집됩니다\n• 수집된 데이터는 실시간으로 업데이트됩니다',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 조기축구 탭
  Widget _buildMorningFootballTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 조기축구 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.withOpacity(0.8),
                  Colors.orange,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '조기축구 경기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '참여자 직접 등록',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 경기 등록 버튼
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: Colors.orange[600],
                ),
                const SizedBox(height: 16),
                Text(
                  '새 경기 등록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '조기축구 경기 결과를 등록해보세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _showAddMatchDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    '경기 등록하기',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 최근 조기축구 경기 목록
          const Text(
            '최근 경기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // 임시 경기 데이터
          _buildMorningMatchCard(
            '한마음FC vs 수우FC',
            '2024.12.15 07:00',
            '3 - 1',
            '승리',
            Colors.green,
          ),
          _buildMorningMatchCard(
            '한FC vs 기타팀',
            '2024.12.14 07:00',
            '2 - 2',
            '무승부',
            Colors.orange,
          ),
          _buildMorningMatchCard(
            '수우FC vs 기타팀',
            '2024.12.13 07:00',
            '1 - 2',
            '패배',
            Colors.red,
          ),

          const SizedBox(height: 24),

          // 정보 안내
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '조기축구 경기는 참여자가 직접 등록할 수 있습니다.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
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

  // 리그 섹션 빌더
  Widget _buildLeagueSection(String title, Color color, List<Widget> matches) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: matches,
            ),
          ),
        ],
      ),
    );
  }

  // 경기 카드 빌더
  Widget _buildMatchCard(String league, String season, String teams) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  league,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$season • $teams',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  // 디비전 카드 빌더 (새로 추가)
  Widget _buildDivisionCard(String divisionName, String league, String code) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          _showDivisionDetail(divisionName, league, code);
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // 리그 아이콘
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getLeagueColor(league).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                league,
                style: TextStyle(
                  color: _getLeagueColor(league),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    divisionName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2024 시즌 • 데이터 수집 대기',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 상태 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '준비중',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // 크롤링 상태 빌더 (새로 추가)
  Widget _buildCrawlingStatus(
      String league, String divisions, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$league: $divisions',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            statusColor == Colors.green ? '수집완료' : '수집중',
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 리그별 색상 반환
  Color _getLeagueColor(String league) {
    switch (league) {
      case 'K5':
        return Colors.red;
      case 'K6':
        return Colors.green;
      case 'K7':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // 디비전 상세 정보 표시
  void _showDivisionDetail(String divisionName, String league, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(divisionName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('리그: $league'),
            Text('코드: $code'),
            const SizedBox(height: 16),
            const Text(
              '경기 데이터 크롤링 기능이 곧 추가됩니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 조기축구 경기 카드 빌더
  Widget _buildMorningMatchCard(
    String teams,
    String date,
    String score,
    String result,
    Color resultColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teams,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result,
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 경기 등록 다이얼로그
  void _showAddMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('경기 등록'),
        content: const Text('조기축구 경기 등록 기능이 곧 추가됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
