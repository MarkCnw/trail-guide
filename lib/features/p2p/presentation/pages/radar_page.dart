import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_guide/features/p2p/presentation/bloc/p2p/p2p_bloc.dart';

// P2P & Room
import '../../domain/entities/peer_entity.dart';
import '../bloc/room/room_bloc.dart';
import '../bloc/room/room_state.dart';
import '../bloc/room/room_event.dart';
import '../../utils/image_helper.dart';

// Location BLoC
import '../../../tracking/presentation/bloc/location/location_bloc.dart';
import '../../../tracking/presentation/bloc/location/location_event.dart';
import '../../../tracking/presentation/bloc/location/location_state.dart';

class RadarPage extends StatefulWidget {
  const RadarPage({super.key});

  @override
  State<RadarPage> createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 🚀 เริ่มดูด GPS เมื่อเปิดแท็บนี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationBloc>().add(StartTrackingEvent());
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    Future.microtask(() => context.read<LocationBloc>().add(StopTrackingEvent()));
    super.dispose();
  }

  void _showEndTripDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Adventure?'),
        content: const Text('Are you sure you want to stop tracking and leave the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // 🚀 1. เช็คก่อนว่าเราเป็น Host หรือ Member
              final isHost = context.read<RoomBloc>().isHost;
              
              if (isHost) {
                // ถ้าเป็น Host -> สั่งปิดห้อง (จะทำการหยุดปล่อยคลื่น Advertising ด้วย)
                context.read<RoomBloc>().add(const CloseRoomEvent(reason: 'Host ended the trip.'));
              } else {
                // ถ้าเป็น Member -> สั่งแค่ออกจากห้อง
                context.read<RoomBloc>().add(const LeaveRoomEvent());
              }

              // 🛑 2. ปิด GPS 
              context.read<LocationBloc>().add(StopTrackingEvent());
              
              // 3. เด้งกลับไปแท็บ Home
              context.go('/home'); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, locationState) {
        if (locationState is LocationTracking) {
          context.read<RoomBloc>().add(
            SendMyLocationEvent(
              latitude: locationState.position.latitude,
              longitude: locationState.position.longitude,
            ),
          );
        }
      },
      child: BlocConsumer<RoomBloc, RoomState>(
        listener: (context, roomState) {
          if (roomState is RoomClosedByHost || roomState is RoomLeft) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trip ended by host.')),
            );
            context.go('/home');
          }
        },
        builder: (context, roomState) {
          // ==========================================
          // 🟢 STATE 3: ทริปเริ่มแล้ว (Active)
          // ==========================================
          if (roomState is RoomTripStarted || roomState is RoomTrackingUpdated) {
            return _buildActiveRadar(context, roomState); 
          }

          // ==========================================
          // ⏳ STATE 2: อยู่ในห้อง แต่ยังไม่เริ่ม (Standby)
          // ==========================================
          if (roomState is RoomCreated || roomState is RoomJoined) {
            final isHost = context.read<RoomBloc>().isHost;
            return Scaffold(
              backgroundColor: const Color(0xFF1E1E1E),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radar, size: 100, color: Colors.orange[300]),
                    const SizedBox(height: 20),
                    Text(
                      isHost ? 'Ready to explore?' : 'Waiting for Host...',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isHost ? 'Go back to lobby to start the trip' : 'The radar will activate once the host starts',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isHost) context.go('/lobby');
                        else context.go('/scan');
                      },
                      icon: const Icon(Icons.group),
                      label: const Text('Go to Team Lobby'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600], foregroundColor: Colors.white),
                    )
                  ],
                ),
              ),
            );
          }

          // ==========================================
          // 🛑 STATE 1: ยังไม่มีห้อง (Offline / Initial)
          // ==========================================
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar, size: 100, color: Colors.grey[700]), 
                  const SizedBox(height: 20),
                  const Text(
                    'Radar Offline',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create or join a room to activate radar',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/scan'), 
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.greenAccent),
                        child: const Text('Join Room'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/lobby'), 
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
                        child: const Text('Create Room'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 🟢 ฟังก์ชันวาดหน้าจอ Active Radar ตัวจริง
  // ==========================================
  Widget _buildActiveRadar(BuildContext context, RoomState roomState) {
    final myDeviceId = context.read<RoomBloc>().deviceId;

    List<PeerEntity> tripMembers = [];
    if (roomState is RoomTripStarted) { // ดึงข้อมูลตอนเริ่มทริป
      tripMembers = roomState.members.where((m) => m.id != myDeviceId).toList();
    } else if (roomState is RoomTrackingUpdated) { // ดึงข้อมูลตอน GPS ขยับ
      tripMembers = roomState.members.where((m) => m.id != myDeviceId).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
          onPressed: _showEndTripDialog,
        ),
        title: const Text(
          'Trail Radar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: Colors.greenAccent),
            onPressed: () {
              // TODO: Re-center
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 📍 พิกัดตัวเอง
          BlocBuilder<LocationBloc, LocationState>(
            builder: (context, locationState) {
              if (locationState is LocationError) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[400],
                  child: Text(locationState.message, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                );
              }
              if (locationState is LocationTracking) {
                final pos = locationState.position;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.black45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gps_fixed, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'My GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.black45,
                child: const Text('Acquiring GPS Signal...', style: TextStyle(color: Colors.orangeAccent), textAlign: TextAlign.center),
              );
            },
          ),

          // 🧭 เรดาร์
          Expanded(
            flex: 3,
            child: Center(child: _buildRadarCircle(tripMembers)),
          ),

          // 👥 รายชื่อเพื่อน
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Team Members',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${tripMembers.length + 1} Connected', 
                          style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: tripMembers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildMemberCard(tripMembers[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarCircle(List<PeerEntity> members) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.greenAccent.withOpacity(0.05),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 1),
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 1),
            ),
          ),
          Container(width: 320, height: 1, color: Colors.greenAccent.withOpacity(0.2)),
          Container(width: 1, height: 320, color: Colors.greenAccent.withOpacity(0.2)),

          AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _radarController.value * 2 * math.pi,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.greenAccent.withOpacity(0.0),
                        Colors.greenAccent.withOpacity(0.5),
                      ],
                      stops: const [0.5, 1.0],
                      startAngle: 0.0,
                      endAngle: math.pi / 2,
                    ),
                  ),
                ),
              );
            },
          ),

          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.blueAccent, blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: const Center(
              child: Icon(Icons.navigation_rounded, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(PeerEntity member) {
    final imageBytes = ImageHelper.decodeBase64(member.imageBase64);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: member.isHost ? Colors.green[100] : Colors.blue[100],
            backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
            child: imageBytes == null
                ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: member.isHost ? Colors.green[700] : Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (member.isHost) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.star_rounded, size: 16, color: Colors.amber[600]),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      member.latitude != null && member.longitude != null
                          ? 'Lat: ${member.latitude!.toStringAsFixed(4)}, Lng: ${member.longitude!.toStringAsFixed(4)}'
                          : 'Waiting for GPS...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
            child: Transform.rotate(
              angle: math.pi / 4, 
              child: Icon(Icons.navigation_rounded, color: Colors.green[600], size: 20),
            ),
          ),
        ],
      ),
    );
  }
}