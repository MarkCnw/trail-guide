// import 'dart:async';
// import 'dart:math';
// import 'package:dartz/dartz.dart';
// import 'package:trail_guide/core/error/failures.dart';
// import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart';
// import 'package:trail_guide/features/p2p/domain/repositories/p2p_repository.dart';

// class MockP2PRepository implements P2PRepository {
//   // ตัวส่งข้อมูลเข้า Stream
//   final _controller = StreamController<List<PeerEntity>>.broadcast();
  
//   // เก็บสถานะเพื่อนปัจจุบัน (ใช้ Map เพื่อให้จัดการง่ายเวลาอัปเดตรายคน)
//   final Map<String, PeerEntity> _currentPeers = {};
  
//   Timer? _timer;
//   final Random _random = Random();

//   // ฐานข้อมูลชื่อสมมติ
//   final List<String> _demoNames = [
//     'Guide Leader', 
//     'Safety Car', 
//     'Nong Som', 
//     'Alex Walker', 
//     'Sarah Croft'
//   ];

//   @override
//   Stream<List<PeerEntity>> get peersStream => _controller.stream;

//   @override
//   Future<Either<Failure, void>> startDiscovery() async {
//     // 1. จำลองการโหลดนิดหน่อย (เหมือน Hardware กำลัง Start)
//     await Future.delayed(const Duration(seconds: 1));

//     // 2. เริ่มลูปจำลองเหตุการณ์
//     _startSimulationLoop();

//     return const Right(null);
//   }

//   @override
//   Future<Either<Failure, void>> stopDiscovery() async {
//     _timer?.cancel();
//     _currentPeers.clear();
//     _controller.add([]); // ส่งลิสต์ว่างไปเพื่อเคลียร์หน้าจอ
//     return const Right(null);
//   }

//   // --- Logic การจำลองสถานการณ์ ---
//   void _startSimulationLoop() {
//     _timer?.cancel();
//     // ทำงานทุกๆ 1.5 วินาที
//     _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      
//       // สุ่มเหตุการณ์ 1: เจอคนใหม่ (ถ้ายังไม่ครบทุกคน)
//       if (_currentPeers.length < _demoNames.length && _random.nextBool()) {
//         final nextIndex = _currentPeers.length;
//         final name = _demoNames[nextIndex];
//         final id = "mock-id-$nextIndex";
        
//         _currentPeers[id] = PeerEntity(
//           id: id,
//           name: name,
//           rssi: -50 - _random.nextInt(20), // สุ่มความแรงสัญญาณ -50 ถึง -70
//           isLost: false,
//         );
//       }

//       // สุ่มเหตุการณ์ 2: อัปเดตสัญญาณเพื่อนทุกคน (ให้ตัวเลข RSSI ขยับไปมา)
//       for (var key in _currentPeers.keys) {
//         final oldPeer = _currentPeers[key]!;
        
//         // จำลองสัญญาณแกว่ง +/- 5 dBm
//         int newRssi = oldPeer.rssi + (_random.nextInt(10) - 5);
        
//         // จำกัดไม่ให้เกินจริง (-30 ถึง -90)
//         if (newRssi > -30) newRssi = -30;
//         if (newRssi < -99) newRssi = -99;

//         // สุ่มสถานะ Lost (นานๆ ทีจะเกิด)
//         // โอกาส 1 ใน 20 ที่จะหลุดระยะ
//         bool isLost = _random.nextInt(20) == 0; 
        
//         // ถ้าหลุดระยะ ให้ RSSI เป็น 0 หรือค่าต่ำสุด
//         if (isLost) newRssi = -100;

//         _currentPeers[key] = PeerEntity(
//           id: oldPeer.id,
//           name: oldPeer.name,
//           rssi: newRssi,
//           isLost: isLost,
//         );
//       }

//       // ส่งข้อมูลชุดใหม่ไปที่หน้าจอ
//       _controller.add(_currentPeers.values.toList());
//     });
//   }
// }