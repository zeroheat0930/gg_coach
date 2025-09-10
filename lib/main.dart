import 'package:flutter/material.dart';
import 'package:gg_coach/result_screen.dart';
import 'package:gg_coach/api_key.dart';
import 'package:http/http.dart' as http; // http 라이브러리를 가져옵니다.
import 'dart:convert'; // JSON 데이터를 다루기 위해 필요합니다.

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
  // 1. TextEditingController를 만들어서 _controller라는 변수에 보관합니다.
  final _controller = TextEditingController();

  // API 호출 상태를 관리할 변수들
  bool _isLoading = false; // 로딩 중인지 여부
  String _searchResult = ''; // 검색 결과 메시지

  // ## 여기가 핵심! 플레이어 검색을 위한 함수 ##
  Future<void> _searchPlayer(String nickname) async {
    // 1. 상태 업데이트: 로딩 시작!
    setState(() {
      _isLoading = true;
      _searchResult = '';
    });

    const apiKey = pubgApiKey;
    final url = Uri.parse('https://api.pubg.com/shards/steam/players?filter[playerNames]=$nickname');

    try {
      // 2. API 서버에 데이터 요청 보내기
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/vnd.api+json',
        },
      );

      // ### 이 부분을 추가해주세요! ###
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      // #############################

      // 3. 응답 결과 처리하기
      if (response.statusCode == 200) {
        // 성공!
        final data = json.decode(response.body);
        final playerId = data['data'][0]['id'];

        // Navigator를 사용해 새로운 화면으로 이동합니다.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              nickname: nickname,
              playerId: playerId,
            ),
          ),
        );
      } else {
        // 실패 (플레이어가 없거나, 오타 등)
        setState(() {
          _searchResult = '플레이어를 찾을 수 없습니다. (에러 코드: ${response.statusCode})';
        });
      }
    } catch (e) {
      // 네트워크 에러 등 예외 발생 시
      setState(() {
        _searchResult = '검색 중 에러가 발생했습니다: $e';
      });
    } finally {
      // 4. 상태 업데이트: 로딩 끝!
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold는 화면의 구조를 잡아주는 '도화지' 같은 역할입니다.
    // appBar(상단바), body(본문) 등을 쉽게 구성할 수 있습니다.
    return Scaffold(
      appBar: AppBar(
        title: const Text('GG Coach 선수 검색'), // 화면 상단에 보일 제목
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 화면 전체에 16만큼의 여백을 줍니다.
        child: Column( // 위젯들을 세로로 배치합니다.
          mainAxisAlignment: MainAxisAlignment.center, // 자식 위젯들을 세로축 중앙에 정렬합니다.
          children: [
            // 닉네임 입력창
            TextField(
              controller: _controller, // 2. 컨트롤러를 TextField에 연결합니다.
              decoration: const InputDecoration(
                labelText: '플레이어 닉네임',
                hintText: '닉네임을 입력하세요',
                helperText: '플레이어 닉네임의 대소문자를 정확히 입력해주세요.',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20), // 입력창과 버튼 사이에 20만큼의 간격을 줍니다.

            // 검색 버튼
            ElevatedButton(
              // 버튼을 누를 때, 로딩 중(_isLoading이 true)이면 버튼을 비활성화(null)하고,
              // 로딩 중이 아니면 _searchPlayer 함수를 실행하라는 의미입니다.
              onPressed: _isLoading ? null : () => _searchPlayer(_controller.text),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white) // 로딩 중일 때 보여줄 위젯
                  : const Text('검색'), // 평상시에 보여줄 위젯
            ),
          ],
        ),
      ),
    );
  }
}