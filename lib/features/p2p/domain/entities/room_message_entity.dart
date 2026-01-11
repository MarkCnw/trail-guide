import 'dart:convert';
import 'package:equatable/equatable.dart';

/// ประเภทข้อความที่ส่งระหว่าง Host ↔ Member
enum RoomMessageType {
  // ===== Member → Host =====

  /// Member ขอเข้าห้อง (ส่ง password มาด้วย)
  joinRequest,

  /// Member ขอออกจากห้อง
  leaveRequest,

  // ===== Host → Member =====

  /// Host ตอบกลับการขอเข้าห้อง
  joinResponse,

  /// Host แจ้งว่ามี Member ใหม่เข้ามา
  memberJoined,

  /// Host แจ้งว่ามี Member ออกไป
  memberLeft,

  /// Host ปิดห้อง
  roomClosed,

  /// Host kick Member ออก (อนาคต)
  memberKicked,

  // ===== Both Ways =====

  /// อัปเดตตำแหน่ง GPS (ใช้ตอน Tracking)
  locationUpdate,

  /// ข้อความทั่วไป (อนาคต)
  generalMessage,

  /// Ping เพื่อเช็คว่ายังเชื่อมต่ออยู่
  ping,

  /// ตอบกลับ Ping
  pong,
}

/// สถานะการตอบกลับ Join Request
enum JoinResponseStatus {
  /// ยอมรับ - เข้าห้องได้
  accepted,

  /// ปฏิเสธ - Password ผิด
  rejectedWrongPassword,

  /// ปฏิเสธ - ห้องเต็ม
  rejectedRoomFull,

  /// ปฏิเสธ - ห้องปิดแล้ว
  rejectedRoomClosed,

  /// ปฏิเสธ - เหตุผลอื่น
  rejectedOther,
}

/// Model หลักสำหรับข้อความที่ส่งระหว่าง Host ↔ Member
/// ใช้ JSON format เพื่อส่งผ่าน nearby_connections
class RoomMessage extends Equatable {
  /// ประเภทข้อความ
  final RoomMessageType type;

  /// ID ของผู้ส่ง
  final String senderId;

  /// ชื่อผู้ส่ง
  final String senderName;

  /// Timestamp ที่ส่ง
  final DateTime timestamp;

  /// ข้อมูลเพิ่มเติม (แตกต่างกันตาม type)
  final Map<String, dynamic> payload;

  const RoomMessage({
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.payload = const {},
  });

  // ============================================================
  // Factory Constructors สำหรับสร้างข้อความแต่ละประเภท
  // ============================================================

  /// Member ขอเข้าห้อง
  factory RoomMessage.joinRequest({
    required String memberId,
    required String memberName,
    required String password,
    String? imageBase64, // 🆕 เพิ่ม
  }) {
    return RoomMessage(
      type: RoomMessageType.joinRequest,
      senderId: memberId,
      senderName: memberName,
      timestamp: DateTime.now(),
      payload: {
        'password': password,
        'imageBase64': imageBase64, // 🆕 เพิ่ม
      },
    );
  }

  /// Host ตอบรับการเข้าห้อง
  factory RoomMessage.joinResponseAccepted({
    required String hostId,
    required String hostName,
    required String roomId,
    required String roomPin,
    required int currentMemberCount,
    required int maxMembers,
    String? hostImageBase64,
    String? roomPassword, // 🆕 เพิ่ม
    List<Map<String, dynamic>>? members,
  }) {
    return RoomMessage(
      type: RoomMessageType.joinResponse,
      senderId: hostId,
      senderName: hostName,
      timestamp: DateTime.now(),
      payload: {
        'status': JoinResponseStatus.accepted.name,
        'roomId': roomId,
        'roomPin': roomPin,
        'roomPassword': roomPassword, // 🆕 เพิ่ม
        'currentMemberCount': currentMemberCount,
        'maxMembers': maxMembers,
        'message': 'Welcome to the room!',
        'hostImageBase64': hostImageBase64,
        'members': members,
      },
    );
  }

  /// Host ปฏิเสธการเข้าห้อง
  factory RoomMessage.joinResponseRejected({
    required String hostId,
    required String hostName,
    required JoinResponseStatus reason,
    String? customMessage,
  }) {
    String message;
    switch (reason) {
      case JoinResponseStatus.rejectedWrongPassword:
        message = customMessage ?? 'Wrong password.  Please try again.';
        break;
      case JoinResponseStatus.rejectedRoomFull:
        message =
            customMessage ?? 'Room is full. Please try another room.';
        break;
      case JoinResponseStatus.rejectedRoomClosed:
        message = customMessage ?? 'Room has been closed. ';
        break;
      default:
        message = customMessage ?? 'Cannot join room. ';
    }

    return RoomMessage(
      type: RoomMessageType.joinResponse,
      senderId: hostId,
      senderName: hostName,
      timestamp: DateTime.now(),
      payload: {'status': reason.name, 'message': message},
    );
  }

  /// Host แจ้งว่ามี Member ใหม่เข้ามา
  factory RoomMessage.memberJoined({
    required String hostId,
    required String hostName,
    required String newMemberId,
    required String newMemberName,
    required int currentMemberCount,
    required int maxMembers,
    String? newMemberImageBase64, // 🆕 เพิ่ม
  }) {
    return RoomMessage(
      type: RoomMessageType.memberJoined,
      senderId: hostId,
      senderName: hostName,
      timestamp: DateTime.now(),
      payload: {
        'memberId': newMemberId,
        'memberName': newMemberName,
        'currentMemberCount': currentMemberCount,
        'maxMembers': maxMembers,
        'imageBase64': newMemberImageBase64, // 🆕 เพิ่ม
      },
    );
  }

