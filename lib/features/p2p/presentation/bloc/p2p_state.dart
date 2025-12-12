part of 'p2p_bloc.dart';

abstract class P2PState extends Equatable {
  const P2PState();
  
  @override
  List<Object> get props => [];
}

class P2PInitial extends P2PState {}

class P2PLoading extends P2PState {}

// State หลัก: เมื่อมีข้อมูลเพื่อน (ไม่ว่าจะว่างเปล่าหรือมีคน)
class P2PUpdated extends P2PState {
  final List<PeerEntity> peers;

  const P2PUpdated(this.peers);

  @override
  List<Object> get props => [peers];
}

class P2PError extends P2PState {
  final String message;

  const P2PError(this.message);

  @override
  List<Object> get props => [message];
}