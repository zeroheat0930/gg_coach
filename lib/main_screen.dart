import 'package:flutter/material.dart';
import 'package:gg_coach/result_screen.dart'; // 전적 결과 화면
import 'package:gg_coach/stats_screen.dart';   // 통계 그래프 화면
import 'package:gg_coach/search_screen.dart'; // search_screen을 가져옵니다.

class MainScreen extends StatefulWidget {
  final String nickname;
  final String playerId;
  final List<dynamic> matchIds;

  const MainScreen({
    super.key,
    required this.nickname,
    required this.playerId,
    required this.matchIds,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  // 탭 별로 다른 제목을 보여주기 위한 리스트
  static const List<String> _appBarTitles = ['최근 전적', '통계 및 리포트'];

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      ResultScreen(
        nickname: widget.nickname,
        playerId: widget.playerId,
        matchIds: widget.matchIds,
      ),
      StatsScreen(
        nickname: widget.nickname,
        playerId: widget.playerId,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar를 MainScreen에서 직접 관리합니다.
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]), // 선택된 탭에 따라 제목 변경
        actions: [
          // ### 여기가 핵심! 새로운 검색 버튼 ###
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '다른 플레이어 검색',
            onPressed: () {
              // 현재 화면을 모두 없애고, 새로운 검색 화면으로 이동합니다.
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
                    (Route<dynamic> route) => false, // 이전 모든 경로를 제거
              );
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '최근 전적',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '통계',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}