part of 'p2p_bloc.dart';

abstract class P2PState extends Equatable {
  const P2PState();
  
  @override
  List<Object> get props => [];
}

class P2PInitial extends P2PState {}

class P2PLoading extends P2PState {}

class P2PUpdated extends P2PState {
  final List<PeerEntity> peers;
  const P2PUpdated(this.peers);
  @override
  List<Object> get props => [peers];
}

// ✅ เพิ่ม State นี้เข้าไปครับ!
class P2PConnected extends P2PState {
  final String peerId; // เก็บ ID คนที่เราต่อติด (เผื่อเอาไปใช้)

  const P2PConnected(this.peerId);

  @override
  List<Object> get props => [peerId];
}

class P2PError extends P2PState {
  final String message;
  const P2PError(this.message);
  @override
  List<Object> get props => [message];
}