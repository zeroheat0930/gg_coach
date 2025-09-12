import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gg_coach/api_key.dart';
import 'package:gg_coach/player_data_tabs.dart'; // 분리된 PlayerDataTabs 위젯을 가져옵니다.

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _steamLeaderboard = [];
  List<Map<String, dynamic>> _kakaoLeaderboard = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLeaderboards();
  }

  Future<void> _fetchLeaderboards() async {
    try {
      final seasonsUrl = Uri.parse('https://api.pubg.com/shards/pc-as/seasons');
      final seasonsResponse = await http.get(seasonsUrl, headers: {'Authorization': 'Bearer $pubgApiKey', 'Accept': 'application/vnd.api+json'});
      if (seasonsResponse.statusCode != 200) throw Exception('시즌 정보 로딩 실패');

      final seasonsData = json.decode(seasonsResponse.body);
      final currentSeason = seasonsData['data'].firstWhere((s) => s['attributes']['isCurrentSeason'] == true, orElse: () => null);
      if (currentSeason == null) throw Exception('현재 시즌 정보 없음');
      final seasonId = currentSeason['id'];

      const gameMode = 'squad-fpp';

      Future<http.Response> fetchPcAs = http.get(
        Uri.parse('https://api.pubg.com/shards/pc-as/leaderboards/$seasonId/$gameMode'),
        headers: {'Authorization': 'Bearer $pubgApiKey', 'Accept': 'application/vnd.api+json'},
      );
      Future<http.Response> fetchKakao = http.get(
        Uri.parse('https://api.pubg.com/shards/pc-kakao/leaderboards/$seasonId/$gameMode'),
        headers: {'Authorization': 'Bearer $pubgApiKey', 'Accept': 'application/vnd.api+json'},
      );

      final responses = await Future.wait([fetchPcAs, fetchKakao]);

      if (mounted) {
        setState(() {
          if (responses[0].statusCode == 200) {
            _steamLeaderboard = _processLeaderboardResponse(json.decode(responses[0].body));
          }
          if (responses[1].statusCode == 200) {
            _kakaoLeaderboard = _processLeaderboardResponse(json.decode(responses[1].body));
          }
        });
      }

    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> _processLeaderboardResponse(Map<String, dynamic> data) {
    final List<dynamic> includedPlayers = data['included'].where((item) => item['type'] == 'player').toList();
    final List<dynamic> rankedPlayerIds = data['data']['relationships']['players']['data'];

    List<Map<String, dynamic>> processedList = [];
    for (var playerInfo in includedPlayers) {
      final playerId = playerInfo['id'];
      final rank = rankedPlayerIds.indexWhere((p) => p['id'] == playerId) + 1;

      if (rank > 0) {
        final newPlayerMap = Map<String, dynamic>.from(playerInfo);
        newPlayerMap['rank'] = rank;
        processedList.add(newPlayerMap);
      }
    }
    processedList.sort((a, b) => a['rank'].compareTo(b['rank']));
    return processedList;
  }

  // 플레이어 프로필 화면으로 이동하는 함수
  Future<void> _navigateToPlayerProfile(String nickname, String playerId, String shard) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 플레이어의 최신 matchId 목록을 가져와야 합니다.
    // 리더보드는 pc-as, pc-kakao shard를 쓰지만, player 검색은 steam, kakao shard를 씁니다.
    final platform = shard == 'Steam' ? 'steam' : 'kakao';
    final url = Uri.parse('https://api.pubg.com/shards/$platform/players/$playerId');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $pubgApiKey', 'Accept': 'application/vnd.api+json'});
      Navigator.pop(context); // 로딩 닫기

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final player = data['data'];
        final playerData = {
          'nickname': nickname,
          'playerId': playerId,
          'matchIds': player['relationships']['matches']['data'],
        };

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text('$nickname님의 프로필')),
                body: PlayerDataTabs(playerData: playerData),
              )
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('플레이어 정보를 불러오는데 실패했습니다.')));
      }
    } catch(e) {
      Navigator.pop(context); // 로딩 닫기
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));

    Widget buildRankSection(String title, List<Map<String, dynamic>> players, String shardName) {
      final top10 = players.take(10).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  const Expanded(child: Text('플레이어', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 80, child: Text('RP', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 60, child: Text('KDA', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: top10.length,
            itemBuilder: (context, index) {
              final player = top10[index];
              final attributes = player['attributes'];
              final rank = player['rank'] ?? 0;
              final playerName = attributes['name'] ?? 'Unknown';
              final playerId = player['id'];
              final stats = attributes['stats'];
              final kda = (stats?['kda'] as num?)?.toStringAsFixed(2) ?? 'N/A';
              final rp = stats?['rankPoints']?.round() ?? 0;

              return ListTile(
                leading: SizedBox(width: 24, child: Center(child: Text('$rank', style: TextStyle(fontSize: 16, color: Colors.grey[700])))),
                title: Text(playerName),
                trailing: SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(width: 80, child: Text('$rp RP', textAlign: TextAlign.right)),
                      SizedBox(width: 60, child: Text(kda, textAlign: TextAlign.right, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                onTap: () {
                  _navigateToPlayerProfile(playerName, playerId, shardName);
                },
              );
            },
          )
        ],
      );
    }

    return ListView(
      children: [
        if (_steamLeaderboard.isNotEmpty) buildRankSection('🏆 Steam 경쟁전 TOP 10', _steamLeaderboard, 'Steam'),
        const SizedBox(height: 20),
        if (_kakaoLeaderboard.isNotEmpty) buildRankSection('🇰 KR 카카오 경쟁전 TOP 10', _kakaoLeaderboard, 'Kakao'),
      ],
    );
  }
}