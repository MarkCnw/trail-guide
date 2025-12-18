import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trail_guide/features/p2p/presentation/bloc/p2p_bloc.dart';
import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _userName = "TrailGuide Member";

  @override
  void initState() {
    super.initState();
    // 1. เริ่ม Animation เรดาร์หมุน
    _controller = AnimationController(
      vsync: this,
      duration:  const Duration(seconds: 4),
    )..repeat();

    // 2. ดึงชื่อ User จาก OnboardingCubit
    final onboardingState = context.read<OnboardingCubit>().state;
    if (onboardingState is OnboardingLoaded) {
      _userName = onboardingState.profile.nickname ??  "TrailGuide Member";
    }

    // 3. เริ่มค้นหา Host
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<P2PBloc>().add(StartDiscoveryEvent(_userName));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // แสดง Dialog ไปตั้งค่าแอป
  void _showSettingsDialog(String message) {
    showDialog(
      context:  context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("ต้องการสิทธิ์"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed:  () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors. green,
              foregroundColor: Colors.white,
            ),
            child: const Text("ไปตั้งค่า"),
          ),
        ],
      ),
    );
  }

  // แสดง Dialog เปิด GPS
  void _showGpsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text("เปิด GPS"),
          ],
        ),
        content: const Text("กรุณาเปิด Location Service (GPS) เพื่อค้นหาทีม"),
        actions: [
          TextButton(
            onPressed:  () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style:  ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("เปิด GPS"),
          ),
        ],
      ),
    );
  }

  // Helper function แสดงความแรงสัญญาณ
  String _getSignalStrength(int?  rssi) {
    if (rssi == null) return "Signal: Unknown";
    if (rssi >= -50) return "Signal: Excellent";
    if (rssi >= -60) return "Signal: Strong";
    if (rssi >= -70) return "Signal: Good";
    return "Signal:  Weak";
  }

  Color _getSignalColor(int?  rssi) {
    if (rssi == null) return Colors.grey;
    if (rssi >= -50) return Colors.green;
    if (rssi >= -60) return Colors.lightGreen;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        leading: IconButton(
          icon:  const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // หยุด Discovery ก่อนออก
            context.read<P2PBloc>().add(StopDiscoveryEvent());
            context.pop();
          },
        ),
        title: const Text(
          "Scanning for Team",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // ปุ่ม Refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<P2PBloc>().add(StartDiscoveryEvent(_userName));
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ----------------- 1. Radar Animation -----------------
          RotationTransition(
            turns: _controller,
            child:  Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  center: Alignment.center,
                  startAngle: 0.0,
                  endAngle: 6.28,
                  colors: [
                    Colors.green.withOpacity(0.0),
                    Colors.green. withOpacity(0.2),
                    Colors.green. withOpacity(0.5),
                  ],
                  stops: const [0.5, 0.8, 1.0],
                ),
              ),
            ),
          ),
          // เส้นวงกลมตกแต่ง
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green. withOpacity(0.7),
                width: 1,
              ),
            ),
          ),

          // ไอคอนเราตรงกลาง
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black, size: 30),
          ),

          // ----------------- 2. Host List (ผลลัพธ์) -----------------
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: BlocConsumer<P2PBloc, P2PState>(
              listener: (context, state) {
                // แสดง Dialog ตาม Error
                if (state is P2PError) {
                  if (state.message.contains("GPS") ||
                      state.message.contains("Location Service")) {
                    _showGpsDialog();
                  } else if (state.message.contains("ถาวร") ||
                      state.message.contains("การตั้งค่า")) {
                    _showSettingsDialog(state.message);
                  }
                }
              },
              builder: (context, state) {
                // แสดง Loading
                if (state is P2PLoading) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:  Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          "กำลังค้นหาทีม...",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }

                // แสดง Error
                if (state is P2PError) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: const TextStyle(color:  Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:  MainAxisAlignment.center,
                          children: [
                            // ปุ่มไปตั้งค่า
                            if (state. message.contains("ถาวร") ||
                                state. message.contains("การตั้งค่า"))
                              ElevatedButton. icon(
                                onPressed:  () => openAppSettings(),
                                icon:  const Icon(Icons.settings, size: 18),
                                label: const Text("ตั้งค่า"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            // ปุ่มเปิด GPS
                            if (state.message.contains("GPS") ||
                                state.message. contains("Location Service"))
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Geolocator.openLocationSettings(),
                                icon: const Icon(Icons.location_on, size: 18),
                                label: const Text("เปิด GPS"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            const SizedBox(width: 8),
                            // ปุ่มลองใหม่
                            OutlinedButton.icon(
                              onPressed: () {
                                context
                                    .read<P2PBloc>()
                                    .add(StartDiscoveryEvent(_userName));
                              },
                              icon: const Icon(Icons.refresh,
                                  size: 18, color: Colors.white),
                              label: const Text("ลองใหม่",
                                  style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color:  Colors.white54),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                // แสดงรายชื่อ Host ที่เจอ
                if (state is P2PUpdated && state.peers.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Found Teams",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:  Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${state.peers.length} found",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight:  FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // ลิสต์รายชื่อ (เอาแค่ 3 คนแรก)
                        ... state.peers.take(3).map(
                              (peer) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius:  BorderRadius.circular(12),
                                ),
                                child:  ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green[100],
                                    child:  const Icon(
                                      Icons.hub,
                                      color: Colors.green,
                                    ),
                                  ),
                                  title: Text(
                                    peer.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    _getSignalStrength(peer. rssi),
                                    style: TextStyle(
                                      color:  _getSignalColor(peer. rssi),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      // ส่งคำสั่ง Connect
                                      context.read<P2PBloc>().add(
                                            ConnectToPeerEvent(peer.id),
                                          );

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "กำลังเชื่อมต่อกับ ${peer.name}.. .",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                    ),
                                    child: const Text("Join"),
                                  ),
                                ),
                              ),
                            ),
                        // แสดงจำนวนที่เหลือถ้ามีมากกว่า 3
                        if (state.peers. length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Center(
                              child: Text(
                                "+${state.peers.length - 3} more teams",
                                style: TextStyle(
                                  color:  Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // ยังไม่เจอใคร (Searching)
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize:  MainAxisSize.min,
                    children: [
                      const Text(
                        "Searching.. .",
                        style: TextStyle(
                          color: Colors. white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "ให้ Host เปิดหน้า Team Lobby ไว้\nแล้วอยู่ใกล้กัน",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}