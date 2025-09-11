import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gg_coach/api_key.dart';

class ProfileScreen extends StatefulWidget {
  final String nickname;
  final String playerId;
  final List<dynamic> matchIds;

  const ProfileScreen({
    super.key,
    required this.nickname,
    required this.playerId,
    required this.matchIds,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _loadingMessage = '데이터를 불러오는 중...';
  List<Map<String, dynamic>> _matches = [];
  Map<String, dynamic> _lifetimeStats = {};

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchLifetimeStats(),
      _fetchMatchDetails(),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLifetimeStats() async {
    if (!mounted) return;
    setState(() { _loadingMessage = '평생 통계 요약 중...'; });
    final url = Uri.parse('https://api.pubg.com/shards/steam/players/${widget.playerId}/seasons/lifetime');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $pubgApiKey',
        'Accept': 'application/vnd.api+json',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _lifetimeStats = data['data']['attributes']['gameModeStats']['squad-fpp'];
          });
        }
      }
    } catch (e) {
      print('Error fetching lifetime stats: $e');
    }
  }

  Future<void> _fetchMatchDetails() async {
    if (!mounted) return;
    setState(() { _loadingMessage = '최근 경기 목록 불러오는 중...'; });
    List<Map<String, dynamic>> fetchedMatches = [];
    final recentMatchIds = widget.matchIds.take(5);

    for (var match in recentMatchIds) {
      if (!mounted) return;
      final matchId = match['id'];
      final url = Uri.parse('https://api.pubg.com/shards/steam/matches/$matchId');
      try {
        final response = await http.get(url, headers: {
          'Authorization': 'Bearer $pubgApiKey',
          'Accept': 'application/vnd.api+json',
        });
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final participants = data['included'];
          final myStats = participants.firstWhere((p) => p['type'] == 'participant' && p['attributes']['stats']['playerId'] == widget.playerId, orElse: () => null);
          if (myStats != null) {
            final stats = myStats['attributes']['stats'];
            fetchedMatches.add({
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
    }
    if (mounted) {
      setState(() {
        _matches = fetchedMatches;
      });
    }
  }

  // AI 분석 함수 (통째로 추가)
  Future<void> _getAiAnalysis(Map<String, dynamic> matchData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

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
        analysisResult = 'AI 서버 응답 에러: Status Code ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      analysisResult = 'AI 호출 중 에러 발생: $e';
    }

    Navigator.pop(context); // 로딩 팝업 닫기

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('🤖 AI 코치 분석'),
          content: SingleChildScrollView(child: Text(analysisResult)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const CircularProgressIndicator(), const SizedBox(height: 10), Text(_loadingMessage)],
        ),
      );
    }

    Widget buildStatCard(String title, dynamic value, {String? subValue}) {
      return Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (subValue != null) Text(subValue, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    final kda = _lifetimeStats['kda']?.toStringAsFixed(2) ?? 'N/A';
    final wins = _lifetimeStats['wins'] ?? 0;
    final top10s = _lifetimeStats['top10s'] ?? 0;
    final roundsPlayed = _lifetimeStats['roundsPlayed'] ?? 1;
    final winRate = roundsPlayed > 0 ? (wins / roundsPlayed * 100).toStringAsFixed(1) : '0';
    final top10Rate = roundsPlayed > 0 ? (top10s / roundsPlayed * 100).toStringAsFixed(1) : '0';

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.nickname, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('평생 통계 (스쿼드 FPP)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  buildStatCard('K/D', kda),
                  buildStatCard('승률', '$winRate%', subValue: '$wins승'),
                  buildStatCard('Top 10', '$top10Rate%', subValue: '$top10s회'),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('최근 경기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _matches.length,
          itemBuilder: (context, index) {
            final matchData = _matches[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ExpansionTile(
                leading: CircleAvatar(
                  radius: 25,
                  child: Text(
                    '${matchData['rank']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  backgroundColor: (matchData['rank'] == 1) ? Colors.amber[200] : Colors.grey[300],
                ),
                title: Text(
                  '${matchData['map']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Kills: ${matchData['kills'] ?? 0} / Damage: ${(matchData['damage'] ?? 0).round()}'),
                children: <Widget>[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('게임 모드'),
                          Text('${matchData['gameMode']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Kills'),
                          Text('${matchData['kills'] ?? 0}'),
                        ]),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Damage Dealt'),
                          Text('${(matchData['damage'] ?? 0).round()}'),
                        ]),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.psychology),
                          label: const Text('AI 코치 분석 보기'),
                          onPressed: () => _getAiAnalysis(matchData),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}