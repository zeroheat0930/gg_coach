import 'package:flutter/material.dart';
import 'package:gg_coach/home_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase 핵심 라이브러리
import 'firebase_options.dart';                  // FlutterFire CLI가 생성한 설정 파일

void main() async { // 1. main 함수를 비동기로 만듭니다 (async)
  // 2. Flutter 엔진이 위젯을 그릴 준비가 될 때까지 기다립니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 3. 앱이 시작되기 전에 Firebase 설정을 비동기적으로 초기화합니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. 모든 준비가 끝나면 앱을 실행합니다.
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
      home: const HomeScreen(),
    );
  }
}