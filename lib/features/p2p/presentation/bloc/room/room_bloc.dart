import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trail_guide/features/p2p/domain/entities/peer_entity.dart';
import 'package:trail_guide/features/p2p/domain/entities/room_entity.dart';
import 'package:trail_guide/features/p2p/domain/entities/room_message_entity.dart';
import 'package:trail_guide/features/p2p/domain/repositories/p2p_repository.dart';
import 'package:trail_guide/features/p2p/presentation/bloc/room/room_event.dart';
import 'package:trail_guide/features/p2p/presentation/bloc/room/room_state.dart';

/// BLoC สำหรับจัดการ Room State
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final P2PRepository _repository;

  /// ข้อมูลห้องปัจจุบัน (สำหรับ Host)
  RoomEntity? _currentRoom;

  /// Role ปัจจุบัน
  RoomRole _currentRole = RoomRole.none;

  /// รายชื่อ Members ที่เชื่อมต่ออยู่ (สำหรับ Host)
  final List<PeerEntity> _connectedMembers = [];

  /// Host Peer ID (สำหรับ Member)
  String? _hostPeerId;

  /// Device ID ของตัวเอง
  String _deviceId = '';

  

  /// Member Name
  String _memberName = '';

  /// 🆕 Member Image Base64
  String? _memberImageBase64;

  /// 🆕 Host Name (เก็บไว้ใช้)
  String _hostName = '';

  /// 🆕 Host Image Base64
  String? _hostImageBase64;

  /// Keep-alive Timer
  Timer? _keepAliveTimer;

  /// Connection check Timer
  Timer? _connectionCheckTimer;

  /// Last ping time for each peer
  final Map<String, DateTime> _lastPingTime = {};

  /// 🆕 All members list (สำหรับ Member เก็บไว้แสดงผล)
  final List<PeerEntity> _allMembersForMember = [];

  RoomBloc({required P2PRepository repository})
    : _repository = repository,
      super(const RoomInitial()) {
    // ลงทะเบียน Event Handlers
    on<CreateRoomEvent>(_onCreateRoom);
    on<CloseRoomEvent>(_onCloseRoom);
    on<JoinRoomEvent>(_onJoinRoom);
    on<LeaveRoomEvent>(_onLeaveRoom);
    on<RoomMessageReceivedEvent>(_onMessageReceived);
    on<MemberJoinedEvent>(_onMemberJoined);
    on<MemberLeftEvent>(_onMemberLeft);
    on<PeerDisconnectedEvent>(_onPeerDisconnected);
    on<ResetRoomEvent>(_onReset);

    // Generate Device ID
    _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Getters
  RoomEntity? get currentRoom => _currentRoom;
  RoomRole get currentRole => _currentRole;
  bool get isHost => _currentRole == RoomRole.host;
  bool get isMember => _currentRole == RoomRole.member;
  bool get isInRoom => _currentRole != RoomRole.none;

  // ============================================================
  // Keep-Alive System
  // ============================================================

  void _startKeepAlive() {
    _stopKeepAlive();

    _keepAliveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _sendPing();
    });

    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 15), (
      _,
    ) {
      _checkConnections();
    });
  }

  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
    _lastPingTime.clear();
  }

  Future<void> _sendPing() async {
    if (isHost) {
      final pingMessage = RoomMessage.ping(
        senderId: _deviceId,
        senderName: _currentRoom?.hostName ?? 'Host',
      );
      for (final member in _connectedMembers) {
        await _repository.sendPayload(member.id, pingMessage.toJson());
      }
    } else if (isMember && _hostPeerId != null) {
      final pingMessage = RoomMessage.ping(
        senderId: _deviceId,
        senderName: _memberName,
      );
      await _repository.sendPayload(_hostPeerId!, pingMessage.toJson());
    }
  }

  void _checkConnections() {
    final now = DateTime.now();
    final timeout = const Duration(seconds: 30);

    if (isHost) {
      final disconnectedMembers = <String>[];

      for (final member in _connectedMembers) {
        final lastPing = _lastPingTime[member.id];
        if (lastPing != null && now.difference(lastPing) > timeout) {
          disconnectedMembers.add(member.id);
        }
      }

      for (final memberId in disconnectedMembers) {
        add(PeerDisconnectedEvent(memberId));
      }
    } else if (isMember && _hostPeerId != null) {
      final lastPing = _lastPingTime[_hostPeerId];
      if (lastPing != null && now.difference(lastPing!) > timeout) {
        add(PeerDisconnectedEvent(_hostPeerId!));
      }
    }
  }

  // ============================================================
  // HOST: สร้างห้อง
  // ============================================================

  Future<void> _onCreateRoom(
    CreateRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    emit(const RoomLoading(message: 'Creating room...'));

    try {
      // 🆕 เก็บ Host info
      _hostName = event.hostName;
      _hostImageBase64 = event.hostImageBase64;

      // 1. สร้าง Room Entity
      _currentRoom = RoomEntity.create(
        password: event.password,
        hostId: _deviceId,
        hostName: event.hostName,
        maxMembers: event.maxMembers,
      );

      // 2. เริ่ม Advertising
      final advertisingName = '${event.hostName}#${_currentRoom!.roomPin}';
      final result = await _repository.startAdvertising(
        advertisingName,
        'star',
      );

      result.fold(
        (failure) {
          _currentRoom = null;
          emit(RoomError(failure.message));
        },
        (_) {
          _currentRole = RoomRole.host;
          _connectedMembers.clear();

          _startKeepAlive();

          // 🆕 เพิ่ม hostName และ hostImageBase64
          emit(
            RoomCreated(
              room: _currentRoom!,
              connectedMembers: const [],
              hostName: _hostName,
              hostImageBase64: _hostImageBase64,
            ),
          );
        },
      );
    } catch (e) {
      _currentRoom = null;
      emit(RoomError('Failed to create room: $e'));
    }
  }

  // ============================================================
  // HOST: ปิดห้อง
  // ============================================================

  Future<void> _onCloseRoom(
    CloseRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    if (!isHost || _currentRoom == null) {
      emit(const RoomError('You are not the host. '));
      return;
    }

    emit(const RoomLoading(message: 'Closing room...'));

    try {
      final closeMessage = RoomMessage.roomClosed(
        hostId: _deviceId,
        hostName: _currentRoom!.hostName,
        reason: event.reason,
      );

      await _broadcastToAllMembers(closeMessage);
      await Future.delayed(const Duration(milliseconds: 500));

      await _repository.stopAdvertising();
      await _repository.stopAll();

      _stopKeepAlive();

      _currentRoom = null;
      _currentRole = RoomRole.none;
      _connectedMembers.clear();
      _hostName = '';
      _hostImageBase64 = null;

      emit(const RoomLeft());
    } catch (e) {
      emit(RoomError('Failed to close room: $e'));
    }
  }

  // ============================================================
  // MEMBER: ขอเข้าห้อง
  // ============================================================

  Future<void> _onJoinRoom(
    JoinRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    emit(
      RoomJoining(hostPeerId: event.hostPeerId, hostName: event.hostName),
    );

    try {
      await _repository.stopDiscovery();

      // 🆕 เก็บ member info
      _memberName = event.memberName;
      _memberImageBase64 = event.memberImageBase64;

      final connectResult = await _repository.connectToPeer(
        event.hostPeerId,
      );

      await connectResult.fold(
        (failure) async {
          emit(RoomError('Failed to connect:  ${failure.message}'));
        },
        (_) async {
          await Future.delayed(const Duration(milliseconds: 800));

          // 🆕 ส่ง imageBase64 ไปด้วย
          final joinRequest = RoomMessage.joinRequest(
            memberId: _deviceId,
            memberName: event.memberName,
            password: event.password,
            imageBase64: event.memberImageBase64,
          );

          final sendResult = await _repository.sendPayload(
            event.hostPeerId,
            joinRequest.toJson(),
          );

          sendResult.fold(
            (failure) {
              emit(
                RoomError(
                  'Failed to send join request: ${failure.message}',
                ),
              );
            },
            (_) {
              _hostPeerId = event.hostPeerId;
              _currentRole = RoomRole.member;
              _lastPingTime[event.hostPeerId] = DateTime.now();
              _startKeepAlive();
            },
          );
        },
      );
    } catch (e) {
      emit(RoomError('Failed to join room: $e'));
    }
  }

  // ============================================================
  // MEMBER: ออกจากห้อง
  // ============================================================

  Future<void> _onLeaveRoom(
    LeaveRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    if (!isMember || _hostPeerId == null) {
      emit(const RoomError('You are not in a room.'));
      return;
    }

    emit(const RoomLoading(message: 'Leaving room...'));

    try {
      final leaveMessage = RoomMessage.leaveRequest(
        memberId: _deviceId,
        memberName: _memberName,
      );

      await _repository.sendPayload(_hostPeerId!, leaveMessage.toJson());
      await Future.delayed(const Duration(milliseconds: 300));

      await _repository.disconnectFromPeer(_hostPeerId!);
      await _repository.stopAll();

      _stopKeepAlive();

      _hostPeerId = null;
      _currentRole = RoomRole.none;
      _allMembersForMember.clear();

      emit(const RoomLeft());
    } catch (e) {
      emit(RoomError('Failed to leave room: $e'));
    }
  }

  // ============================================================
  // รับข้อความจาก Peer
  // ============================================================

  Future<void> _onMessageReceived(
    RoomMessageReceivedEvent event,
    Emitter<RoomState> emit,
  ) async {
    final message = event.message;
    final fromPeerId = event.fromPeerId;

    _lastPingTime[fromPeerId] = DateTime.now();

    switch (message.type) {
      case RoomMessageType.joinRequest:
        if (isHost) {
          await _handleJoinRequest(fromPeerId, message, emit);
        }
        break;

      case RoomMessageType.leaveRequest:
        if (isHost) {
          await _handleLeaveRequest(fromPeerId, message, emit);
        }
        break;

      case RoomMessageType.ping:
        final pongMessage = RoomMessage.pong(
          senderId: _deviceId,
          senderName: isHost
              ? (_currentRoom?.hostName ?? 'Host')
              : _memberName,
        );
        await _repository.sendPayload(fromPeerId, pongMessage.toJson());
        break;

      case RoomMessageType.pong:
        break;

      case RoomMessageType.joinResponse:
        if (isMember) {
          await _handleJoinResponse(message, emit);
        }
        break;

      case RoomMessageType.memberJoined:
        if (isMember) {
          _handleMemberJoinedNotification(message, emit);
        }
        break;

      case RoomMessageType.memberLeft:
        if (isMember) {
          _handleMemberLeftNotification(message, emit);
        }
        break;

      case RoomMessageType.roomClosed:
        if (isMember) {
          await _handleRoomClosed(message, emit);
        }
        break;

      default:
        break;
    }
  }

  // ============================================================
  // HOST: Handle Join Request
  // ============================================================

  Future<void> _handleJoinRequest(
    String fromPeerId,
    RoomMessage message,
    Emitter<RoomState> emit,
  ) async {
    if (_currentRoom == null) return;

    final password = message.password;
    final memberName = message.senderName;
    final memberId = message.senderId;
    final memberImageBase64 = message.imageBase64; // 🆕

    // 1. ตรวจสอบ Password
    if (!_currentRoom!.validatePassword(password ?? '')) {
      final rejectMessage = RoomMessage.joinResponseRejected(
        hostId: _deviceId,
        hostName: _currentRoom!.hostName,
        reason: JoinResponseStatus.rejectedWrongPassword,
      );
      await _repository.sendPayload(fromPeerId, rejectMessage.toJson());
      return;
    }

    // 2. 🆕 ตรวจสอบจำนวนคน (รวม Host)
    // maxMembers = 5 หมายถึงรวม Host แล้ว ดังนั้น members ได้สูงสุด 4 คน
    if (_connectedMembers.length >= (_currentRoom!.maxMembers - 1)) {
      final rejectMessage = RoomMessage.joinResponseRejected(
        hostId: _deviceId,
        hostName: _currentRoom!.hostName,
        reason: JoinResponseStatus.rejectedRoomFull,
      );
      await _repository.sendPayload(fromPeerId, rejectMessage.toJson());
      return;
    }

    // 3. เพิ่ม Member ใหม่
    final alreadyExists = _connectedMembers.any((m) => m.id == fromPeerId);
    if (!alreadyExists) {
      final newMember = PeerEntity(
        id: fromPeerId,
        name: memberName,
        rssi: 0,
        isLost: false,
        imageBase64: memberImageBase64, // 🆕
        isHost: false,
      );
      _connectedMembers.add(newMember);
      _lastPingTime[fromPeerId] = DateTime.now();
    }

    // 4. 🆕 สร้าง members list สำหรับส่งไป Member ใหม่
    final membersList = _connectedMembers
        .map(
          (m) => {
            'id': m.id,
            'name': m.name,
            'imageBase64': m.imageBase64,
            'isHost': false,
          },
        )
        .toList();

    // 5. ส่ง ACCEPTED ไป Member ใหม่ (พร้อม Host info และ members list)
    final acceptMessage = RoomMessage.joinResponseAccepted(
      hostId: _deviceId,
      hostName: _currentRoom!.hostName,
      roomId: _currentRoom!.roomId,
      roomPin: _currentRoom!.roomPin,
      currentMemberCount: _connectedMembers.length + 1, // 🆕 รวม Host
      maxMembers: _currentRoom!.maxMembers,
      hostImageBase64: _hostImageBase64, // 🆕
      roomPassword: _currentRoom!.password,
      members: membersList, // 🆕
    );
    await _repository.sendPayload(fromPeerId, acceptMessage.toJson());

    // 6. Broadcast ไป Members คนอื่นๆ
    final joinedNotification = RoomMessage.memberJoined(
      hostId: _deviceId,
      hostName: _currentRoom!.hostName,
      newMemberId: memberId,
      newMemberName: memberName,
      currentMemberCount: _connectedMembers.length + 1, // 🆕 รวม Host
      maxMembers: _currentRoom!.maxMembers,
      newMemberImageBase64: memberImageBase64, // 🆕
    );
    await _broadcastToAllMembers(
      joinedNotification,
      excludePeerId: fromPeerId,
    );

    // 7. Update State
    emit(
      RoomCreated(
        room: _currentRoom!,
        connectedMembers: List.from(_connectedMembers),
        hostName: _hostName, // 🆕
        hostImageBase64: _hostImageBase64, // 🆕
      ),
    );
  }

  // ============================================================
  // HOST: Handle Leave Request
  // ============================================================

  Future<void> _handleLeaveRequest(
    String fromPeerId,
    RoomMessage message,
    Emitter<RoomState> emit,
  ) async {
    if (_currentRoom == null) return;

    final memberName = message.senderName;
    final memberId = message.senderId;

    _connectedMembers.removeWhere((m) => m.id == fromPeerId);
    _lastPingTime.remove(fromPeerId);

    final leftNotification = RoomMessage.memberLeft(
      hostId: _deviceId,
      hostName: _currentRoom!.hostName,
      leftMemberId: memberId,
      leftMemberName: memberName,
      currentMemberCount: _connectedMembers.length + 1, // 🆕 รวม Host
      maxMembers: _currentRoom!.maxMembers,
    );
    await _broadcastToAllMembers(leftNotification);

    emit(
      RoomCreated(
        room: _currentRoom!,
        connectedMembers: List.from(_connectedMembers),
        hostName: _hostName, // 🆕
        hostImageBase64: _hostImageBase64, // 🆕
      ),
    );
  }

  // ============================================================
  // MEMBER: Handle Join Response
  // ============================================================

  // ============================================================
  // MEMBER:  Handle Join Response
  // ============================================================

  Future<void> _handleJoinResponse(
    RoomMessage message,
    Emitter<RoomState> emit,
  ) async {
    if (message.isJoinAccepted) {
      // 🆕 สร้าง allMembers list (รวม Host)
      _allMembersForMember.clear();

      // เพิ่ม Host เป็นคนแรก
      _allMembersForMember.add(
        PeerEntity(
          id: message.senderId,
          name: message.senderName,
          imageBase64: message.hostImageBase64,
          isHost: true,
        ),
      );

      // เพิ่ม Members ที่มีอยู่แล้ว (ไม่รวมตัวเอง)
      final members = message.members;
      if (members != null) {
        for (final m in members) {
          final memberId = m['id'] as String? ?? '';
          // 🔧 FIX: ไม่เพิ่มตัวเองซ้ำ
          if (memberId != _deviceId && memberId.isNotEmpty) {
            _allMembersForMember.add(
              PeerEntity(
                id: memberId,
                name: m['name'] as String? ?? '',
                imageBase64: m['imageBase64'] as String?,
                isHost: false,
              ),
            );
          }
        }
      }

      // เพิ่มตัวเอง (ครั้งเดียว)
      _allMembersForMember.add(
        PeerEntity(
          id: _deviceId,
          name: _memberName,
          imageBase64: _memberImageBase64,
          isHost: false,
        ),
      );

      emit(
        RoomJoined(
          roomId: message.roomId ?? '',
          roomPin: message.payload['roomPin'] as String? ?? '',
         roomPassword: message.roomPassword ?? '',  // 🆕 เพิ่ม
          hostPeerId: _hostPeerId ?? '',
          hostName: message.senderName,
          hostImageBase64: message.hostImageBase64,
          maxMembers: message.maxMembers ?? 5,
          allMembers: List.from(_allMembersForMember),
        ),
      );
    } else {
      _stopKeepAlive();

      final status = message.joinResponseStatus;

      switch (status) {
        case JoinResponseStatus.rejectedWrongPassword:
          emit(
            RoomPasswordError(
              message: message.message ?? 'Wrong password. ',
            ),
          );
          break;

        case JoinResponseStatus.rejectedRoomFull:
          emit(RoomFullError(hostName: message.senderName));
          break;

        default:
          emit(RoomError(message.message ?? 'Cannot join room.'));
      }

      _hostPeerId = null;
      _currentRole = RoomRole.none;
    }
  }

  // ============================================================
  // MEMBER:  Handle Member Joined Notification
  // ============================================================

  void _handleMemberJoinedNotification(
    RoomMessage message,
    Emitter<RoomState> emit,
  ) {
    final currentState = state;
    if (currentState is RoomJoined) {
      // 🆕 เพิ่ม member ใหม่เข้า list
      final newMember = PeerEntity(
        id: message.memberId ?? '',
        name: message.memberName ?? '',
        imageBase64: message.imageBase64,
        isHost: false,
      );

      // เช็คว่ามีอยู่แล้วหรือยัง
      final alreadyExists = _allMembersForMember.any(
        (m) => m.id == newMember.id,
      );
      if (!alreadyExists) {
        _allMembersForMember.add(newMember);
      }

      emit(
        currentState.copyWith(allMembers: List.from(_allMembersForMember)),
      );
    }
  }

  // ============================================================
  // MEMBER: Handle Member Left Notification
  // ============================================================

  void _handleMemberLeftNotification(
    RoomMessage message,
    Emitter<RoomState> emit,
  ) {
    final currentState = state;
    if (currentState is RoomJoined) {
      // 🆕 ลบ member ออกจาก list
      _allMembersForMember.removeWhere((m) => m.id == message.memberId);

      emit(
        currentState.copyWith(allMembers: List.from(_allMembersForMember)),
      );
    }
  }

  // ============================================================
  // MEMBER: Handle Room Closed
  // ============================================================

  Future<void> _handleRoomClosed(
    RoomMessage message,
    Emitter<RoomState> emit,
  ) async {
    _stopKeepAlive();

    if (_hostPeerId != null) {
      await _repository.disconnectFromPeer(_hostPeerId!);
    }
    await _repository.stopAll();

    _hostPeerId = null;
    _currentRole = RoomRole.none;
    _allMembersForMember.clear();

    emit(
      RoomClosedByHost(
        reason:
            message.payload['reason'] as String? ??
            'Host closed the room.',
      ),
    );
  }

  // ============================================================
  // Internal Events
  // ============================================================

  void _onMemberJoined(MemberJoinedEvent event, Emitter<RoomState> emit) {}

  void _onMemberLeft(MemberLeftEvent event, Emitter<RoomState> emit) {}

  Future<void> _onPeerDisconnected(
    PeerDisconnectedEvent event,
    Emitter<RoomState> emit,
  ) async {
    _lastPingTime.remove(event.peerId);

    if (isHost) {
      final disconnectedMember = _connectedMembers
          .where((m) => m.id == event.peerId)
          .firstOrNull;

      if (disconnectedMember != null) {
        _connectedMembers.removeWhere((m) => m.id == event.peerId);

        if (_currentRoom != null) {
          final leftNotification = RoomMessage.memberLeft(
            hostId: _deviceId,
            hostName: _currentRoom!.hostName,
            leftMemberId: disconnectedMember.id,
            leftMemberName: disconnectedMember.name,
            currentMemberCount: _connectedMembers.length + 1,
            maxMembers: _currentRoom!.maxMembers,
          );
          await _broadcastToAllMembers(leftNotification);
        }

        emit(
          RoomCreated(
            room: _currentRoom!,
            connectedMembers: List.from(_connectedMembers),
            hostName: _hostName,
            hostImageBase64: _hostImageBase64,
          ),
        );
      }
    } else if (isMember) {
      if (event.peerId == _hostPeerId) {
        _stopKeepAlive();
        _hostPeerId = null;
        _currentRole = RoomRole.none;
        _allMembersForMember.clear();
        emit(const RoomClosedByHost(reason: 'Lost connection to host.'));
      }
    }
  }

  // ============================================================
  // Reset
  // ============================================================

  Future<void> _onReset(
    ResetRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    _stopKeepAlive();
    await _repository.stopAll();

    _currentRoom = null;
    _currentRole = RoomRole.none;
    _connectedMembers.clear();
    _hostPeerId = null;
    _lastPingTime.clear();
    _allMembersForMember.clear();
    _hostName = '';
    _hostImageBase64 = null;

    emit(const RoomInitial());
  }

  // ============================================================
  // Helpers
  // ============================================================

  Future<void> _broadcastToAllMembers(
    RoomMessage message, {
    String? excludePeerId,
  }) async {
    for (final member in _connectedMembers) {
      if (member.id != excludePeerId) {
        await _repository.sendPayload(member.id, message.toJson());
      }
    }
  }

  void processIncomingMessage(String fromPeerId, Uint8List bytes) {
    try {
      final message = RoomMessage.fromBytes(bytes.toList());
      add(
        RoomMessageReceivedEvent(fromPeerId: fromPeerId, message: message),
      );
    } catch (e) {
      print('RoomBloc: Failed to parse message: $e');
    }
  }

  void processPeerDisconnected(String peerId) {
    add(PeerDisconnectedEvent(peerId));
  }

  @override
  Future<void> close() {
    _stopKeepAlive();
    return super.close();
  }
}
