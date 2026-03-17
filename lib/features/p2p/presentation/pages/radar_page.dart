import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_guide/core/utils/location_calculator.dart';
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

class _RadarPageState extends State<RadarPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  
  // 🌟 ประกาศตัวแปรเก็บ LocationBloc เพื่อป้องกันบัค context พังตอนสลับหน้า
  late final LocationBloc _locationBloc;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // ดึงค่ามาเก็บไว้ในตัวแปรตั้งแต่เริ่มสร้างหน้าจอ
    _locationBloc = context.read<LocationBloc>();

    // 🚀 เริ่มดูด GPS เมื่อเปิดแท็บนี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationBloc.add(StartTrackingEvent());
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    // 🌟 สั่งหยุด GPS ผ่านตัวแปรตรงๆ ไม่มี Future.microtask หรือ context แล้ว
    _locationBloc.add(StopTrackingEvent());
    super.dispose();
  }

  void _showEndTripDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('End Adventure?'),
        content: const Text(
          'Are you sure you want to stop tracking and leave the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // 🚀 1. เช็คก่อนว่าเราเป็น Host หรือ Member
              final isHost = context.read<RoomBloc>().isHost;

              if (isHost) {
                // ถ้าเป็น Host -> สั่งปิดห้อง (จะทำการหยุดปล่อยคลื่น Advertising ด้วย)
                context.read<RoomBloc>().add(
                  const CloseRoomEvent(reason: 'Host ended the trip.'),
                );
              } else {
                // ถ้าเป็น Member -> สั่งแค่ออกจากห้อง
                context.read<RoomBloc>().add(const LeaveRoomEvent());
              }

              // 🛑 2. ปิด GPS
              _locationBloc.add(StopTrackingEvent());

          
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          if (roomState is RoomClosedByHost) {
            // กรณี Host เป็นคนกดปิดห้อง
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(roomState.reason),
                backgroundColor: Colors.red[600],
              ),
            );
            context.go('/radar');
          } else if (roomState is RoomLeft) {
            // กรณี Member (ตัวเรา) กดออกเอง
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('You left the adventure.'),
                backgroundColor: Colors.orange[600],
              ),
            );
            context.go('/home');
          }
        },
        builder: (context, roomState) {
          // ==========================================
          // 🟢 STATE 3: ทริปเริ่มแล้ว (Active)
          // ==========================================
          if (roomState is RoomTripStarted ||
              roomState is RoomTrackingUpdated) {
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
                    Icon(
                      Icons.radar,
                      size: 100,
                      color: Colors.orange[300],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isHost ? 'Ready to explore?' : 'Waiting for Host...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isHost
                          ? 'Go back to lobby to start the trip'
                          : 'The radar will activate once the host starts',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isHost) {
                          context.go('/lobby');
                        } else {
                          context.go('/scan');
                        }
                      },
                      icon: const Icon(Icons.group),
                      label: const Text('Go to Team Lobby'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create or join a room to activate radar',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/scan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.greenAccent,
                        ),
                        child: const Text('Join Room'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/lobby'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Create Room'),
                      ),
                    ],
                  ),
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
    if (roomState is RoomTripStarted) {
      // ดึงข้อมูลตอนเริ่มทริป
      tripMembers = roomState.members
          .where((m) => m.id != myDeviceId)
          .toList();
    } else if (roomState is RoomTrackingUpdated) {
      // ดึงข้อมูลตอน GPS ขยับ
      tripMembers = roomState.members
          .where((m) => m.id != myDeviceId)
          .toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.power_settings_new_rounded,
            color: Colors.redAccent,
          ),
          onPressed: _showEndTripDialog,
        ),
        title: const Text(
          'Trail Radar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        
      ),
      // 🔥 รวบ BlocBuilder มาไว้ตรงนี้เลย ดึงพิกัดครั้งเดียวใช้ได้ทั้งหน้า!
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, locationState) {
          double? myLat;
          double? myLng;
          double myHeading = 0.0; // 🆕 1. เพิ่มตัวแปรเก็บทิศที่เราหันหน้า

          // ดึงพิกัดของเราออกมา
          if (locationState is LocationTracking) {
            myLat = locationState.position.latitude;
            myLng = locationState.position.longitude;
            myHeading = locationState.position.heading; // 🆕 ดึงค่า heading มาจาก
          }

          return Column(
            children: [
              // 📍 พิกัดตัวเอง
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.symmetric(
              //     vertical: 8,
              //     horizontal: 16,
              //   ),
              //   color: Colors.black45,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(
              //         myLat != null
              //             ? Icons.gps_fixed
              //             : Icons.gps_not_fixed,
              //         color: myLat != null
              //             ? Colors.greenAccent
              //             : Colors.orangeAccent,
              //         size: 16,
              //       ),
              //       const SizedBox(width: 8),
              //       Text(
              //         myLat != null
              //             ? 'My GPS: ${myLat.toStringAsFixed(5)}, ${myLng!.toStringAsFixed(5)}'
              //             : 'Acquiring GPS Signal...',
              //         style: TextStyle(
              //           color: myLat != null
              //               ? Colors.greenAccent
              //               : Colors.orangeAccent,
              //           fontFamily: 'monospace',
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // 🧭 เรดาร์
              Expanded(
                flex: 3,
                child: Center(
                  // ✅ ส่งพิกัดตัวเองเข้าไปด้วย 3 ตัวแปรครบถ้วน
                  child: _buildRadarCircle(tripMembers, myLat, myLng, myHeading),
                ),
              ),

              // 👥 รายชื่อเพื่อน
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: 24,
                    right: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Team Members',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${tripMembers.length + 1} Connected',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: tripMembers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            // โยนพิกัดเพื่อน และพิกัดเรา เข้าไปคำนวณในการ์ด!
                            return _buildMemberCard(
                              tripMembers[index],
                              myLat,
                              myLng,
                              myHeading,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🟢 ฟังก์ชันวาดวงกลมเรดาร์ และจุดของเพื่อนๆ
  Widget _buildRadarCircle(
    List<PeerEntity> members,
    double? myLat,
    double? myLng,
    double myHeading, // 🆕 รับค่าเข็มทิศตรงนี้
  ) {
    const double radarSize = 320.0;
    const double centerOffset = radarSize / 2;
    const double maxDistanceMeters = 1000.0; // ขอบเรดาร์คือ 1 กิโลเมตร

    List<Widget> radarBlips = [];

    // ถ้าเรามี GPS และเพื่อนมี GPS ถึงจะคำนวณวาดจุด
    if (myLat != null && myLng != null) {
      for (var member in members) {
        if (member.latitude != null && member.longitude != null) {
          // 1. หาระยะทาง
          double distance = LocationCalculator.calculateDistance(
            myLat,
            myLng,
            member.latitude!,
            member.longitude!,
          );

          // 2. ล็อคไม่ให้จุดกระเด็นทะลุขอบจอ
          double drawDistance = distance > maxDistanceMeters
              ? maxDistanceMeters
              : distance;
          double scaledRadius =
              (drawDistance / maxDistanceMeters) * centerOffset;

          // 3. หาองศาทิศทาง
          double bearing = LocationCalculator.calculateBearing(
            myLat,
            myLng,
            member.latitude!,
            member.longitude!,
          );

          // 🆕 3.5 หักลบทิศทางโลก ด้วยทิศทางที่เรากำลังหันหน้าไป
          double relativeBearing = bearing - myHeading;

          // 4. แปลงองศาเข็มทิศ เป็นองศาคณิตศาสตร์ และแปลงเป็น Radians
          double mathAngle = (relativeBearing - 90) * (math.pi / 180);

          // 5. หาพิกัด X, Y บนหน้าจอ
          double x = centerOffset + (scaledRadius * math.cos(mathAngle));
          double y = centerOffset + (scaledRadius * math.sin(mathAngle));

          // 6. สร้างจุดและเอาไปแปะในลิสต์
          radarBlips.add(
            Positioned(
              left: x - 12, // ให้จุดอยู่กึ่งกลางพิกัดพอดี (ขนาดจุดคือ 24x24)
              top: y - 12,
              child: _buildRadarDot(member),
            ),
          );
        }
      }
    }

    return Container(
      width: radarSize,
      height: radarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.greenAccent.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        // ใช้ Stack วางซ้อนกัน (พื้นหลังเรดาร์ -> แสงกวาด -> จุดเพื่อน -> ตัวเราตรงกลาง)
        children: [
          // วงแหวนระยะ 1 (ประมาณ 666 เมตร)
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
          ),
          // วงแหวนระยะ 2 (ประมาณ 333 เมตร)
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
          ),
          // เส้นกากบาท แกน X, Y
          Center(
            child: Container(
              width: radarSize,
              height: 1,
              color: Colors.greenAccent.withOpacity(0.2),
            ),
          ),
          Center(
            child: Container(
              width: 1,
              height: radarSize,
              color: Colors.greenAccent.withOpacity(0.2),
            ),
          ),

          // 📡 แสงเรดาร์หมุนๆ
          Center(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _radarController.value * 2 * math.pi,
                  child: Container(
                    width: radarSize,
                    height: radarSize,
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
          ),

          // 📍 วางจุดพิกัดเพื่อนลงบนเรดาร์
          ...radarBlips,

          // 🔵 จุดศูนย์กลาง (ตัวเราเอง)
          Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.navigation_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔴 ฟังก์ชันสร้างจุด 1 จุดบนเรดาร์
  Widget _buildRadarDot(PeerEntity member) {
    // กำหนดสี: Host สีเหลืองอำพัน, Member สีเขียวสว่าง
    final isActive = member.isActive;
    Color color;
    if (!isActive) {
      color = Colors.grey; 
    } else {
      color = member.isHost ? Colors.amberAccent : Colors.greenAccent;
    }

    return Tooltip(
      message: member.name, // กดค้างเพื่อดูชื่อได้
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
         color: color.withValues(alpha :isActive ? 0.8 : 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: color, blurRadius:isActive? 8:4, spreadRadius: 1),
          ],
        ),
        child: Center(
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 ฟังก์ชันสร้างการ์ดรายชื่อเพื่อน (รับ 3 พารามิเตอร์)
  Widget _buildMemberCard(PeerEntity member, double? myLat, double? myLng ,double myHeading) {
    final imageBytes = ImageHelper.decodeBase64(member.imageBase64);
    final isActive = member.isActive;

    // 🧮 ตัวแปรสำหรับคำนวณ
    String distanceText = 'Waiting for GPS...';
    double bearingAngle = 0.0;
    bool canCalculate = false;

    // ถ้าทั้งคู่มีพิกัด GPS -> เริ่มคำนวณเลย!
    if (myLat != null &&
        myLng != null &&
        member.latitude != null &&
        member.longitude != null) {
      canCalculate = true;

      // 1. คำนวณระยะทาง
      final distanceInMeters = LocationCalculator.calculateDistance(
        myLat,
        myLng,
        member.latitude!,
        member.longitude!,
      );
      


      // จัด Format ให้ดูสวย (ถ้าเกิน 1000m ให้โชว์เป็น km)
      if (distanceInMeters >= 1000) {
        distanceText =
            '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
      } else {
        distanceText = '${distanceInMeters.toStringAsFixed(0)} m away';
      }
      if (!isActive) {
        if (member.lastUpdatedAt != null) {
          final minutesAgo = DateTime.now().difference(member.lastUpdatedAt!).inMinutes;
          if (minutesAgo == 0) {
            distanceText = 'Offline (Just now) - Last at ${(distanceInMeters).toStringAsFixed(0)}m';
          } else {
            distanceText = 'Offline ($minutesAgo min ago) - Last at ${(distanceInMeters).toStringAsFixed(0)}m';
          }
        } else {
          distanceText = 'Offline';
        }
      } else {
        // ทำงานปกติถ้ายังออนไลน์อยู่
        if (distanceInMeters >= 1000) {
          distanceText = '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
        } else {
          distanceText = '${distanceInMeters.toStringAsFixed(0)} m away';
        }
      }

      // 2. คำนวณทิศทาง (องศา) แล้วแปลงเป็นเรเดียนสำหรับหมุนไอคอน
      final bearingInDegrees = LocationCalculator.calculateBearing(
        myLat,
        myLng,
        member.latitude!,
        member.longitude!,
      );
      final relativeBearing = bearingInDegrees - myHeading;
      bearingAngle = relativeBearing * (math.pi / 180);
    }else if (!isActive) {
       distanceText = 'Offline'; // กรณีหลุดตั้งแต่ยังไม่มี GPS
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:isActive? Colors.white: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: member.isHost
                ? Colors.green[300]
                : (member.isHost ? Colors.green[100] : Colors.blue[100]),
            backgroundImage: imageBytes != null
                ? MemoryImage(imageBytes)
                : null,
            child: imageBytes == null
                ? Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: member.isHost
                          ? Colors.green[700]
                          : Colors.blue[700],
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
                    Text(
                      member.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                       color: isActive ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    if (member.isHost) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber[600],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      !isActive 
                          ? Icons.cloud_off_rounded // 🟢 เปลี่ยนไอคอนถ้าหลุด
                          : (canCalculate ? Icons.social_distance_rounded : Icons.location_off_rounded),
                      size: 14,
                      color: !isActive 
                          ? Colors.red[300] 
                          : (canCalculate ? Colors.green[600] : Colors.grey[500]),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      distanceText,
                      style: TextStyle(
                        color: canCalculate
                            ? Colors.grey[800]
                            : Colors.grey[500],
                        fontSize: 13,
                        fontWeight: canCalculate
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🧭 เข็มทิศชี้เป้าหมาย
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
             color: !isActive 
                  ? Colors.grey[200] 
                  : (canCalculate ? Colors.green[50] : Colors.grey[100]),
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: canCalculate
                  ? bearingAngle
                  : math.pi / 4, // ถ้ายังไม่มี GPS ให้ชี้เฉียงๆ ไว้ก่อน
              child: Icon(
                Icons.navigation_rounded,
                color: canCalculate ? Colors.green[600] : Colors.grey[400],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}