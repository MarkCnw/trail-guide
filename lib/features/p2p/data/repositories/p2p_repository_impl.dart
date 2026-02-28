import 'dart:async';
import 'dart:typed_data';


import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart';

import '../../../../core/error/failures.dart';

import '../../domain/repositories/p2p_repository.dart';

/// Implementation ของ P2PRepository ใช้ nearby_connections package
class P2PRepositoryImpl implements P2PRepository {
  final Nearby _nearby = Nearby();

  // ============================================================
  // STREAMS & CONTROLLERS
  // ============================================================

  final _peerStreamController = StreamController<List<PeerEntity>>.broadcast();
  final List<PeerEntity> _discoveredPeers = [];
  final List<PeerEntity> _connectedPeers = [];

  // ============================================================
  // CALLBACKS
  // ============================================================

  OnPayloadReceivedCallback? _onPayloadReceived;
  OnPeerDisconnectedCallback? _onPeerDisconnected;
  OnConnectionCallback? _onNewConnection;

  @override
  set onPayloadReceived(OnPayloadReceivedCallback? callback) {
    _onPayloadReceived = callback;
  }

  @override
  set onPeerDisconnected(OnPeerDisconnectedCallback? callback) {
    _onPeerDisconnected = callback;
  }

  @override
  set onNewConnection(OnConnectionCallback? callback) {
    _onNewConnection = callback;
  }

  // ============================================================
  // CONSTANTS & STATE
  // ============================================================

  final Strategy _strategy = Strategy.P2P_STAR;
  static const String _serviceId = 'com.markcnw.trail_guide';

  bool _isDiscovering = false;
  bool _isAdvertising = false;
  Timer? _retryTimer;

  // เก็บชื่อ peer ที่กำลังเชื่อมต่อ
  final Map<String, String> _pendingConnectionNames = {};

  // 🆕 เก็บ peer ที่ accept แล้ว (ป้องกัน accept ซ้ำ)
  final Set<String> _acceptedPeers = {};

  P2PRepositoryImpl();

  // ============================================================
  // GETTERS
  // ============================================================

  @override
  Stream<List<PeerEntity>> get peersStream => _peerStreamController.stream;

  @override
  int get connectedPeersCount => _connectedPeers.length;

  @override
  List<PeerEntity> get connectedPeers => List.unmodifiable(_connectedPeers);

  @override
  bool get isAdvertising => _isAdvertising;

  @override
  bool get isDiscovering => _isDiscovering;

  // ============================================================
  // PERMISSIONS
  // ============================================================

  Future<Either<Failure, bool>> _checkPermissions() async {
    try {
      // 1. ตรวจสอบ Location Service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(P2PFailure('กรุณาเปิด Location Service (GPS)'));
      }

      // 2. ขอ Permission ทีละตัว
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
      ].request();

      // 3. ตรวจสอบ Location Permission
      if (statuses[Permission.location]?. isDenied ?? true) {
        return const Left(P2PFailure('กรุณาอนุญาต Location Permission'));
      }

      // 4. ตรวจสอบ Bluetooth Permissions
      if (statuses[Permission.bluetoothScan]?.isDenied ?? true) {
        return const Left(P2PFailure('กรุณาอนุญาต Bluetooth Scan Permission'));
      }

