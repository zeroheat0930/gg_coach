import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gg_coach/api_key.dart';
import 'package:gg_coach/profile_screen.dart';
import 'package:gg_coach/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<String> _recentSearches = [];
  Map<String, dynamic>? _searchedPlayer; // 검색 결과를 이 화면의 상태로 관리

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _recentSearches = prefs.getStringList('recent_searches') ?? []; });
  }

  Future<void> _saveAndSearch(String nickname) async {
    if (nickname.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(nickname);
    _recentSearches.insert(0, nickname);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    await prefs.setStringList('recent_searches', _recentSearches);
    _searchPlayer(nickname);
  }

  Future<void> _searchPlayer(String nickname) async {
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; });
    final url = Uri.parse('https://api.pubg.com/shards/steam/players?filter[playerNames]=$nickname');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $pubgApiKey', 'Accept': 'application/vnd.api+json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // 검색 성공 시, Navigator.pop 대신 setState로 상태를 업데이트!
        setState(() {
          _searchedPlayer = {
            'nickname': nickname,
            'playerId': data['data'][0]['id'],
            'matchIds': data['data'][0]['relationships']['matches']['data'],
          };
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('플레이어를 찾을 수 없습니다 (에러: ${response.statusCode})')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('검색 중 에러 발생: $e')));
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  // 검색 결과를 초기화하고 최근 검색 목록으로 돌아가는 함수
  void _clearSearch() {
    setState(() {
      _searchedPlayer = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 검색 결과가 있으면 뒤로가기 버튼(초기화 기능)을 보여주고, 없으면 안 보여줌
        leading: _searchedPlayer != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        )
            : null,
        title: _searchedPlayer == null
            ? TextField(controller: _searchController, autofocus: true, decoration: const InputDecoration(hintText: '플레이어 닉네임 검색...', border: InputBorder.none), onSubmitted: _saveAndSearch)
            : Text(_searchedPlayer!['nickname'], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _searchedPlayer == null
              ? IconButton(icon: const Icon(Icons.search), onPressed: () => _saveAndSearch(_searchController.text))
              : const SizedBox.shrink(), // 검색 후에는 돋보기 아이콘 숨김
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchedPlayer == null
          ? ListView.builder( // 검색 전: 최근 검색 목록
        itemCount: _recentSearches.length,
        itemBuilder: (context, index) {
          final nickname = _recentSearches[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(nickname),
            onTap: () { _searchController.text = nickname; _saveAndSearch(nickname); },
          );
        },
      )
          : PlayerDataTabs(playerData: _searchedPlayer!), // 검색 후: 플레이어 데이터 탭
    );
  }
}

// PlayerDataTabs 위젯을 home_screen에서 이곳으로 옮겨옵니다.
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
  void dispose() { _tabController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [ Tab(text: '프로필 요약'), Tab(text: '성장 리포트') ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ProfileScreen(nickname: widget.playerData['nickname'], playerId: widget.playerData['playerId'], matchIds: widget.playerData['matchIds']),
              StatsScreen(nickname: widget.playerData['nickname'], playerId: widget.playerData['playerId']),
            ],
          ),
        ),
      ],
    );
  }
}