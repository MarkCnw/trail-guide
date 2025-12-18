import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart';
import 'package:trail_guide/features/p2p/domain/repositories/p2p_repository.dart';
import 'package:trail_guide/features/p2p/domain/usecases/scan_for_peers.dart';


import '../../domain/usecases/watch_peers.dart';

part 'p2p_event.dart';
part 'p2p_state.dart';

class P2PBloc extends Bloc<P2PEvent, P2PState> {
  final ScanForPeers scanForPeers;
  final WatchPeers watchPeers;
  final P2PRepository repository;

  StreamSubscription<List<PeerEntity>>? _peersSubscription;

  P2PBloc({
    required this.scanForPeers,
    required this.watchPeers,
    required this.repository,
  }) : super(P2PInitial()) {
    // จัดการ Events ทั้งหมด
    on<StartDiscoveryEvent>(_onStartDiscovery);
    on<StartAdvertisingEvent>(_onStartAdvertising);
    on<StopDiscoveryEvent>(_onStopDiscovery);
    on<StopAdvertisingEvent>(_onStopAdvertising);
    on<ConnectToPeerEvent>(_onConnectToPeer);
    on<OnPeersUpdatedEvent>(_onPeersUpdated);

    _subscribeToPeers();
  }

  // ✅ Logic:  Joiner (สแกนหา Host)
  Future<void> _onStartDiscovery(
    StartDiscoveryEvent event,
    Emitter<P2PState> emit,
  ) async {
    emit(P2PLoading());
    
    // ใช้ชื่อจาก Event แทน hardcode
    final result = await repository.startDiscovery(
      event.userName,
      "star",
    );
    
    result.fold(
      (failure) => emit(P2PError(failure.message)),
      (_) {}, // สำเร็จ รอ stream
    );
  }

  // ✅ Logic: Host (ประกาศตัวให้คนอื่นเจอ)
  Future<void> _onStartAdvertising(
    StartAdvertisingEvent event,
    Emitter<P2PState> emit,
  ) async {
    emit(P2PLoading());
    
    // ใช้ชื่อจาก Event แทน hardcode
    final result = await repository.startAdvertising(
      event.hostName,
      "star",
    );

    result.fold(
      (failure) => emit(P2PError(failure.message)),
      (_) {
        // สำเร็จ รอคนมา connect (Stream จะทำงาน)
        // Emit state ว่าพร้อมรับคนแล้ว
        emit(const P2PUpdated([]));
      },
    );
  }

  // ✅ Logic: หยุด Discovery
  Future<void> _onStopDiscovery(
    StopDiscoveryEvent event,
    Emitter<P2PState> emit,
  ) async {
    final result = await repository.stopDiscovery();
    result.fold(
      (failure) => print("Stop Discovery Failed: ${failure.message}"),
      (_) => print("Discovery Stopped"),
    );
  }

  // ✅ Logic: หยุด Advertising
  Future<void> _onStopAdvertising(
    StopAdvertisingEvent event,
    Emitter<P2PState> emit,
  ) async {
    final result = await repository.stopAdvertising();
    result.fold(
      (failure) => print("Stop Advertising Failed: ${failure.message}"),
      (_) => print("Advertising Stopped"),
    );
  }

  // ✅ Logic: เชื่อมต่อกับ Peer
  Future<void> _onConnectToPeer(
    ConnectToPeerEvent event,
    Emitter<P2PState> emit,
  ) async {
    final result = await repository.connectToPeer(event.peerId);

    result.fold(
      (failure) {
        print("Connection Failed: ${failure.message}");
        // แสดง error แต่ไม่ทับ state เดิม
      },
      (_) {
        print("Requested Connection to ${event.peerId}");
        // ถ้าสำเร็จ สถานะจะเปลี่ยนผ่าน Stream
      },
    );
  }

  // ✅ Logic:  อัปเดตรายชื่อ Peers
  void _onPeersUpdated(OnPeersUpdatedEvent event, Emitter<P2PState> emit) {
    emit(P2PUpdated(event. peers));
  }

  void _subscribeToPeers() {
    _peersSubscription?. cancel();
    _peersSubscription = watchPeers().listen(
      (peers) => add(OnPeersUpdatedEvent(peers)),
    );
  }

  @override
  Future<void> close() {
    _peersSubscription?.cancel();
    // หยุดทุกอย่างเมื่อปิด Bloc
    repository.stopAll();
    return super.close();
  }
}