      return const Right(true);
    } catch (e) {
      return Left(P2PFailure('Permission Error: $e'));
    }
  }

  // ============================================================
  // DISCOVERY (Member Side)
  // ============================================================

  @override
  Future<Either<Failure, void>> startDiscovery(
    String userName,
    String strategy,
  ) async {
    try {
      // หยุด discovery เก่าก่อน (ถ้ามี)
      if (_isDiscovering) {
        await _nearby.stopDiscovery();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // ตรวจสอบ permissions
      final permissionResult = await _checkPermissions();
      if (permissionResult.isLeft()) {
        return permissionResult. fold(
          (failure) => Left(failure),
          (_) => const Left(P2PFailure('Permission Error')),
        );
      }

      // Clear discovered peers
      _discoveredPeers.clear();
      _updatePeersStream();

      // เริ่ม Discovery
      final bool result = await _nearby.startDiscovery(
        userName,
        _strategy,
        onEndpointFound: (endpointId, endpointName, serviceId) {
          _onEndpointFound(endpointId, endpointName);
        },
        onEndpointLost: (endpointId) {
          _onEndpointLost(endpointId!);
        },
        serviceId: _serviceId,
      );

      if (result) {
        _isDiscovering = true;
        _startRetryTimer(userName);
        return const Right(null);
      } else {
        return const Left(P2PFailure('ไม่สามารถเริ่มค้นหาได้'));
      }
    } catch (e) {
      return Left(P2PFailure('Discovery Error:  $e'));
    }
  }

  void _onEndpointFound(String endpointId, String endpointName) {
    // ตรวจสอบว่ามีอยู่แล้วหรือไม่
    final existingIndex = _discoveredPeers. indexWhere((p) => p.id == endpointId);

    if (existingIndex >= 0) {
      // อัปเดต peer ที่มีอยู่
      _discoveredPeers[existingIndex] = PeerEntity(
        id: endpointId,
        name: endpointName,
        rssi: 0,
        isLost: false,
      );
    } else {
      // เพิ่ม peer ใหม่
      _discoveredPeers.add(PeerEntity(
        id: endpointId,
        name: endpointName,
        rssi: 0,
        isLost: false,
      ));
    }

    _updatePeersStream();
  }

  void _onEndpointLost(String endpointId) {
    _discoveredPeers.removeWhere((p) => p.id == endpointId);
    _updatePeersStream();
  }

  void _startRetryTimer(String userName) {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isDiscovering) {
        // Restart discovery เพื่อ refresh รายการ
        await _nearby.stopDiscovery();
        await Future.delayed(const Duration(milliseconds: 500));

        if (_isDiscovering) {
          await _nearby.startDiscovery(
            userName,
            _strategy,
            onEndpointFound: (endpointId, endpointName, serviceId) {
              _onEndpointFound(endpointId, endpointName);
            },
            onEndpointLost: (endpointId) {
              _onEndpointLost(endpointId!);
            },
            serviceId: _serviceId,
          );
        }
      }
    });
  }

  @override
  Future<Either<Failure, void>> stopDiscovery() async {
    try {
      _isDiscovering = false;
      _retryTimer?.cancel();
      await _nearby.stopDiscovery();
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure('Stop Discovery Error: $e'));
    }
  }

  // ============================================================
  // ADVERTISING (Host Side)
  // ============================================================

  @override
  Future<Either<Failure, void>> startAdvertising(
    String userName,
    String strategy,
  ) async {
    try {
      // หยุด advertising เก่าก่อน (ถ้ามี)
      if (_isAdvertising) {
        await _nearby.stopAdvertising();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // ตรวจสอบ permissions
      final permissionResult = await _checkPermissions();
      if (permissionResult.isLeft()) {
        return permissionResult. fold(
          (failure) => Left(failure),
          (_) => const Left(P2PFailure('Permission Error')),
        );
      }

      // Clear
      _connectedPeers.clear();
      _acceptedPeers. clear();

      // เริ่ม Advertising
      final bool result = await _nearby.startAdvertising(
        userName,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );

      if (result) {
        _isAdvertising = true;
        return const Right(null);
      } else {
        return const Left(P2PFailure('ไม่สามารถเริ่ม Advertising ได้'));
      }
    } catch (e) {
      return Left(P2PFailure('Advertising Error: $e'));
    }
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    print('P2P:  Connection initiated from $endpointId (${info.endpointName})');

    // เก็บชื่อไว้ก่อน
    _pendingConnectionNames[endpointId] = info.endpointName;

    // 🆕 เช็คว่า accept แล้วหรือยัง
    if (! _acceptedPeers.contains(endpointId)) {
      _acceptedPeers. add(endpointId);
      acceptConnection(endpointId);
    }
  }

  void _onConnectionResult(String endpointId, Status status) {
    print('P2P: Connection result for $endpointId: $status');

    if (status == Status. CONNECTED) {
      final peerName = _pendingConnectionNames[endpointId] ?? 'Unknown';

      // เพิ่มเข้า connected peers
      final newPeer = PeerEntity(
        id: endpointId,
        name: peerName,
        rssi: 0,
        isLost:  false,
      );

      // ตรวจสอบว่ามีอยู่แล้วหรือไม่
      final existingIndex = _connectedPeers.indexWhere((p) => p.id == endpointId);
      if (existingIndex < 0) {
        _connectedPeers.add(newPeer);
      }

      // Notify callback
      _onNewConnection?.call(endpointId, peerName);

      // Clear pending
      _pendingConnectionNames.remove(endpointId);
    } else {
      // Connection failed
      _pendingConnectionNames.remove(endpointId);
      _acceptedPeers.remove(endpointId);
    }
  }

  void _onDisconnected(String endpointId) {
    print('P2P: Disconnected from $endpointId');

    // ลบออกจาก connected peers
    _connectedPeers.removeWhere((p) => p.id == endpointId);
    _acceptedPeers. remove(endpointId);

    // Notify callback
    _onPeerDisconnected?.call(endpointId);
  }

  @override
  Future<Either<Failure, void>> stopAdvertising() async {
    try {
      _isAdvertising = false;
      await _nearby.stopAdvertising();
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure('Stop Advertising Error: $e'));
    }
  }

  // ============================================================
  // CONNECTION
  // ============================================================

  @override
  Future<Either<Failure, void>> connectToPeer(String peerId) async {
    try {
      print('P2P: Requesting connection to $peerId');

      // 🆕 Clear accepted peers for new connection
      _acceptedPeers.clear();

      await _nearby.requestConnection(
        'TrailGuide User',
        peerId,
        onConnectionInitiated: (endpointId, info) {
          print('P2P:  (Member) Connection initiated to $endpointId');
          _pendingConnectionNames[endpointId] = info.endpointName;

          if (!_acceptedPeers. contains(endpointId)) {
            _acceptedPeers.add(endpointId);
            acceptConnection(endpointId);
          }
        },
        onConnectionResult: (endpointId, status) {
          print('P2P: (Member) Connection result: $status');

          if (status == Status. CONNECTED) {
            final peerName = _pendingConnectionNames[endpointId] ?? 'Unknown';

            final newPeer = PeerEntity(
              id: endpointId,
              name: peerName,
              rssi: 0,
              isLost: false,
            );

            final existingIndex = _connectedPeers.indexWhere((p) => p.id == endpointId);
            if (existingIndex < 0) {
              _connectedPeers. add(newPeer);
            }

            _onNewConnection?. call(endpointId, peerName);
            _pendingConnectionNames.remove(endpointId);
          } else {
            _acceptedPeers.remove(endpointId);
          }
        },
        onDisconnected: (endpointId) {
          print('P2P: (Member) Disconnected from $endpointId');
          _connectedPeers.removeWhere((p) => p.id == endpointId);
          _acceptedPeers.remove(endpointId);
          _onPeerDisconnected?.call(endpointId);
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure('Connection Error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> acceptConnection(String peerId) async {
    try {
      print('P2P: Accepting connection from $peerId');

      await _nearby.acceptConnection(
        peerId,
        onPayLoadRecieved: (endpointId, payload) {
          _handlePayloadReceived(endpointId, payload);
        },
        onPayloadTransferUpdate: (endpointId, update) {
          // สำหรับ file transfer - ไม่ใช้ตอนนี้
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure('Accept Connection Error: $e'));
    }
  }

  void _handlePayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      print('P2P: Received payload from $endpointId (${payload.bytes! .length} bytes)');
      // Notify callback
      _onPayloadReceived?.call(endpointId, payload.bytes!);
    }
  }

  @override
  Future<Either<Failure, void>> disconnectFromPeer(String peerId) async {
    try {
      print('P2P: Disconnecting from $peerId');
      _nearby.disconnectFromEndpoint(peerId);
      _connectedPeers.removeWhere((p) => p.id == peerId);
      _acceptedPeers.remove(peerId);
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure('Disconnect Error: $e'));
    }
  }

  // ============================================================
  // PAYLOAD
  // ============================================================

  @override
  Future<Either<Failure, void>> sendPayload(
    String peerId,
    String message,
  ) async {
    try {
      await _nearby.sendBytesPayload(
        peerId,
        Uint8List.fromList(message. codeUnits),
      );
      return const Right(null);
    } catch (e) {
      print('P2P: Send payload error: $e');
      return Left(P2PFailure('Send Payload Error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendBytesPayload(
    String peerId,
    Uint8List bytes,
  ) async {
    try {
      await _nearby.sendBytesPayload(peerId, bytes);
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure('Send Bytes Payload Error: $e'));
    }
  }

  // ============================================================
  // STOP ALL
  // ============================================================

  @override
  Future<Either<Failure, void>> stopAll() async {
    try {
      _isDiscovering = false;
      _isAdvertising = false;
      _retryTimer?.cancel();

      await _nearby.stopDiscovery();
      await _nearby.stopAdvertising();
      _nearby.stopAllEndpoints();

      _discoveredPeers.clear();
      _connectedPeers. clear();
      _pendingConnectionNames.clear();
      _acceptedPeers.clear();
      _updatePeersStream();

      return const Right(null);
    } catch (e) {
      return Left(P2PFailure('Stop All Error: $e'));
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _updatePeersStream() {
    _peerStreamController.add(List.from(_discoveredPeers));
  }

  /// Dispose - เรียกเมื่อไม่ใช้แล้ว
  void dispose() {
    _retryTimer?.cancel();
    _peerStreamController.close();
  }
}