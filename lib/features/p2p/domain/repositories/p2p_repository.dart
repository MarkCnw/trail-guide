import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/peer_entity.dart';

/// Callback เมื่อได้รับ payload จาก peer
typedef OnPayloadReceivedCallback =
    void Function(String peerId, Uint8List bytes);

/// Callback เมื่อ peer disconnect
typedef OnPeerDisconnectedCallback = void Function(String peerId);

/// Callback เมื่อมี connection ใหม่
typedef OnConnectionCallback =
    void Function(String peerId, String peerName);

/// Abstract Repository สำหรับ P2P Communication
abstract class P2PRepository {
  // ============================================================
  // STREAMS
  // ============================================================

  /// Stream สำหรับส่งรายชื่อ peers ที่ค้นพบ
  Stream<List<PeerEntity>> get peersStream;

  // ============================================================
  // CALLBACKS - ต้อง set ก่อนใช้งาน
  // ============================================================

  /// Set callback เมื่อได้รับ payload
  set onPayloadReceived(OnPayloadReceivedCallback? callback);

  /// Set callback เมื่อ peer disconnect
  set onPeerDisconnected(OnPeerDisconnectedCallback? callback);

  /// Set callback เมื่อมี connection ใหม่ (Host side)
  set onNewConnection(OnConnectionCallback? callback);

  // ============================================================
  // DISCOVERY & ADVERTISING
  // ============================================================

  /// เริ่มค้นหา Host (Member side)
  /// [userName] - ชื่อที่จะแสดงให้ Host เห็น
  /// [strategy] - รูปแบบการเชื่อมต่อ ("star", "cluster", "p2p")
  Future<Either<Failure, void>> startDiscovery(
    String userName,
    String strategy,
  );

  /// เริ่ม Advertise ตัวเอง (Host side)
  /// [userName] - ชื่อที่จะแสดงให้ Member เห็น (format: "HostName#PIN")
  /// [strategy] - รูปแบบการเชื่อมต่อ
  Future<Either<Failure, void>> startAdvertising(
    String userName,
    String strategy,
  );

  /// หยุด Discovery
  Future<Either<Failure, void>> stopDiscovery();

  /// หยุด Advertising
  Future<Either<Failure, void>> stopAdvertising();

  /// หยุดทุกอย่าง (Discovery + Advertising + Connections)
  Future<Either<Failure, void>> stopAll();

  // ============================================================
  // CONNECTION
  // ============================================================

  /// เชื่อมต่อกับ Peer
  Future<Either<Failure, void>> connectToPeer(String peerId);

  /// ยอมรับการเชื่อมต่อ
  Future<Either<Failure, void>> acceptConnection(String peerId);

  /// ตัดการเชื่อมต่อจาก Peer
  Future<Either<Failure, void>> disconnectFromPeer(String peerId);

  // ============================================================
  // PAYLOAD
  // ============================================================

  /// ส่งข้อมูลไปยัง Peer
  /// [peerId] - ID ของ peer ที่ต้องการส่งให้
  /// [message] - ข้อความ (JSON string)
  Future<Either<Failure, void>> sendPayload(String peerId, String message);

  /// ส่งข้อมูลแบบ bytes ไปยัง Peer
  Future<Either<Failure, void>> sendBytesPayload(
    String peerId,
    Uint8List bytes,
  );

  // ============================================================
  // UTILITIES
  // ============================================================

  /// ดึงจำนวน peers ที่เชื่อมต่ออยู่
  int get connectedPeersCount;

  /// ดึงรายชื่อ peers ที่เชื่อมต่ออยู่
  List<PeerEntity> get connectedPeers;

  /// เช็คว่ากำลัง Advertising อยู่หรือไม่
  bool get isAdvertising;

  /// เช็คว่ากำลัง Discovering อยู่หรือไม่
  bool get isDiscovering;
}
