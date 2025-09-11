import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계 및 리포트'),
      ),
      body: const Center(
        child: Text(
          '여기에 성장 그래프가 표시될 예정입니다.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}