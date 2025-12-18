import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart';
import 'package:trail_guide/features/p2p/domain/repositories/p2p_repository.dart'; // 👈 import repository
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/scan_for_peers.dart';
import '../../domain/usecases/watch_peers.dart';

part 'p2p_event.dart';
part 'p2p_state.dart';

class P2PBloc extends Bloc<P2PEvent, P2PState> {
  final ScanForPeers scanForPeers;
  final WatchPeers watchPeers;
  final P2PRepository repository; // 👈 1. เพิ่ม Repository เข้ามา

  StreamSubscription<List<PeerEntity>>? _peersSubscription;

  P2PBloc({
    required this.scanForPeers,
    required this.watchPeers,
    required this.repository, // 👈 2. รับ Repository
  }) : super(P2PInitial()) {
    // จัดการ Event: เริ่มสแกน (Join)
    on<StartDiscoveryEvent>(_onStartDiscovery);

    // ✅ 3. จัดการ Event: เริ่มประกาศตัว (Host) <-- ที่ขาดไป
    on<StartAdvertisingEvent>(_onStartAdvertising);

    on<ConnectToPeerEvent>(_onConnectToPeer);
    // จัดการ Event: เพื่อนอัปเดต
    on<OnPeersUpdatedEvent>(_onPeersUpdated);

    _subscribeToPeers();
  }

  Future<void> _onConnectToPeer(
    ConnectToPeerEvent event,
    Emitter<P2PState> emit,
  ) async {
    // ไม่ต้อง emit Loading ทับ State เดิม (เดี๋ยว list หาย)
    // แค่ส่งคำสั่งไปหลังบ้าน
    final result = await repository.connectToPeer(event.peerId);

    result.fold(
      (failure) {
        // อาจจะส่ง Toast หรือ SnackBar บอกว่าเชื่อมต่อไม่ได้
        print("Connection Failed: ${failure.message}");
      },
      (_) {
        print("Requested Connection to ${event.peerId}");
        // ถ้าสำเร็จ เดี๋ยวสถานะจะเปลี่ยนผ่าน Stream เอง
        // หรือจะเปลี่ยนหน้าไป Tracking เลยก็ได้ถ้าต้องการ
      },
    );
  }

  // Logic: Joiner (สแกนหาเพื่อน)
  Future<void> _onStartDiscovery(
    StartDiscoveryEvent event,
    Emitter<P2PState> emit,
  ) async {
    emit(P2PLoading());
    final result = await scanForPeers(NoParams());
    result.fold(
      (failure) => emit(P2PError(failure.message)),
      (_) {}, // สำเร็จ รอ stream
    );
  }

  // ✅ 4. Logic: Host (ประกาศตัว)
  Future<void> _onStartAdvertising(
    StartAdvertisingEvent event,
    Emitter<P2PState> emit,
  ) async {
    emit(P2PLoading());
    // เรียกใช้ repository โดยตรง (หรือจะสร้าง UseCase ก็ได้)
    // ใส่ชื่อ Host ที่ต้องการ เช่น "TrailGuide Host"
    final result = await repository.startAdvertising(
      "TrailGuide Host",
      "star",
    );

    result.fold((failure) => emit(P2PError(failure.message)), (_) {
      // สำเร็จ รอคนมา connect (Stream จะทำงาน)
    });
  }

  void _onPeersUpdated(OnPeersUpdatedEvent event, Emitter<P2PState> emit) {
    emit(P2PUpdated(event.peers));
  }

  void _subscribeToPeers() {
    _peersSubscription?.cancel();
    _peersSubscription = watchPeers().listen(
      (peers) => add(OnPeersUpdatedEvent(peers)),
    );
  }

  @override
  Future<void> close() {
    _peersSubscription?.cancel();
    return super.close();
  }
}
