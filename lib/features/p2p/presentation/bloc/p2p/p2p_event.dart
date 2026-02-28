part of 'p2p_bloc.dart';

abstract class P2PEvent extends Equatable {
  const P2PEvent();

  @override
  List<Object> get props => [];
}

// 1. เหตุการณ์:  ผู้ใช้กดปุ่มสแกน (Join)
class StartDiscoveryEvent extends P2PEvent {
  final String userName;
  const StartDiscoveryEvent(this. userName);
  
  @override
  List<Object> get props => [userName];
}

// 2. เหตุการณ์: ผู้ใช้กดปุ่ม Host
class StartAdvertisingEvent extends P2PEvent {
  final String hostName;
  const StartAdvertisingEvent(this.hostName);
  
  @override
  List<Object> get props => [hostName];
}

// 3. เหตุการณ์: หยุด Discovery
class StopDiscoveryEvent extends P2PEvent {}

// 4. เหตุการณ์: หยุด Advertising
class StopAdvertisingEvent extends P2PEvent {}

// 5. เหตุการณ์: ข้อมูลเพื่อนมีการเปลี่ยนแปลง (Internal Event)
class OnPeersUpdatedEvent extends P2PEvent {
  final List<PeerEntity> peers;

  const OnPeersUpdatedEvent(this.peers);

  @override
  List<Object> get props => [peers];
}

// 6. เหตุการณ์: กดปุ่ม Join เชื่อมต่อกับ Host
class ConnectToPeerEvent extends P2PEvent {
  final String peerId;
  const ConnectToPeerEvent(this.peerId);
  
  @override
  List<Object> get props => [peerId];
}