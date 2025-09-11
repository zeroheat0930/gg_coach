import 'package:flutter/material.dart';
import 'package:gg_coach/search_screen.dart'; // 방금 분리한 파일

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GG Coach',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 앱의 첫 화면은 이제 무조건 SearchScreen 입니다.
      home: const SearchScreen(),
    );
  }
}