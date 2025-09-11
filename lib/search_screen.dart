import 'package:flutter/material.dart';
import 'package:gg_coach/main_screen.dart';
import 'package:gg_coach/api_key.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// SearchScreen 클래스: '선수 검색' 화면을 담당할 위젯입니다.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String _searchResult = '';

  Future<void> _searchPlayer(String nickname) async {
    // ... (이 함수 내용은 그대로 유지)
    setState(() { _isLoading = true; _searchResult = ''; });
    const apiKey = pubgApiKey;
    final url = Uri.parse('https://api.pubg.com/shards/steam/players?filter[playerNames]=$nickname');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $apiKey', 'Accept': 'application/vnd.api+json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final player = data['data'][0];
        final playerId = player['id'];
        final List<dynamic> matchIds = player['relationships']['matches']['data'];

        // SharedPreferences를 열고, 검색 성공한 플레이어 정보를 저장합니다.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_searched_nickname', nickname);
        await prefs.setString('last_searched_playerId', playerId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen( // ResultScreen 대신 MainScreen으로 이동!
              nickname: nickname,
              playerId: playerId,
              matchIds: matchIds,
            ),
          ),
        );
      } else {
        setState(() { _searchResult = '플레이어를 찾을 수 없습니다. (에러 코드: ${response.statusCode})'; });
      }
    } catch (e) {
      setState(() { _searchResult = '검색 중 에러가 발생했습니다: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GG Coach 선수 검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '플레이어 닉네임',
                hintText: '대소문자를 정확히 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _searchPlayer(_controller.text),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('검색'),
            ),
            if (_searchResult.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(_searchResult, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}