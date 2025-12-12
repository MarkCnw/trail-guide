
import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart';


import 'package:dartz/dartz.dart';
import 'package:trail_guide/core/error/failures.dart';

abstract class P2PRepository {
  // เริ่มค้นหาเพื่อน (Radar Sweep)
  Future<Either<Failure, void>> startDiscovery();

  // หยุดค้นหา
  Future<Either<Failure, void>> stopDiscovery();

  // ฟังเสียงสัญญาณ (Stream) เพื่ออัปเดตหน้าเรดาร์แบบ Real-time
  Stream<List<PeerEntity>> get peersStream;
}