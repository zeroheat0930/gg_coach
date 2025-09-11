import 'package:flutter/material.dart';
import 'package:gg_coach/api_key.dart';
import 'package:gg_coach/profile_screen.dart';
import 'package:gg_coach/stats_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// HomeScreen: 앱의 전체적인 뼈대를 관리하는 최상위 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _searchedPlayer; // 검색된 플레이어 정보

  // 하단 탭 관련 상태 변수
  int _bottomNavIndex = 0;

  Future<void> _searchPlayer(String nickname) async {
    if (nickname.isEmpty) return;
    FocusScope.of(context).unfocus(); // 검색 후 키보드 숨기기
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://api.pubg.com/shards/steam/players?filter[playerNames]=$nickname');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $pubgApiKey',
        'Accept': 'application/vnd.api+json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchedPlayer = {
            'nickname': nickname,
            'playerId': data['data'][0]['id'],
            'matchIds': data['data'][0]['relationships']['matches']['data'],
          };
          _bottomNavIndex = 0; // 검색 성공 시 '홈' 탭으로 초기화
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('플레이어를 찾을 수 없습니다 (에러: ${response.statusCode})')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('검색 중 에러 발생: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 현재 상태에 따라 중앙에 보여줄 콘텐츠를 결정하는 함수
  Widget _buildBody() {
    if (_searchedPlayer == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('상단 검색창에서 플레이어를 검색하세요.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    switch (_bottomNavIndex) {
      case 0: // 홈 (검색 결과)
        return PlayerDataTabs(playerData: _searchedPlayer!);
      case 1: // 알림
        return const Center(child: Text('알림 화면입니다. (구현 예정)'));
      case 2: // 설정
        return const Center(child: Text('설정 화면입니다. (구현 예정)'));
      default:
        return PlayerDataTabs(playerData: _searchedPlayer!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '플레이어 닉네임 검색...',
            border: InputBorder.none,
            suffixIcon: _isLoading
                ? const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0)),
            )
                : IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _searchPlayer(_searchController.text),
            ),
          ),
          onSubmitted: (value) => _searchPlayer(value),
        ),
      ),
      body: _buildBody(),

      // 커스텀 하단 네비게이션 바
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 검색된 플레이어 정보를 null로 만들어 초기 화면으로 되돌립니다.
          setState(() {
            _searchedPlayer = null;
            _searchController.clear(); // 검색창도 깨끗하게 비워줍니다.
          });
        },
        child: const Icon(Icons.home), // 아이콘을 'PUBG' 로고 이미지로 바꾸면 더 멋지겠죠!
        backgroundColor: Colors.blueAccent,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              tooltip: '알림',
              icon: Icon(Icons.notifications, color: _bottomNavIndex == 1 ? Colors.blueAccent : Colors.grey),
              onPressed: () {
                setState(() {
                  _bottomNavIndex = 1;
                });
              },
            ),
            const SizedBox(width: 40), // FAB가 차지할 공간
            IconButton(
              tooltip: '설정',
              icon: Icon(Icons.settings, color: _bottomNavIndex == 2 ? Colors.blueAccent : Colors.grey),
              onPressed: () {
                setState(() {
                  _bottomNavIndex = 2;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 검색 성공 후 '홈' 탭에 보여줄 위젯.
// 이 위젯 안에 '프로필'과 '성장 리포트' 탭을 넣습니다.
class PlayerDataTabs extends StatefulWidget {
  final Map<String, dynamic> playerData;
  const PlayerDataTabs({super.key, required this.playerData});

  @override
  State<PlayerDataTabs> createState() => _PlayerDataTabsState();
}

class _PlayerDataTabsState extends State<PlayerDataTabs> with SingleTickerProviderStateMixin {
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '프로필'),
            Tab(text: '성장 리포트'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ProfileScreen(
                nickname: widget.playerData['nickname'],
                playerId: widget.playerData['playerId'],
                matchIds: widget.playerData['matchIds'],
              ),
              StatsScreen(
                nickname: widget.playerData['nickname'],
                playerId: widget.playerData['playerId'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}