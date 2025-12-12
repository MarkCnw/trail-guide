import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trail_guide/core/error/failures.dart';
import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart'; 
import 'package:trail_guide/features/p2p/domain/repositories/p2p_repository.dart';

class P2PRepositoryImpl implements P2PRepository {
  final Nearby nearby = Nearby();
  
  final _peerStreamController = StreamController<List<PeerEntity>>.broadcast();
  final Map<String, PeerEntity> _foundPeers = {}; 

  final Strategy strategy = Strategy.P2P_STAR; 
  final String userName = "TrailGuide User"; 

  P2PRepositoryImpl();

  @override
  Stream<List<PeerEntity>> get peersStream => _peerStreamController.stream;

  @override
  Future<Either<Failure, void>> startDiscovery() async {
    try {
      // 1. ขอ Permission
      await [
        Permission.location,
        Permission.storage,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
      ].request();

      bool locationEnabled = await Permission.location.serviceStatus.isEnabled;
      if (!locationEnabled) {
         return const Left(P2PFailure("กรุณาเปิด GPS (Location Service)"));
      }

      // 2. เริ่ม Discovery
      bool result = await nearby.startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          // 🛑 แก้จุดที่ 1: ถ้า id ไม่มีค่า ให้ข้ามไปเลย
          if (id == null) return;

          _foundPeers[id] = PeerEntity(
            id: id,
            name: name ?? "Unknown Device", 
            rssi: -1, 
            isLost: false,
          );
          _updateStream(); 
        },
        onEndpointLost: (id) {
          // 🛑 แก้จุดที่ 2: เช็ค id ก่อนใช้
          if (id == null) return;

          if (_foundPeers.containsKey(id)) {
             final oldPeer = _foundPeers[id]!;
             _foundPeers[id] = PeerEntity(
               id: oldPeer.id, 
               name: oldPeer.name, 
               rssi: oldPeer.rssi, 
               isLost: true
             );
             _updateStream();
          }
        },
      );

      // 3. เริ่ม Advertising
      await nearby.startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (id, info) {
          // 🛑 แก้จุดที่ 3: เช็ค id ก่อนใช้
          if (id == null) return;
          // TODO: Handle connection request
        },
        onConnectionResult: (id, status) {
          // 🛑 แก้จุดที่ 4: เช็ค id ก่อนใช้
          if (id == null) return;
          // TODO: Handle Result
        },
        onDisconnected: (id) {
          // 🛑 แก้จุดที่ 5: เช็ค id ก่อนใช้
          if (id == null) return;
          // TODO: Handle Disconnect
        },
      );

      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopDiscovery() async {
    try {
      await nearby.stopDiscovery();
      await nearby.stopAdvertising();
      _foundPeers.clear();
      _updateStream();
      return const Right(null);
    } catch (e) {
      return Left(P2PFailure(e.toString()));
    }
  }

  void _updateStream() {
    _peerStreamController.add(_foundPeers.values.toList());
  }
}