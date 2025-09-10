import 'package:flutter/material.dart';

// 검색 결과를 보여줄 새로운 화면 위젯입니다.
class ResultScreen extends StatelessWidget {
  final String nickname;
  final String playerId;

  // 이전 화면에서 닉네임과 플레이어 ID를 전달받습니다.
  const ResultScreen({
    super.key,
    required this.nickname,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$nickname님의 전적'), // 상단바에 닉네임 표시
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 자식 위젯들을 왼쪽으로 정렬
          children: [
            // 플레이어 정보를 보여줄 카드
            Card(
              elevation: 4,
              child: ListTile(
                title: Text(
                  nickname,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                subtitle: Text('Player ID: $playerId'),
                leading: const Icon(Icons.person, size: 40),
              ),
            ),

            const SizedBox(height: 20), // 간격

            // 최근 전적 목록 타이틀
            const Text(
              '최근 전적 (Placeholder)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(), // 구분선

            // 앞으로 실제 전적 목록이 들어갈 리스트뷰 (지금은 가짜 데이터)
            Expanded(
              child: ListView.builder(
                itemCount: 5, // 가짜 데이터 5개
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.videogame_asset),
                    title: Text('경기 #${index + 1}'),
                    subtitle: const Text('맵: 에란겔 / 결과: 10등'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}