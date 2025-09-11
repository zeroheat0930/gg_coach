import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gg_coach/api_key.dart';

class ResultScreen extends StatefulWidget {
  final String nickname;
  final String playerId;
  final List<dynamic> matchIds;

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
    // ... (이 함수는 이전과 동일합니다)
    int loadedMatches = 0;
    final recentMatchIds = widget.matchIds.take(5);

    for (var match in recentMatchIds) {
      final matchId = match['id'];
      final url = Uri.parse('https://api.pubg.com/shards/steam/matches/$matchId');

      try {
        final response = await http.get(url, headers: {
          'Authorization': 'Bearer $pubgApiKey',
          'Accept': 'application/vnd.api+json',
        });

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> participants = data['included'];
          final myStats = participants.firstWhere(
            (p) => p['type'] == 'participant' && p['attributes']['stats']['playerId'] == widget.playerId,
            orElse: () => null,
          );

          if (myStats != null) {
            final stats = myStats['attributes']['stats'];
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
      setState(() { _loadingMessage = '경기 정보 분석 중... ($loadedMatches/${recentMatchIds.length})'; });
    }
    setState(() { _isLoading = false; });
  }

  // ### AI 분석 함수 (새로 추가!) ###
  Future<void> _getAiAnalysis(Map<String, dynamic> matchData) async {
    // 1. 로딩 팝업 보여주기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 2. Gemini API에 보낼 프롬프트(지시서) 작성
    final prompt = '''
    당신은 세계 최고의 배틀그라운드 프로 코치입니다.
    아래 경기 데이터를 보고, 이 플레이어의 플레이를 한 문장으로 요약하고, 
    다음 경기를 위해 개선할 점 딱 한 가지만 구체적인 조언을 해주세요. 친절하지만 핵심을 찌르는 말투로 설명해주세요.

    [경기 데이터]
    - 맵: ${matchData['map']}
    - 게임 모드: ${matchData['gameMode']}
    - 최종 등수: ${matchData['rank']}등
    - 킬: ${matchData['kills']}킬
    - 입힌 대미지: ${matchData['damage'].round()}
    ''';

    // 3. Gemini API 호출
    String analysisResult = '분석 중 에러가 발생했습니다.';
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [{'parts': [{'text': prompt}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        analysisResult = data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        analysisResult = 'AI 서버 응답 에러: ${response.statusCode}';
      }
    } catch (e) {
      analysisResult = 'AI 호출 중 에러 발생: $e';
    }

    // 4. 로딩 팝업 닫기
    Navigator.pop(context);

    // 5. 결과 팝업 보여주기
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('🤖 AI 코치 분석'),
          content: Text(analysisResult),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return _isLoading
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 10), Text(_loadingMessage)]))
          : ListView.builder(
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final matchData = _matches[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    // 등수를 보여주는 부분
                    leading: CircleAvatar(
                      radius: 25,
                      child: Text(
                        '${matchData['rank']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      // 1등이면 금색으로!
                      backgroundColor: (matchData['rank'] == 1) ? Colors.amber[200] : Colors.grey[300],
                    ),
                    // 맵 이름과 게임 모드를 보여주는 부분
                    title: Text(
                      '${matchData['map']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // 킬과 대미지를 아이콘과 함께 보여주는 부분
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.dangerous_outlined, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('${matchData['kills'] ?? 0} kills'),
                          const SizedBox(width: 16),
                          const Icon(Icons.flash_on, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('${(matchData['damage'] ?? 0).round()} dmg'),
                        ],
                      ),
                    ),
                    // AI 분석 버튼
                    trailing: IconButton(
                      icon: const Icon(Icons.psychology, color: Colors.blue),
                      tooltip: 'AI 분석 보기',
                      onPressed: () => _getAiAnalysis(matchData),
                    ),
                  ),
                );
    });
  }
}