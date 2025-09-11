import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gg_coach/api_key.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  final String nickname;
  final String playerId;

  const StatsScreen({
    super.key,
    required this.nickname,
    required this.playerId,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _fetchPlayerMatches(widget.playerId);
  }

  Future<void> _fetchPlayerMatches(String playerId) async {
    final playerUrl = Uri.parse('https://api.pubg.com/shards/steam/players/$playerId');
    final playerResponse = await http.get(playerUrl, headers: {'Authorization': 'Bearer $pubgApiKey', 'Accept': 'application/vnd.api+json'});
    if (playerResponse.statusCode == 200) {
      final playerData = json.decode(playerResponse.body);
      final List<dynamic> matchIds = playerData['data']['relationships']['matches']['data'].take(10).toList();
      List<Map<String, dynamic>> fetchedMatches = [];

      for (var match in matchIds) {
        final matchId = match['id'];
        final matchUrl = Uri.parse('https://api.pubg.com/shards/steam/matches/$matchId');
        final matchResponse = await http.get(matchUrl, headers: {'Authorization': 'Bearer $pubgApiKey', 'Accept': 'application/vnd.api+json'});
        if (matchResponse.statusCode == 200) {
          final data = json.decode(matchResponse.body);
          final participants = data['included'];
          final totalTeams = participants.where((p) => p['type'] == 'roster').length;
          final myStats = participants.firstWhere((p) => p['type'] == 'participant' && p['attributes']['stats']['playerId'] == playerId, orElse: () => null);
          if (myStats != null) {
            final rank = myStats['attributes']['stats']['winPlace'];
            if (rank != null && rank is num && totalTeams > 1) {
              final score = ((totalTeams - rank) / (totalTeams - 1)) * 100;
              if (!score.isNaN && !score.isInfinite) {
                fetchedMatches.add({'rank': rank, 'score': score.toDouble()});
              }
            }
          }
        }
      }
      if (mounted) {
        setState(() { _matches = fetchedMatches.reversed.toList(); });
      }
    }
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_matches.isEmpty) {
      return const Center(child: Text('그래프를 표시할 유효한 경기 데이터가 부족합니다.'));
    }

    final List<Map<String, dynamic>> validMatches = _matches.where((match) {
      final score = match['score'];
      return score != null && score is num;
    }).toList();

    if (validMatches.isEmpty) {
      return const Center(child: Text('그래프를 표시할 유효한 경기 데이터가 부족합니다.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.nickname}님의 성장 리포트', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('최근 10경기 성과 점수', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value % 20 == 0) {
                          return Padding(padding: const EdgeInsets.only(right: 8.0), child: Text('${value.toInt()}', style: const TextStyle(fontSize: 10)));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: validMatches.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['score']);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}