  /// Host แจ้งว่ามี Member ออกไป
  factory RoomMessage.memberLeft({
    required String hostId,
    required String hostName,
    required String leftMemberId,
    required String leftMemberName,
    required int currentMemberCount,
    required int maxMembers,
  }) {
    return RoomMessage(
      type: RoomMessageType.memberLeft,
      senderId: hostId,
      senderName: hostName,
      timestamp: DateTime.now(),
      payload: {
        'memberId': leftMemberId,
        'memberName': leftMemberName,
        'currentMemberCount': currentMemberCount,
        'maxMembers': maxMembers,
      },
    );
  }

  /// Member ขอออกจากห้อง
  factory RoomMessage.leaveRequest({
    required String memberId,
    required String memberName,
  }) {
    return RoomMessage(
      type: RoomMessageType.leaveRequest,
      senderId: memberId,
      senderName: memberName,
      timestamp: DateTime.now(),
    );
  }

  /// Host ปิดห้อง
  factory RoomMessage.roomClosed({
    required String hostId,
    required String hostName,
    String? reason,
  }) {
    return RoomMessage(
      type: RoomMessageType.roomClosed,
      senderId: hostId,
      senderName: hostName,
      timestamp: DateTime.now(),
      payload: {'reason': reason ?? 'Host closed the room.'},
    );
  }

  /// อัปเดตตำแหน่ง GPS
  factory RoomMessage.locationUpdate({
    required String senderId,
    required String senderName,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
  }) {
    return RoomMessage(
      type: RoomMessageType.locationUpdate,
      senderId: senderId,
      senderName: senderName,
      timestamp: DateTime.now(),
      payload: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
      },
    );
  }

  /// Ping
  factory RoomMessage.ping({
    required String senderId,
    required String senderName,
  }) {
    return RoomMessage(
      type: RoomMessageType.ping,
      senderId: senderId,
      senderName: senderName,
      timestamp: DateTime.now(),
    );
  }

  /// Pong (ตอบกลับ Ping)
  factory RoomMessage.pong({
    required String senderId,
    required String senderName,
  }) {
    return RoomMessage(
      type: RoomMessageType.pong,
      senderId: senderId,
      senderName: senderName,
      timestamp: DateTime.now(),
    );
  }

  // ============================================================
  // Helper Getters สำหรับดึงข้อมูลจาก Payload
  // ============================================================

  /// ดึง Password จาก joinRequest
  String? get password => payload['password'] as String?;

  /// 🆕 ดึง roomPassword จาก joinResponse
  String? get roomPassword => payload['roomPassword'] as String?;

  /// ดึง JoinResponseStatus
  JoinResponseStatus? get joinResponseStatus {
    final statusStr = payload['status'] as String?;
    if (statusStr == null) return null;
    return JoinResponseStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => JoinResponseStatus.rejectedOther,
    );
  }

  /// เช็คว่า Join สำเร็จไหม
  bool get isJoinAccepted =>
      type == RoomMessageType.joinResponse &&
      joinResponseStatus == JoinResponseStatus.accepted;

  /// ดึงข้อความ
  String? get message => payload['message'] as String?;

  /// ดึง Room ID
  String? get roomId => payload['roomId'] as String?;

  /// ดึงจำนวน Member ปัจจุบัน
  int? get currentMemberCount => payload['currentMemberCount'] as int?;

  /// ดึงจำนวน Member สูงสุด
  int? get maxMembers => payload['maxMembers'] as int?;

  /// ดึง Member ID (สำหรับ memberJoined/memberLeft)
  String? get memberId => payload['memberId'] as String?;

  /// ดึง Member Name
  String? get memberName => payload['memberName'] as String?;

  /// ดึง Latitude
  double? get latitude => payload['latitude'] as double?;

  /// ดึง Longitude
  double? get longitude => payload['longitude'] as double?;

  String? get imageBase64 => payload['imageBase64'] as String?;

  /// ดึง hostImageBase64
  String? get hostImageBase64 => payload['hostImageBase64'] as String?;

  /// ดึงรายชื่อ members
  List<Map<String, dynamic>>? get members {
    final list = payload['members'];
    if (list == null) return null;
    return List<Map<String, dynamic>>.from(list);
  }

  // ============================================================
  // Serialization
  // ============================================================

  /// แปลงเป็น Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
    };
  }

  /// แปลงเป็น JSON String (สำหรับส่งผ่าน nearby_connections)
  String toJson() => jsonEncode(toMap());

  /// แปลงเป็น bytes (สำหรับ sendBytesPayload)
  List<int> toBytes() => utf8.encode(toJson());

  /// สร้างจาก Map
  factory RoomMessage.fromMap(Map<String, dynamic> map) {
    return RoomMessage(
      type: RoomMessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RoomMessageType.generalMessage,
      ),
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
    );
  }

  /// สร้างจาก JSON String
  factory RoomMessage.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return RoomMessage.fromMap(map);
  }

  /// สร้างจาก bytes (จาก onPayLoadRecieved)
  factory RoomMessage.fromBytes(List<int> bytes) {
    final jsonStr = utf8.decode(bytes);
    return RoomMessage.fromJson(jsonStr);
  }

  @override
  List<Object?> get props => [
    type,
    senderId,
    senderName,
    timestamp,
    payload,
  ];

  @override
  String toString() {
    return 'RoomMessage(type: ${type.name}, from: $senderName, payload: $payload)';
  }
}
