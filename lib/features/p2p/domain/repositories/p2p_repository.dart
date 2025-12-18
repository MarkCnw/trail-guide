import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/peer_entity.dart';

abstract class P2PRepository {
  // Stream สำหรับส่งรายชื่อเพื่อน
  Stream<List<PeerEntity>> get peersStream;

  // ฟังก์ชันหลัก (รับค่า userName และ strategy แล้ว)
  Future<Either<Failure, void>> startDiscovery(String userName, String strategy);
  Future<Either<Failure, void>> startAdvertising(String userName, String strategy);
  
  // ฟังก์ชันหยุด
  Future<Either<Failure, void>> stopDiscovery();
  Future<Either<Failure, void>> stopAdvertising();
  Future<Either<Failure, void>> stopAll();

  // ฟังก์ชันการเชื่อมต่อ
  Future<Either<Failure, void>> connectToPeer(String peerId);
  Future<Either<Failure, void>> acceptConnection(String peerId);
  Future<Either<Failure, void>> disconnectFromPeer(String peerId);
  
  // ฟังก์ชันส่งข้อมูล
  Future<Either<Failure, void>> sendPayload(String peerId, String message);
}