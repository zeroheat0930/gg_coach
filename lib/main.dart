import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// MyApp 클래스: 우리 앱 전체의 시작점 및 기본 설정을 담당합니다.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp은 우리 앱의 총괄 매니저 같은 역할입니다.
    // 앱의 테마, 이름, 첫 화면 등을 여기서 정합니다.
    return MaterialApp(
      title: 'GG Coach', // 앱의 이름
      theme: ThemeData(
        primarySwatch: Colors.blue, // 앱의 기본 색상 테마
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SearchScreen(), // 앱이 실행될 때 가장 먼저 보여줄 화면
    );
  }
}

// SearchScreen 클래스: '선수 검색' 화면을 담당할 위젯입니다.
// 지금은 비어있지만, 앞으로 여기에 입력창과 버튼을 추가할 겁니다.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    // Scaffold는 화면의 구조를 잡아주는 '도화지' 같은 역할입니다.
    // appBar(상단바), body(본문) 등을 쉽게 구성할 수 있습니다.
    return Scaffold(
      appBar: AppBar(
        title: const Text('GG Coach 선수 검색'), // 화면 상단에 보일 제목
      ),
      body: const Center(
        // 지금은 화면 중앙에 '검색 화면입니다'라는 글씨만 보여줍니다.
        child: Text('검색 화면입니다.'),
      ),
    );
  }
}