import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gg_coach/api_key.dart'; // API 키를 가져옵니다.

// 결과 화면을 StatefulWidget으로 변경합니다.
// 데이터를 불러오는 동안 '로딩 중' 상태를 표시해야 하기 때문입니다.
class ResultScreen extends StatefulWidget {
  final String nickname;
  final String playerId;
  final List<dynamic> matchIds; // 경기 ID 목록을 받습니다.

  const ResultScreen({
    super.key,
    required this.nickname,
    required this.playerId,
    required this.matchIds,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  String _loadingMessage = '최근 경기 목록을 불러오는 중...';
  final List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _fetchMatchDetails();
  }

  Future<void> _fetchMatchDetails() async {
    int loadedMatches = 0;
    // 최근 5경기만 가져오도록 제한 (너무 많으면 API 호출이 많아짐)
    final recentMatchIds = widget.matchIds.take(5);

    for (var match in recentMatchIds) {
      final matchId = match['id'];
      // steam 또는 kakao (main.dart와 동일한 서버로 맞춰주세요)
      final url = Uri.parse('https://api.pubg.com/shards/steam/matches/$matchId');

      try {
        final response = await http.get(url, headers: {
          'Authorization': 'Bearer $pubgApiKey',
          'Accept': 'application/vnd.api+json',
        });

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // ### 여기가 핵심! ###
          // 경기 데이터에 포함된 모든 참가자 목록을 가져옵니다.
          final List<dynamic> participants = data['included'];

          // 참가자 목록에서 '나'의 데이터를 찾습니다.
          final myStats = participants.firstWhere(
                (p) => p['type'] == 'participant' && p['attributes']['stats']['playerId'] == widget.playerId,
            orElse: () => null, // 못 찾으면 null 반환
          );

          if (myStats != null) {
            final stats = myStats['attributes']['stats'];
            // 필요한 정보(등수, 킬, 대미지)만 추출해서 리스트에 추가합니다.
            _matches.add({
              'map': data['data']['attributes']['mapName'],
              'gameMode': data['data']['attributes']['gameMode'],
              'rank': stats['winPlace'],
              'kills': stats['kills'],
              'damage': stats['damageDealt'],
            });
          }
        }
      } catch (e) {
        print('Error fetching match $matchId: $e');
      }

      loadedMatches++;
      setState(() {
        _loadingMessage = '경기 정보 분석 중... ($loadedMatches/${recentMatchIds.length})';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.nickname}님의 전적'),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(_loadingMessage),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final matchData = _matches[index];
          // 데이터를 예쁘게 보여줄 Card 위젯 사용
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('${matchData['rank']}')),
              title: Text('맵: ${matchData['map']} (${matchData['gameMode']})'),
              subtitle: Text('Kills: ${matchData['kills'] ?? 0} / Damage: ${(matchData['damage'] ?? 0).round()}'),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          );
        },
      ),
    );
  }
}