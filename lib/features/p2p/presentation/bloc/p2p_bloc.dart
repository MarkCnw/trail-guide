import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart';
import '../../../../core/usecases/usecase.dart';

import '../../domain/usecases/scan_for_peers.dart';
import '../../domain/usecases/watch_peers.dart';

part 'p2p_event.dart';
part 'p2p_state.dart';

class P2PBloc extends Bloc<P2PEvent, P2PState> {
  final ScanForPeers scanForPeers;
  final WatchPeers watchPeers;
  
  // ตัวแปรสำหรับถือท่อส่งข้อมูล
  StreamSubscription<List<PeerEntity>>? _peersSubscription;

  P2PBloc({
    required this.scanForPeers,
    required this.watchPeers,
  }) : super(P2PInitial()) {
    
    // จัดการ Event: เริ่มสแกน
    on<StartDiscoveryEvent>(_onStartDiscovery);
    
    // จัดการ Event: เพื่อนอัปเดต (รับลูกต่อจาก Stream)
    on<OnPeersUpdatedEvent>(_onPeersUpdated);

    // *เทคนิค Senior Dev:* เริ่มฟัง Stream ทันทีที่ Bloc ถูกสร้าง
    // เพื่อให้พร้อมรับข้อมูลเสมอ
    _subscribeToPeers();
  }

  // Logic การเริ่มสแกน
  Future<void> _onStartDiscovery(
    StartDiscoveryEvent event,
    Emitter<P2PState> emit,
  ) async {
    emit(P2PLoading()); // หมุนๆ รอ
    final result = await scanForPeers(NoParams());
    
    result.fold(
      (failure) => emit(P2PError(failure.message)),
      (_) {
        // ถ้าสำเร็จ ไม่ต้อง emit อะไรเพิ่ม 
        // เพราะเดี๋ยวข้อมูลจะไหลมาทาง Stream เอง
      },
    );
  }

  // Logic เมื่อ Stream ส่งข้อมูลมา -> อัปเดต State
  void _onPeersUpdated(
    OnPeersUpdatedEvent event,
    Emitter<P2PState> emit,
  ) {
    emit(P2PUpdated(event.peers));
  }

  // ฟังก์ชันเชื่อมต่อท่อ Stream
  void _subscribeToPeers() {
    _peersSubscription?.cancel();
    _peersSubscription = watchPeers().listen(
      (peers) {
        // เมื่อมีข้อมูลใหม่ ให้โยนเข้า Event ของ Bloc (ห้าม emit ใน listen โดยตรง)
        add(OnPeersUpdatedEvent(peers));
      },
      onError: (error) {
        // จัดการ Error ถ้า Stream พัง
        // add(OnPeerErrorEvent(...)); // ถ้าต้องการ
      },
    );
  }

  @override
  Future<void> close() {
    _peersSubscription?.cancel(); // ปิดท่อเมื่อเลิกใช้ ป้องกัน Memory Leak
    return super.close();
  }
}