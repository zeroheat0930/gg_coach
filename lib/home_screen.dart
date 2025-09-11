import 'package:flutter/material.dart';
import 'package:gg_coach/search_screen.dart';

// HomeScreen: 이제 정말 앱의 껍데기 역할만 합니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // HomeScreen은 더 이상 플레이어 정보를 관리할 필요가 없습니다.
  int _bottomNavIndex = 0;

  // 현재 선택된 탭에 따라 중앙에 보여줄 위젯
  Widget _buildBody() {
    switch (_bottomNavIndex) {
      case 0: // 홈
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text('상단 검색 아이콘을 눌러\n플레이어를 검색하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        );
      case 1: // 알림
        return const Center(child: Text('알림 화면입니다. (구현 예정)'));
      case 2: // 설정
        return const Center(child: Text('설정 화면입니다. (구현 예정)'));
      default:
        return const Center(child: Text('오류'));
    }
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
            // SearchScreen으로 이동만 시켜줍니다.
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),

      // 하단 네비게이션 바는 이전과 동일
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () { setState(() { _bottomNavIndex = 0; }); },
        child: const Icon(Icons.home),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.notifications, color: _bottomNavIndex == 1 ? Theme.of(context).primaryColor : Colors.grey),
              onPressed: () { setState(() { _bottomNavIndex = 1; }); },
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: Icon(Icons.settings, color: _bottomNavIndex == 2 ? Theme.of(context).primaryColor : Colors.grey),
              onPressed: () { setState(() { _bottomNavIndex = 2; }); },
            ),
          ],
        ),
      ),
    );
  }
}