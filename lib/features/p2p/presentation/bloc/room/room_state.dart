import 'package:equatable/equatable.dart';
import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart';
import 'package:trail_guide/features/p2p/domain/entities/room_entity.dart';

/// Role ของผู้ใช้ในห้อง
enum RoomRole { none, host, member }

/// Base class
abstract class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

// ============================================================
// INITIAL & LOADING
// ============================================================

class RoomInitial extends RoomState {
  const RoomInitial();
}

class RoomLoading extends RoomState {
  final String? message;

  const RoomLoading({this.message});

  @override
  List<Object?> get props => [message];
}

// ============================================================
// HOST STATES
// ============================================================

class RoomCreated extends RoomState {
  final RoomEntity room;
  final List<PeerEntity> connectedMembers;
  final String hostName;
  final String? hostImageBase64;

  const RoomCreated({
    required this.room,
    this.connectedMembers = const [],
    required this.hostName,
    this.hostImageBase64,
  });

  /// จำนวนคนทั้งหมด (รวม Host)
  int get totalCount => connectedMembers.length + 1;

  /// ห้องเต็มหรือยัง
  bool get isFull => totalCount >= room.maxMembers;

  /// ข้อความแสดงจำนวนคน
  String get memberCountDisplay => '$totalCount/${room.maxMembers}';

  /// 🆕 รวมทุกคน (Host + Members) สำหรับแสดงผล
  List<PeerEntity> get allParticipants {
    final list = <PeerEntity>[
      // Host อยู่บนสุด
      PeerEntity(
        id: room.hostId,
        name: hostName,
        imageBase64: hostImageBase64,
        isHost: true,
      ),
      // Members ตามมา
      ...connectedMembers,
    ];
    return list;
  }

  RoomCreated copyWith({
    RoomEntity? room,
    List<PeerEntity>? connectedMembers,
    String? hostName,
    String? hostImageBase64,
  }) {
    return RoomCreated(
      room: room ?? this.room,
      connectedMembers: connectedMembers ?? this.connectedMembers,
      hostName: hostName ?? this.hostName,
      hostImageBase64: hostImageBase64 ?? this.hostImageBase64,
    );
  }

  @override
  List<Object?> get props => [
    room,
    connectedMembers,
    hostName,
    hostImageBase64,
  ];
}

// ============================================================
// MEMBER STATES
// ============================================================

class RoomJoining extends RoomState {
  final String hostPeerId;
  final String hostName;

  const RoomJoining({required this.hostPeerId, required this.hostName});

  @override
  List<Object?> get props => [hostPeerId, hostName];
}

class RoomJoined extends RoomState {
  final String roomId;
  final String roomPin;
  final String roomPassword; // 🆕 เพิ่ม
  final String hostPeerId;
  final String hostName;
  final String? hostImageBase64;
  final int maxMembers;
  final List<PeerEntity> allMembers;

  const RoomJoined({
    required this.roomId,
    required this.roomPin,
    this.roomPassword = '', // 🆕 เพิ่ม
    required this.hostPeerId,
    required this.hostName,
    this.hostImageBase64,
    required this.maxMembers,
    this.allMembers = const [],
  });

  int get totalCount => allMembers.length;

  String get memberCountDisplay => '$totalCount/$maxMembers';

  bool get isFull => totalCount >= maxMembers;

  RoomJoined copyWith({
    String? roomId,
    String? roomPin,
    String? roomPassword,
    String? hostPeerId,
    String? hostName,
    String? hostImageBase64,
    int? maxMembers,
    List<PeerEntity>? allMembers,
  }) {
    return RoomJoined(
      roomId: roomId ?? this.roomId,
      roomPin: roomPin ?? this.roomPin,
      roomPassword: roomPassword ?? this.roomPassword,
      hostPeerId: hostPeerId ?? this.hostPeerId,
      hostName: hostName ?? this.hostName,
      hostImageBase64: hostImageBase64 ?? this.hostImageBase64,
      maxMembers: maxMembers ?? this.maxMembers,
      allMembers: allMembers ?? this.allMembers,
    );
  }

  @override
  List<Object?> get props => [
    roomId,
    roomPin,
    roomPassword,
    hostPeerId,
    hostName,
    hostImageBase64,
    maxMembers,
    allMembers,
  ];
}

// ============================================================
// CLOSED & LEFT
// ============================================================

class RoomClosedByHost extends RoomState {
  final String reason;

  const RoomClosedByHost({this.reason = 'Host closed the room.'});

  @override
  List<Object?> get props => [reason];
}

class RoomLeft extends RoomState {
  const RoomLeft();
}

// ============================================================
// ERROR STATES
// ============================================================

class RoomError extends RoomState {
  final String message;

  const RoomError(this.message);

  @override
  List<Object?> get props => [message];
}

class RoomPasswordError extends RoomState {
  final String message;
  final int? remainingAttempts;

  const RoomPasswordError({
    this.message = 'Wrong password.  Please try again.',
    this.remainingAttempts,
  });

  @override
  List<Object?> get props => [message, remainingAttempts];
}

class RoomFullError extends RoomState {
  final String hostName;

  const RoomFullError({required this.hostName});

  String get message => "Room '$hostName' is full.";

  @override
  List<Object?> get props => [hostName];
}



// เอาไปวางไว้ล่างสุดของไฟล์ room_state.dart
// 🆕 State สำหรับการอัปเดตพิกัดเรียลไทม์ในหน้า Tracking
class RoomTrackingUpdated extends RoomState {
  final List<PeerEntity> members;
  const RoomTrackingUpdated({required this.members});
  @override
  List<Object?> get props => [members];
}

// 🆕 State ตอนเริ่มทริป (ให้ดึงคุณสมบัติมาจาก RoomTrackingUpdated เลย)
class RoomTripStarted extends RoomTrackingUpdated {
  const RoomTripStarted({required super.members});
}

class RoomMemberOfflineAlert extends RoomState {
  final String memberName;
  const RoomMemberOfflineAlert({required this.memberName});

  @override
  // ใส่ DateTime.now() เข้าไปเพื่อให้ State ถือว่าเป็นข้อมูลใหม่เสมอ (บังคับให้ UI เด้งทุกรอบ)
  List<Object> get props => [memberName, DateTime.now()]; 
}