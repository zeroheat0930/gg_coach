import 'package:flutter/material.dart';
import 'package:gg_coach/profile_screen.dart';
import 'package:gg_coach/stats_screen.dart';

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              ProfileScreen(
                nickname: widget.playerData['nickname'],
                playerId: widget.playerData['playerId'],
                matchIds: widget.playerData['matchIds'],
              ),
              StatsScreen(
                nickname: widget.playerData['nickname'],
                playerId: widget.playerData['playerId'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}