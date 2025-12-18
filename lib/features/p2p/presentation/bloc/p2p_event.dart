part of 'p2p_bloc.dart';

abstract class P2PEvent extends Equatable {
  const P2PEvent();

  @override
  List<Object> get props => [];
}

// 1. เหตุการณ์: ผู้ใช้กดปุ่มสแกน
class StartDiscoveryEvent extends P2PEvent {}
class StartAdvertisingEvent extends P2PEvent {}

// 2. เหตุการณ์: ข้อมูลเพื่อนมีการเปลี่ยนแปลง (Internal Event)
// เหตุการณ์นี้จะถูกเรียกโดย StreamSubscription ภายใน Bloc เอง
class OnPeersUpdatedEvent extends P2PEvent {
  final List<PeerEntity> peers;

  const OnPeersUpdatedEvent(this.peers);

  @override
  List<Object> get props => [peers];
}

// ... events อื่นๆ

// ✨ เพิ่มอันนี้: อีเวนต์กดปุ่ม Join
class ConnectToPeerEvent extends P2PEvent {
  final String peerId;
  const ConnectToPeerEvent(this.peerId);
  @override
  List<Object> get props => [peerId];
}