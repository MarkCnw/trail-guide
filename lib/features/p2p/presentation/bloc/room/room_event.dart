import 'package:equatable/equatable.dart';
import 'package:trail_guide/features/p2p/domain/entities/room_message_entity.dart';

abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

// ============================================================
// HOST EVENTS
// ============================================================

class CreateRoomEvent extends RoomEvent {
  final String password;
  final String hostName;
  final String?  hostImageBase64;
  final int maxMembers;

  const CreateRoomEvent({
    required this.password,
    required this.hostName,
    this.hostImageBase64,
    this.maxMembers = 5,
  });

  @override
  List<Object?> get props => [password, hostName, hostImageBase64, maxMembers];
}

class CloseRoomEvent extends RoomEvent {
  final String?  reason;

  const CloseRoomEvent({this.reason});

  @override
  List<Object?> get props => [reason];
}

class KickMemberEvent extends RoomEvent {
  final String memberId;

  const KickMemberEvent(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

// ============================================================
// MEMBER EVENTS
// ============================================================

class JoinRoomEvent extends RoomEvent {
  final String hostPeerId;
  final String hostName;
  final String password;
  final String memberName;
  final String?  memberImageBase64;

  const JoinRoomEvent({
    required this.hostPeerId,
    required this.hostName,
    required this.password,
    required this.memberName,
    this.memberImageBase64,
  });

  @override
  List<Object?> get props => [hostPeerId, hostName, password, memberName, memberImageBase64];
}

class LeaveRoomEvent extends RoomEvent {
  const LeaveRoomEvent();
}

// ============================================================
// INTERNAL EVENTS
// ============================================================

class RoomMessageReceivedEvent extends RoomEvent {
  final String fromPeerId;
  final RoomMessage message;

  const RoomMessageReceivedEvent({
    required this.fromPeerId,
    required this.message,
  });

  @override
  List<Object?> get props => [fromPeerId, message];
}

class MemberJoinedEvent extends RoomEvent {
  final String memberId;
  final String memberName;

  const MemberJoinedEvent({
    required this.memberId,
    required this.memberName,
  });

  @override
  List<Object?> get props => [memberId, memberName];
}

class MemberLeftEvent extends RoomEvent {
  final String memberId;
  final String memberName;

  const MemberLeftEvent({
    required this.memberId,
    required this.memberName,
  });

  @override
  List<Object?> get props => [memberId, memberName];
}

class PeerDisconnectedEvent extends RoomEvent {
  final String peerId;

  const PeerDisconnectedEvent(this.peerId);

  @override
  List<Object?> get props => [peerId];
}

class ResetRoomEvent extends RoomEvent {
  const ResetRoomEvent();
}