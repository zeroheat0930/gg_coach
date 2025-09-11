import 'package:flutter/material.dart';
import 'package:gg_coach/leaderboard_screen.dart';
import 'package:gg_coach/profile_screen.dart';
import 'package:gg_coach/search_screen.dart';
import 'package:gg_coach/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// TabController를 사용하기 위해 'with SingleTickerProviderStateMixin'를 추가해야 합니다.
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _searchedPlayer;
  int _bottomNavIndex = 0;

  // 검색 전 글로벌 정보를 보여줄 서브 탭 컨트롤러
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 탭 4개를 가진 TabController를 초기화합니다.
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 검색 화면으로 이동하고, 그 결과를 받아오는 함수
  Future<void> _navigateToSearchScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _searchedPlayer = result;
        _bottomNavIndex = 0; // 검색 성공 시, 하단 탭은 '홈'으로 강제 이동
      });
    }
  }

  // 현재 상태에 따라 중앙에 보여줄 콘텐츠를 결정하는 함수
  Widget _buildBody() {
    // 하단 탭 인덱스에 따라 다른 화면을 보여줍니다.
    switch (_bottomNavIndex) {
      case 0: // 홈 탭
        return _searchedPlayer == null
            ? _buildGlobalTabs() // 검색 전: 글로벌 정보 탭
            : PlayerDataTabs(playerData: _searchedPlayer!); // 검색 후: 플레이어 정보 탭
      case 1: // 알림 탭
        return const NotificationScreen();
      case 2: // 설정 탭
        return const SettingsScreen();
      default:
        return _buildGlobalTabs();
    }
  }

  // 검색 전 상태에서 보여줄 글로벌 정보 탭 위젯
  Widget _buildGlobalTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '홈'),
            Tab(text: '통계'),
            Tab(text: '순위표'),
            Tab(text: '즐겨찾기'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 각 서브 탭에 해당하는 화면들
              const LeaderboardScreen(), // 우리가 만든 리더보드 화면
              const Center(child: Text('글로벌 홈 콘텐츠 (구현 예정)')),
              const Center(child: Text('글로벌 통계 콘텐츠 (구현 예정)')),
              const Center(child: Text('즐겨찾기 목록 (구현 예정)')),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GG Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '플레이어 검색',
            onPressed: _navigateToSearchScreen,
          ),
        ],
      ),
      body: _buildBody(),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 홈 버튼을 누르면 검색 결과를 초기화하고 글로벌 탭 화면으로 돌아갑니다.
          setState(() {
            _searchedPlayer = null;
            _bottomNavIndex = 0;
          });
        },
        child: const Icon(Icons.home),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              tooltip: '알림',
              icon: Icon(Icons.notifications, color: _bottomNavIndex == 1 ? Theme.of(context).primaryColor : Colors.grey),
              onPressed: () { setState(() { _bottomNavIndex = 1; }); },
            ),
            const SizedBox(width: 40),
            IconButton(
              tooltip: '설정',
              icon: Icon(Icons.settings, color: _bottomNavIndex == 2 ? Theme.of(context).primaryColor : Colors.grey),
              onPressed: () { setState(() { _bottomNavIndex = 2; }); },
            ),
          ],
        ),
      ),
    );
  }
}

// --- 아래 위젯들은 HomeScreen 파일 안에서 함께 관리합니다 ---

class PlayerDataTabs extends StatefulWidget {
  final Map<String, dynamic> playerData;
  const PlayerDataTabs({super.key, required this.playerData});
  @override
  State<PlayerDataTabs> createState() => _PlayerDataTabsState();
}
class _PlayerDataTabsState extends State<PlayerDataTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [ Tab(text: '프로필 요약'), Tab(text: '성장 리포트') ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ProfileScreen(nickname: widget.playerData['nickname'], playerId: widget.playerData['playerId'], matchIds: widget.playerData['matchIds']),
              StatsScreen(nickname: widget.playerData['nickname'], playerId: widget.playerData['playerId']),
            ],
          ),
        ),
      ],
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: const Center(child: Text('알림 화면입니다. (구현 예정)')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: const Center(child: Text('설정 화면입니다. (구현 예정)')),
    );
  }
}