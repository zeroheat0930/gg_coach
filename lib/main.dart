import 'package:flutter/material.dart';
import 'package:gg_coach/home_screen.dart'; // 앱의 유일한 시작 화면

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
      // 앱의 첫 화면은 이제 HomeScreen 입니다.
      home: const HomeScreen(),
    );
  }
}