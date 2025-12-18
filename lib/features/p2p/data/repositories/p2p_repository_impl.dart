import 'dart:async';
import 'dart:typed_data'; // สำหรับ Uint8List
import 'package:dartz/dartz.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart'; 
import '../../../../core/error/failures.dart';
import '../../domain/entities/peer_entity.dart'; 
import '../../domain/repositories/p2p_repository.dart';

class P2PRepositoryImpl implements P2PRepository {
  final Nearby nearby = Nearby();
  
  final _peerStreamController = StreamController<List<PeerEntity>>.broadcast();
  final List<PeerEntity> _discoveredPeers = []; 

  final Strategy strategy = Strategy.P2P_STAR; 

  P2PRepositoryImpl();

  @override
  Stream<List<PeerEntity>> get peersStream => _peerStreamController.stream;

  // ... (ฟังก์ชัน _checkPermissions เหมือนเดิม) ...
  Future<bool> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    if (await Permission.location.serviceStatus.isDisabled) {
      return false;
    }

    return statuses.values.every((status) => status.isGranted);
  }

  // ✅ แก้ไข startDiscovery ให้ตรงกับ Interface
  @override
  Future<Either<Failure, void>> startDiscovery(String userName, String strategyStr) async {
    try {
      if (!await _checkPermissions()) {
        return const Left(P2PFailure("กรุณาอนุญาตสิทธิ์ Location และ Bluetooth"));
      }

      final bool result = await nearby.startDiscovery(
        userName,
        strategy, 
        onEndpointFound: (id, name, serviceId) {
          // ✅ แก้ไข PeerEntity: ใส่ rssi และ isLost (เอา status ออก)
          final newPeer = PeerEntity(
            id: id,
            name: name,
            rssi: 0,         // ใส่ค่าเริ่มต้น
            isLost: false,   // เพิ่งเจอ ยังไม่หาย
          );

          if (!_discoveredPeers.any((p) => p.id == id)) {
            _discoveredPeers.add(newPeer);
            _updateStream();
          }
        },
        onEndpointLost: (id) {
          // แทนที่จะลบทิ้ง อาจจะ mark ว่า isLost = true ก็ได้
          // แต่ในที่นี้ลบออกตาม Logic เดิม
          _discoveredPeers.removeWhere((p) => p.id == id);
          _updateStream();
        },
      );

      return result ? const Right(null) : const Left(P2PFailure("ไม่สามารถเริ่มค้นหาได้"));
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startAdvertising(String userName, String strategyStr) async {
    try {
      if (!await _checkPermissions()) {
        return const Left(P2PFailure("กรุณาอนุญาตสิทธิ์ Location และ Bluetooth"));
      }

      final bool result = await nearby.startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (id, info) {
          acceptConnection(id); 
        },
        onConnectionResult: (id, status) {
          print("Connection status: $status");
        },
        onDisconnected: (id) {
          print("Disconnected: $id");
        },
      );

      return result ? const Right(null) : const Left(P2PFailure("ไม่สามารถเริ่มประกาศตัวได้"));
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  // ✅ เพิ่มฟังก์ชัน stopDiscovery / stopAdvertising / stopAll ให้ครบ
  @override
  Future<Either<Failure, void>> stopDiscovery() async {
    try {
      await nearby.stopDiscovery();
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopAdvertising() async {
    try {
      await nearby.stopAdvertising();
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopAll() async {
    try {
      await nearby.stopDiscovery();
      await nearby.stopAdvertising();
      nearby.stopAllEndpoints();
      _discoveredPeers.clear();
      _updateStream();
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  // ... (ฟังก์ชัน connectToPeer, acceptConnection, disconnectFromPeer, sendPayload ใส่เหมือนเดิมได้เลยครับ เพราะตอนนี้ Interface มีรองรับแล้ว) ...
  
  @override
  Future<Either<Failure, void>> connectToPeer(String peerId) async {
    try {
      await nearby.requestConnection(
        "TrailGuide User", 
        peerId,
        onConnectionInitiated: (id, info) => acceptConnection(id),
        onConnectionResult: (id, status) => print("Connected: $status"),
        onDisconnected: (id) => print("Disconnected"),
      );
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptConnection(String peerId) async {
    try {
      await nearby.acceptConnection(
        peerId,
        onPayLoadRecieved: (endId, payload) {
           // จัดการข้อมูลที่ได้รับ
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnectFromPeer(String peerId) async {
     try {
      nearby.disconnectFromEndpoint(peerId);
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPayload(String peerId, String message) async {
    try {
      await nearby.sendBytesPayload(peerId, Uint8List.fromList(message.codeUnits));
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  void _updateStream() {
    _peerStreamController.add(List.from(_discoveredPeers));
  }
}