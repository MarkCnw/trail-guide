
import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart';

import '../repositories/p2p_repository.dart';

class WatchPeers {
  final P2PRepository repository;

  WatchPeers(this.repository);

  // ไม่ต้องเป็น Future เพราะเราต้องการ Stream ต่อเนื่อง
  Stream<List<PeerEntity>> call() {
    return repository.peersStream;
  }
}