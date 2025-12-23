import 'dart:async';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/peer_entity.dart';
import '../../domain/repositories/p2p_repository.dart';

class P2PRepositoryImpl implements P2PRepository {
  final Nearby nearby = Nearby();

  final _peerStreamController =
      StreamController<List<PeerEntity>>.broadcast();
  final List<PeerEntity> _discoveredPeers = [];

  final Strategy strategy = Strategy.P2P_STAR;

  // 🔥 สำคัญ! กำหนด Service ID ให้ตรงกันทั้ง Host และ Client
  static const String SERVICE_ID = "com.markcnw.trail_guide";

  // เพิ่มตัวแปรเก็บสถานะ
  bool _isDiscovering = false;
  bool _isAdvertising = false;
  Timer? _retryTimer;

  P2PRepositoryImpl();

  @override
  Stream<List<PeerEntity>> get peersStream => _peerStreamController.stream;

  // ✅ ฟังก์ชันตรวจสอบ Permission (ปรับปรุงแล้ว)
  Future<Either<Failure, bool>> _checkPermissions() async {
    try {
      // 1. ตรวจสอบ Location Service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(P2PFailure("กรุณาเปิด Location Service (GPS)"));
      }

      // 2. ขอ Permission ทีละตัว
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
      ].request();

      // ตรวจสอบว่าผ่านหมดหรือไม่
      for (var entry in statuses.entries) {
        if (entry.value.isPermanentlyDenied) {
          return Left(
            P2PFailure(
              "สิทธิ์ ${entry.key} ถูกปฏิเสธถาวร กรุณาเปิดในการตั้งค่า",
            ),
          );
        }
        // Location เป็นตัวบังคับ ต้อง granted
        if (entry.key == Permission.location && !entry.value.isGranted) {
          return const Left(P2PFailure("กรุณาอนุญาตสิทธิ์ Location"));
        }
      }

      return const Right(true);
    } catch (e) {
      return Left(P2PFailure("เกิดข้อผิดพลาด: $e"));
    }
  }

  // ✅ ปรับปรุง startDiscovery (เพิ่ม retry mechanism)
  @override
  Future<Either<Failure, void>> startDiscovery(
    String userName,
    String strategyStr,
  ) async {
    try {
      // ถ้ากำลัง discover อยู่แล้ว ให้หยุดก่อน
      if (_isDiscovering) {
        await nearby.stopDiscovery();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // ตรวจสอบ Permission
      final permissionResult = await _checkPermissions();
      if (permissionResult.isLeft()) {
        return permissionResult.fold(
          (failure) => Left(failure),
          (_) => const Left(P2PFailure("Permission Error")),
        );
      }

      // เริ่ม Discovery ด้วย Service ID ที่ถูกต้อง
      final bool result = await nearby.startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          // ตรวจสอบ Service ID ว่าตรงกันหรือไม่
          if (serviceId == SERVICE_ID) {
            final newPeer = PeerEntity(
              id: id,
              name: name,
              rssi: 0,
              isLost: false,
            );

            if (!_discoveredPeers.any((p) => p.id == id)) {
              _discoveredPeers.add(newPeer);
              _updateStream();
            }
          }
        },
        onEndpointLost: (id) {
          _discoveredPeers.removeWhere((p) => p.id == id);
          _updateStream();
        },
        serviceId: SERVICE_ID, // 🔥 ใช้ Service ID เดียวกัน
      );

      if (result) {
        _isDiscovering = true;
        _startAutoRetry(); // เริ่ม auto retry
        return const Right(null);
      } else {
        return const Left(P2PFailure("ไม่สามารถเริ่มค้นหาได้"));
      }
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  // ✅ ปรับปรุง startAdvertising
  @override
  Future<Either<Failure, void>> startAdvertising(
    String userName,
    String strategyStr,
  ) async {
    try {
      if (_isAdvertising) {
        await nearby.stopAdvertising();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final permissionResult = await _checkPermissions();
      if (permissionResult.isLeft()) {
        return permissionResult.fold(
          (failure) => Left(failure),
          (_) => const Left(P2PFailure("Permission Error")),
        );
      }

      final bool result = await nearby.startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (id, info) {
          acceptConnection(id);
          final newPeer = PeerEntity(
            id: id,
            name: info.endpointName,
            rssi: 0,
            isLost: false,
          );
          if (!_discoveredPeers.any((p) => p.id == id)) {
            _discoveredPeers.add(newPeer);
            _updateStream();
          }
        },
        onConnectionResult: (id, status) {
          if (status == Status.ERROR) {
            _discoveredPeers.removeWhere((p) => p.id == id);
            _updateStream();
          }
        },
        onDisconnected: (id) {
          _discoveredPeers.removeWhere((p) => p.id == id);
          _updateStream();
        },
        serviceId: SERVICE_ID, // 🔥 ใช้ Service ID เดียวกัน
      );

      if (result) {
        _isAdvertising = true;
        return const Right(null);
      } else {
        return const Left(P2PFailure("ไม่สามารถเริ่มประกาศตัวได้"));
      }
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  // 🆕 Auto Retry Mechanism (ลอง restart ทุก 10 วินาที)
  void _startAutoRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isDiscovering && _discoveredPeers.isEmpty) {
        print("🔄 Auto retry discovery...");
        nearby.stopDiscovery();
        Future.delayed(const Duration(milliseconds: 500), () {
          nearby.startDiscovery(
            "TrailGuide Member",
            strategy,
            onEndpointFound: (id, name, serviceId) {
              if (serviceId == SERVICE_ID) {
                final newPeer = PeerEntity(
                  id: id,
                  name: name,
                  rssi: 0,
                  isLost: false,
                );
                if (!_discoveredPeers.any((p) => p.id == id)) {
                  _discoveredPeers.add(newPeer);
                  _updateStream();
                }
              }
            },
            onEndpointLost: (id) {
              _discoveredPeers.removeWhere((p) => p.id == id);
              _updateStream();
            },
            serviceId: SERVICE_ID,
          );
        });
      }
    });
  }

  @override
  Future<Either<Failure, void>> stopDiscovery() async {
    try {
      _isDiscovering = false;
      _retryTimer?.cancel();
      await nearby.stopDiscovery();
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopAdvertising() async {
    try {
      _isAdvertising = false;
      await nearby.stopAdvertising();
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopAll() async {
    try {
      _isDiscovering = false;
      _isAdvertising = false;
      _retryTimer?.cancel();
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
  Future<Either<Failure, void>> sendPayload(
    String peerId,
    String message,
  ) async {
    try {
      await nearby.sendBytesPayload(
        peerId,
        Uint8List.fromList(message.codeUnits),
      );
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  void _updateStream() {
    _peerStreamController.add(List.from(_discoveredPeers));
  }

  // ปิด timer เมื่อ dispose
  void dispose() {
    _retryTimer?.cancel();
    _peerStreamController.close();
  }
}
