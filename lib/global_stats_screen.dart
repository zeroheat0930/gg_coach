import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 라이브러리

class GlobalStatsScreen extends StatefulWidget {
  const GlobalStatsScreen({super.key});

  @override
  State<GlobalStatsScreen> createState() => _GlobalStatsScreenState();
}

class _GlobalStatsScreenState extends State<GlobalStatsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  // Firestore에서 가져온 데이터를 담을 변수
  List<dynamic> _topWeapons = [];
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchMetaFromFirestore();
  }

  // ### 여기가 완전히 새로운 부분입니다! ###
  // Firestore DB에서 직접 데이터를 가져오는 함수
  Future<void> _fetchMetaFromFirestore() async {
    try {
      // 'global_stats' 컬렉션의 'weapon_meta' 문서를 가져옵니다.
      final docSnapshot = await FirebaseFirestore.instance
          .collection('global_stats')
          .doc('weapon_meta')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (mounted && data != null) {
          setState(() {
            _topWeapons = data['topWeapons'] ?? [];
            // Timestamp를 DateTime으로 변환
            _lastUpdated = (data['updatedAt'] as Timestamp?)?.toDate();
            _isLoading = false;
          });
        }
      } else {
        // DB에 아직 데이터가 없는 경우 (Cloud Function이 아직 실행되지 않음)
        throw Exception('아직 집계된 데이터가 없습니다. 데이터 수집 로봇이 곧 실행될 예정입니다.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    if (_topWeapons.isEmpty) return const Center(child: Text('표시할 무기 메타 정보가 없습니다.'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '최신 무기 선호도 Top 10',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // 데이터가 언제 업데이트되었는지 표시
        if (_lastUpdated != null)
          Text(
            '마지막 업데이트: ${_lastUpdated!.toLocal()}',
            style: const TextStyle(color: Colors.grey),
          ),
        const Divider(height: 32),
        ..._topWeapons.map((weaponData) {
          // 데이터 구조가 Cloud Function에서 저장한 형식에 맞게 변경되었습니다.
          final rank = weaponData['rank'];
          final weaponId = weaponData['weaponId'];
          final pickCount = weaponData['pickCount'];
          final displayedName = weaponId.replaceAll('Item_Weapon_', '').replaceAll('_C', '');

          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('$rank')),
              title: Text(displayedName, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('$pickCount Pick(s)', style: const TextStyle(fontSize: 16)),
            ),
          );
        }),
      ],
    );
  }
}