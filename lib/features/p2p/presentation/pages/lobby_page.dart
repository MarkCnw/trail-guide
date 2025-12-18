
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';
import '../bloc/p2p_bloc.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  String _hostData = "TrailGuide-Host";

  @override
  void initState() {
    super.initState();

    // ดึงชื่อ User จาก OnboardingCubit
    final onboardingState = context.read<OnboardingCubit>().state;
    if (onboardingState is OnboardingLoaded) {
      _hostData = onboardingState.profile.nickname ?? "TrailGuide-Host";
    }

    // เริ่มปล่อยสัญญาณ (Advertising) ทันทีที่เข้าหน้านี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<P2PBloc>().add(StartAdvertisingEvent(_hostData));
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // แสดง Dialog ไปตั้งค่าแอป
  void _showSettingsDialog(String message) {
    showDialog(
      context: context,
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
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
        content: const Text("กรุณาเปิด Location Service (GPS) เพื่อใช้งานฟีเจอร์นี้"),
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
              foregroundColor: Colors. white,
            ),
            child: const Text("เปิด GPS"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon:  const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () {
            // หยุด Advertising ก่อนออก
            context.read<P2PBloc>().add(StopAdvertisingEvent());
            context.pop();
          },
        ),
        title: const Text(
          "Team Lobby",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // ----------------- 1. ส่วน QR Code -----------------
          Text(
            "Scan to Join",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 16),

          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow:  [
                  BoxShadow(
                    color: Colors. black.withOpacity(0.05),
                    blurRadius:  20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: QrImageView(
                data: _hostData,
                version: QrVersions.auto,
                size: 200.0,
                foregroundColor: const Color(0xFF2E7D32),
              ),
            ),
          ),

          const SizedBox(height:  16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child:  Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                const SizedBox(width:  8),
                Text(
                  _hostData,
                  style:  const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ----------------- 2. ส่วนรายชื่อเพื่อน (Member List) -----------------
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color:  Color(0xFFF6F8F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight:  Radius.circular(32),
                ),
              ),
              child:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Teammates",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Badge บอกจำนวนคน
                        BlocBuilder<P2PBloc, P2PState>(
                          builder: (context, state) {
                            int count = 0;
                            if (state is P2PUpdated) count = state.peers.length;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green. withOpacity(0.1),
                                borderRadius: BorderRadius. circular(12),
                              ),
                              child: Text(
                                "$count Joined",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // List รายชื่อเพื่อน
                  Expanded(
                    child: BlocConsumer<P2PBloc, P2PState>(
                      listener: (context, state) {
                        // แสดง Dialog ตาม Error
                        if (state is P2PError) {
                          if (state.message. contains("GPS") ||
                              state.message.contains("Location Service")) {
                            _showGpsDialog();
                          } else if (state.message.contains("ถาวร") ||
                              state.message. contains("การตั้งค่า")) {
                            _showSettingsDialog(state.message);
                          }
                        }
                      },
                      builder: (context, state) {
                        // แสดง Loading
                        if (state is P2PLoading) {
                          return Center(
                            child: Column(
                              mainAxisAlignment:  MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "กำลังเปิดรับสมาชิก...",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        // แสดง Error
                        if (state is P2PError) {
                          return Center(
                            child:  Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48, color: Colors.red[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.message,
                                    style: TextStyle(color: Colors.red[400]),
                                    textAlign:  TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  // ปุ่มไปตั้งค่า
                                  if (state.message.contains("ถาวร") ||
                                      state. message.contains("การตั้งค่า"))
                                    ElevatedButton.icon(
                                      onPressed: () => openAppSettings(),
                                      icon: const Icon(Icons.settings),
                                      label: const Text("ไปตั้งค่าแอป"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:  Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  // ปุ่มเปิด GPS
                                  if (state.message.contains("GPS") ||
                                      state. message.contains("Location Service"))
                                    ElevatedButton. icon(
                                      onPressed: () =>
                                          Geolocator.openLocationSettings(),
                                      icon: const Icon(Icons.location_on),
                                      label: const Text("เปิด GPS"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:  Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  // ปุ่มลองใหม่
                                  TextButton. icon(
                                    onPressed: () {
                                      context.read<P2PBloc>().add(
                                          StartAdvertisingEvent(_hostData));
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("ลองใหม่"),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // แสดงรายชื่อเพื่อน
                        if (state is P2PUpdated && state.peers.isNotEmpty) {
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.peers.length,
                            itemBuilder: (context, index) {
                              final peer = state.peers[index];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[50],
                                    child: Text(
                                      peer.name.isNotEmpty
                                          ? peer.name[0]. toUpperCase()
                                          : "? ",
                                      style: TextStyle(color: Colors.blue[700]),
                                    ),
                                  ),
                                  title: Text(
                                    peer.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Connected",
                                    style: TextStyle(
                                        color: Colors.green[600], fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.check_circle,
                                      color: Colors. green),
                                ),
                              );
                            },
                          );
                        }

                        // กรณีไม่มีเพื่อน (Waiting)
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1_rounded,
                                  size: 48, color:  Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text(
                                "Waiting for members...",
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "ให้เพื่อนกด Join Team แล้วสแกนหาทีมของคุณ",
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
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
            ),
          ),
        ],
      ),

      // ----------------- 3. ปุ่ม Start Trek -----------------
      bottomNavigationBar: Container(
        color: const Color(0xFFF6F8F6),
        padding: const EdgeInsets. all(20),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              context.push('/tracking');
            },
            style:  ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor:  Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius:  BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child:  const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Start Adventure",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}