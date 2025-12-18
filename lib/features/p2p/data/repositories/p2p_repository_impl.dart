import 'dart:async';
import 'dart:typed_data'; // สำหรับ Uint8List
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
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

  // ✅ แก้ไขฟังก์ชัน _checkPermissions ให้ละเอียดขึ้น
  Future<Either<Failure, bool>> _checkPermissions() async {
    try {
      // 1. ตรวจสอบว่า Location Service เปิดอยู่หรือไม่
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(P2PFailure("กรุณาเปิด Location Service (GPS) ในการตั้งค่าเครื่อง"));
      }

      // 2. ขอ Permission ทีละตัว พร้อมตรวจสอบ
      // Location Permission
      PermissionStatus locationStatus = await Permission.location.status;
      if (locationStatus.isDenied) {
        locationStatus = await Permission.location.request();
      }
      if (locationStatus. isPermanentlyDenied) {
        return const Left(P2PFailure(
            "สิทธิ์ Location ถูกปฏิเสธถาวร กรุณาไปเปิดในการตั้งค่าแอป"));
      }
      if (! locationStatus.isGranted) {
        return const Left(P2PFailure("กรุณาอนุญาตสิทธิ์ Location"));
      }

      // Bluetooth Permissions (Android 12+)
      PermissionStatus bluetoothScanStatus = await Permission.bluetoothScan.status;
      if (bluetoothScanStatus.isDenied) {
        bluetoothScanStatus = await Permission.bluetoothScan.request();
      }
      if (bluetoothScanStatus.isPermanentlyDenied) {
        return const Left(P2PFailure(
            "สิทธิ์ Bluetooth Scan ถูกปฏิเสธถาวร กรุณาไปเปิดในการตั้งค่าแอป"));
      }

      PermissionStatus bluetoothAdvertiseStatus =
          await Permission.bluetoothAdvertise.status;
      if (bluetoothAdvertiseStatus. isDenied) {
        bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.request();
      }
      if (bluetoothAdvertiseStatus.isPermanentlyDenied) {
        return const Left(P2PFailure(
            "สิทธิ์ Bluetooth Advertise ถูกปฏิเสธถาวร กรุณาไปเปิดในการตั้งค่าแอป"));
      }

      PermissionStatus bluetoothConnectStatus =
          await Permission. bluetoothConnect.status;
      if (bluetoothConnectStatus.isDenied) {
        bluetoothConnectStatus = await Permission.bluetoothConnect. request();
      }
      if (bluetoothConnectStatus. isPermanentlyDenied) {
        return const Left(P2PFailure(
            "สิทธิ์ Bluetooth Connect ถูกปฏิเสธถาวร กรุณาไปเปิดในการตั้งค่าแอป"));
      }

      // Nearby Wi-Fi Devices (Android 13+)
      PermissionStatus nearbyWifiStatus =
          await Permission.nearbyWifiDevices.status;
      if (nearbyWifiStatus.isDenied) {
        nearbyWifiStatus = await Permission.nearbyWifiDevices.request();
      }
      // nearbyWifiDevices อาจไม่จำเป็นในบางเครื่อง ไม่ต้อง block

      // ตรวจสอบ Bluetooth เปิดอยู่หรือไม่
      // (nearby_connections จะจัดการเอง แต่เราแจ้งเตือนได้)

      return const Right(true);
    } catch (e) {
      return Left(P2PFailure("เกิดข้อผิดพลาดในการขอสิทธิ์: $e"));
    }
  }

  // ✅ แก้ไข startDiscovery
  @override
  Future<Either<Failure, void>> startDiscovery(
      String userName, String strategyStr) async {
    try {
      // ตรวจสอบ Permission ก่อน
      final permissionResult = await _checkPermissions();
      if (permissionResult.isLeft()) {
        return permissionResult. fold(
          (failure) => Left(failure),
          (_) => const Left(P2PFailure("Permission Error")),
        );
      }

      final bool result = await nearby.startDiscovery(
        userName,
        strategy,
        onEndpointFound:  (id, name, serviceId) {
          final newPeer = PeerEntity(
            id: id,
            name: name,
            rssi:  0,
            isLost: false,
          );

          if (! _discoveredPeers.any((p) => p.id == id)) {
            _discoveredPeers.add(newPeer);
            _updateStream();
          }
        },
        onEndpointLost: (id) {
          _discoveredPeers. removeWhere((p) => p.id == id);
          _updateStream();
        },
      );

      return result
          ? const Right(null)
          : const Left(P2PFailure("ไม่สามารถเริ่มค้นหาได้"));
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  // ✅ แก้ไข startAdvertising
  @override
  Future<Either<Failure, void>> startAdvertising(
      String userName, String strategyStr) async {
    try {
      // ตรวจสอบ Permission ก่อน
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
          // ✅ เพิ่ม Peer เข้า List เมื่อมีคน Connect เข้ามา
          final newPeer = PeerEntity(
            id: id,
            name: info.endpointName,
            rssi: 0,
            isLost: false,
          );
          if (!_discoveredPeers. any((p) => p.id == id)) {
            _discoveredPeers.add(newPeer);
            _updateStream();
          }
        },
        onConnectionResult: (id, status) {
          print("Connection status: $status");
          if (status == Status.ERROR) {
            _discoveredPeers.removeWhere((p) => p.id == id);
            _updateStream();
          }
        },
        onDisconnected: (id) {
          print("Disconnected:  $id");
          _discoveredPeers.removeWhere((p) => p.id == id);
          _updateStream();
        },
      );

      return result
          ? const Right(null)
          : const Left(P2PFailure("ไม่สามารถเริ่มประกาศตัวได้"));
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

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

  @override
  Future<Either<Failure, void>> connectToPeer(String peerId) async {
    try {
      await nearby.requestConnection(
        "TrailGuide User",
        peerId,
        onConnectionInitiated: (id, info) => acceptConnection(id),
        onConnectionResult: (id, status) => print("Connected: $status"),
        onDisconnected:  (id) => print("Disconnected"),
      );
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e. toString()));
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
      await nearby.sendBytesPayload(
          peerId, Uint8List.fromList(message.codeUnits));
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  void _updateStream() {
    _peerStreamController.add(List.from(_discoveredPeers));
  }
}