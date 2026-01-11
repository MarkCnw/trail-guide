import 'package:equatable/equatable.dart';
import 'peer_entity.dart';

/// สถานะของห้อง
enum RoomStatus {
  /// ห้องกำลังรอคนเข้า (Host สร้างแล้ว รอ Members)
  waiting,

  /// ห้องกำลังใช้งาน (เริ่ม Trip แล้ว)
  active,

  /// ห้องถูกปิดแล้ว
  closed,
}

/// Entity หลักสำหรับเก็บข้อมูลห้อง
/// ใช้ Equatable เพื่อให้ BLoC เปรียบเทียบ State ได้ง่าย
class RoomEntity extends Equatable {
  /// ID ห้องแบบ unique (ใช้ timestamp + random)
  final String roomId;

  /// PIN 6 หลักสำหรับให้ Member ค้นหาห้อง
  final String roomPin;

  /// Password 4 หลักสำหรับเข้าห้อง
  final String password;

  /// Device ID ของ Host
  final String hostId;

  /// ชื่อที่แสดงของ Host
  final String hostName;

  /// จำนวน Members สูงสุดที่รับได้
  final int maxMembers;

  /// รายชื่อ Members ที่อยู่ในห้อง (ไม่รวม Host)
  final List<PeerEntity> members;

  /// สถานะปัจจุบันของห้อง
  final RoomStatus status;

  /// เวลาที่สร้างห้อง
  final DateTime createdAt;

  const RoomEntity({
    required this.roomId,
    required this.roomPin,
    required this.password,
    required this. hostId,
    required this. hostName,
    this.maxMembers = 5,
    this.members = const [],
    this.status = RoomStatus.waiting,
    required this.createdAt,
  });

  /// จำนวน Members ปัจจุบ���น (ไม่รวม Host)
  int get memberCount => members.length;

  /// จำนวนคนทั้งหมดในห้อง (รวม Host)
  int get totalCount => members.length + 1;

  /// ห้องเต็มหรือยัง
  bool get isFull => members.length >= maxMembers;

  /// ยังรับคนได้อีกกี่คน
  int get availableSlots => maxMembers - members.length;

  /// ห้องยังเปิดอยู่ไหม (ไม่ใช่ closed)
  bool get isOpen => status != RoomStatus.closed;

  /// ข้อความแสดงจำนวนคน เช่น "3/5"
  String get memberCountDisplay => '${members.length}/$maxMembers';

  /// สร้าง RoomEntity ใหม่พร้อม generate PIN และ ID อัตโนมัติ
  factory RoomEntity.create({
    required String password,
    required String hostId,
    required String hostName,
    int maxMembers = 5,
  }) {
    return RoomEntity(
      roomId: _generateRoomId(),
      roomPin: _generatePin(),
      password: password,
      hostId: hostId,
      hostName: hostName,
      maxMembers: maxMembers,
      members: const [],
      status: RoomStatus.waiting,
      createdAt: DateTime.now(),
    );
  }

  /// Generate Room ID จาก timestamp + random
  static String _generateRoomId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'room_${timestamp}_$random';
  }

  /// Generate PIN 6 หลัก
  static String _generatePin() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// สร้าง copy ใหม่พร้อมแก้ไขบาง field (Immutable pattern)
  RoomEntity copyWith({
    String? roomId,
    String? roomPin,
    String? password,
    String? hostId,
    String?  hostName,
    int? maxMembers,
    List<PeerEntity>? members,
    RoomStatus? status,
    DateTime? createdAt,
  }) {
    return RoomEntity(
      roomId: roomId ?? this.roomId,
      roomPin: roomPin ?? this. roomPin,
      password: password ?? this.password,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      maxMembers: maxMembers ?? this.maxMembers,
      members: members ?? this.members,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// เพิ่ม Member เข้าห้อง (return null ถ้าห้องเต็ม)
  RoomEntity? addMember(PeerEntity member) {
    if (isFull) return null;

    // เช็คว่ามี member นี้อยู่แล้วหรือยัง
    final alreadyExists = members.any((m) => m.id == member.id);
    if (alreadyExists) return this;

    return copyWith(
      members: [... members, member],
    );
  }

  /// ลบ Member ออกจากห้อง
  RoomEntity removeMember(String memberId) {
    return copyWith(
      members: members.where((m) => m.id != memberId).toList(),
    );
  }

  /// ปิดห้อง
  RoomEntity closeRoom() {
    return copyWith(status: RoomStatus.closed);
  }

  /// เปลี่ยนสถานะเป็น active
  RoomEntity startRoom() {
    return copyWith(status: RoomStatus.active);
  }

  /// ตรวจสอบ Password
  bool validatePassword(String inputPassword) {
    return password == inputPassword;
  }

  /// แปลงเป็น Map (สำหรับส่งผ่าน nearby_connections)
  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomPin':  roomPin,
      'password':  password,
      'hostId':  hostId,
      'hostName': hostName,
      'maxMembers': maxMembers,
      'memberCount': memberCount,
      'status': status.name,
      'createdAt':  createdAt.toIso8601String(),
    };
  }

  /// สร้างจาก Map
  factory RoomEntity.fromMap(Map<String, dynamic> map) {
    return RoomEntity(
      roomId: map['roomId'] as String,
      roomPin: map['roomPin'] as String,
      password: map['password'] as String,
      hostId: map['hostId'] as String,
      hostName: map['hostName'] as String,
      maxMembers: map['maxMembers'] as int?  ?? 5,
      members:  const [], // Members จะถูก manage แยก
      status: RoomStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RoomStatus.waiting,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        roomId,
        roomPin,
        password,
        hostId,
        hostName,
        maxMembers,
        members,
        status,
        createdAt,
      ];

  @override
  String toString() {
    return 'RoomEntity(roomId: $roomId, pin: $roomPin, host: $hostName, '
        'members: $memberCountDisplay, status: ${status.name})';
  }
}