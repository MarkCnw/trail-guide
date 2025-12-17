import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:geolocator/geolocator.dart'; // 📡 GPS
import 'package:go_router/go_router.dart';
import 'package:torch_light/torch_light.dart'; // 🔦 ไฟฉาย
import 'package:trail_guide/features/p2p/presentation/widgets/action_card.dart';
import 'package:trail_guide/features/p2p/presentation/widgets/hike_history_card.dart';

import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  // 🔦 Flashlight State
  bool _isFlashlightOn = false;
  bool _hasFlashlight = false;

  // 📡 GPS State
  int _gpsSignalBars = 0; // 0-4 ขีด
  String _gpsStatusText = "Searching...";
  Color _signalColor = Colors.grey; // สีเริ่มต้น (ไม่มีสัญญาณ)

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _checkFlashlightAvailability();
    _startGpsMonitoring();
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // ปิด GPS เมื่อออกจากหน้าเพื่อประหยัดแบต
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 🔦 FLASHLIGHT LOGIC
  // ---------------------------------------------------------------------------
  Future<void> _checkFlashlightAvailability() async {
    try {
      // ตรวจสอบเบื้องต้น (ใน Android ส่วนใหญ่มีอยู่แล้ว)
      setState(() {
        _hasFlashlight = true;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _toggleFlashlight() async {
    try {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
      });
    } on Exception catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิดไฟฉายได้ ⚠️')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📡 GPS LOGIC (Real-time & Color Changing)
  // ---------------------------------------------------------------------------
  void _startGpsMonitoring() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // ตั้งค่าให้อัปเดตถี่ๆ เพื่อให้เห็น Signal Bar ขยับ
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position? position) {
              if (position != null) {
                _updateSignalStrength(position.accuracy);
              }
            },
            onError: (e) {
              if (mounted) {
                setState(() {
                  _gpsSignalBars = 0;
                  _gpsStatusText = "No GPS";
                  _signalColor = Colors.red;
                });
              }
            },
          );
    }
  }

  // คำนวณสีและขีดสัญญาณตามความแม่นยำ (Accuracy)
  void _updateSignalStrength(double accuracyInMeters) {
    int bars;
    String status;
    Color color;

    if (accuracyInMeters <= 10) {
      bars = 4;
      status = "GPS: Strong";
      color = const Color(0xFF11D452); // 🟢 Strong (Primary Green)
    } else if (accuracyInMeters <= 25) {
      bars = 3;
      status = "GPS: Good";
      color = const Color(0xFF66BB6A); // 🍃 Good (Soft Green)
    } else if (accuracyInMeters <= 50) {
      bars = 2;
      status = "GPS: Fair";
      color = const Color(0xFFFFB300); // 🟡 Fair (Amber)
    } else {
      bars = 1;
      status = "GPS: Weak";
      color = const Color(0xFFE53935); // 🔴 Weak (Red)
    }

    if (mounted) {
      setState(() {
        _gpsSignalBars = bars;
        _gpsStatusText = status;
        _signalColor = color;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 🎨 UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),

      // === APP BAR ===
      appBar: AppBar(
        toolbarHeight: 90,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F3923), Color(0xFF1B5E3C)],
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (context, state) {
              if (state is OnboardingLoaded) {
                final user = state.profile;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white24,
                      backgroundImage: user.imagePath != null
                          ? FileImage(File(user.imagePath!))
                          : null,
                      child: user.imagePath == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'สวัสดี',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          user.nickname,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 12),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  context.push('/settings');
                },
              ),
            ),
          ),
        ],
      ),

      // === BODY ===
      body: Column(
        children: [
          // 🛠️ DASHBOARD CARD (Flashlight + GPS)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    // เส้น Accent สีเขียว (Signature TrailGuide)
                    Container(
                      width: 6,
                      height: double.infinity,
                      color: const Color(0xFF2E7D32),
                    ),

                    // 🔦 ส่วนซ้าย: Flashlight Button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _hasFlashlight ? _toggleFlashlight : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isFlashlightOn
                                    ? Icons.flashlight_on
                                    : Icons.flashlight_off,
                                color: _isFlashlightOn
                                    ? Colors.orangeAccent
                                    : Colors.grey,
                                size: 26,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isFlashlightOn
                                    ? "Flashlight: ON"
                                    : "Flashlight",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _isFlashlightOn
                                      ? Colors.black87
                                      : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // เส้นคั่นกลาง
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey.withOpacity(0.2),
                    ),

                    // 📡 ส่วนขวา: GPS Signal (Dynamic Color)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ไอคอนเปลี่ยนสีตามตัวแปร _signalColor
                              Icon(
                                Icons.satellite_alt_rounded,
                                color: _signalColor,
                                size: 26,
                              ),

                              const SizedBox(width: 8),

                              // แท่งกราฟเปลี่ยนสีตามตัวแปร _signalColor
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildSignalBar(
                                    height: 6,
                                    isActive: _gpsSignalBars >= 1,
                                    activeColor: _signalColor,
                                  ),
                                  _buildSignalBar(
                                    height: 10,
                                    isActive: _gpsSignalBars >= 2,
                                    activeColor: _signalColor,
                                  ),
                                  _buildSignalBar(
                                    height: 14,
                                    isActive: _gpsSignalBars >= 3,
                                    activeColor: _signalColor,
                                  ),
                                  _buildSignalBar(
                                    height: 18,
                                    isActive: _gpsSignalBars >= 4,
                                    activeColor: _signalColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // ข้อความเปลี่ยนสีตามตัวแปร _signalColor
                          Text(
                            _gpsStatusText,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _signalColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 17),
          // ส่วนปุ่มเมนูหลัก (Host / Join) แบบแนวนอน
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 🟢 การ์ด Host (Green Gradient)
                Expanded(
                  child: ActionGridCard(
                    title: 'Host Team',
                    subtitle: 'Create Group',
                    icon: Icons.flag, // หรือใช้ SVG
                    iconColor: Colors.white, // ไอคอนสีขาว
                    // ✨ ใส่ Gradient สีเขียว ✨
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F3923), // เขียวเข้มมาก (เขียวป่า)
                        Color(0xFF1B5E3C), // เขียวเข้มอมสด
                      ],
                    ),
                    onTap: () => context.push('/lobby'),
                  ),
                ),

                const SizedBox(width: 16),

                // ⚫ การ์ด Join (Dark Gradient)
                Expanded(
                  child: ActionGridCard(
                    title: 'Join Team',
                    subtitle: 'Scan Code',
                    icon: Icons.qr_code_scanner,
                    iconColor: Colors.white, // ไอคอนสีขาว
                    // ✨ ใส่ Gradient สีดำเทา ✨
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF232323), // ดำเทาเข้ม
                        Color(0xFF2E2E2E), // เทาเข้ม
                      ],
                    ),
                    onTap: () => context.push('/scan'),
                  ),
                ),
              ],
            ),
          ),

          // ... (ต่อจาก Row ปุ่ม Host/Join) ...
          const SizedBox(height: 24), // เว้นระยะห่าง
          // หัวข้อ "Recent Hikes" + "View All"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Hikes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "View All",
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // รายการการ์ด (Mock Data)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                HikeHistoryCard(
                  title: "Doi Chiang Dao",
                  subtitle: "4hr 20m",
                  date: "Nov 12",
                  onTap: () {},
                ),
                HikeHistoryCard(
                  title: "Mon Jam Loop",
                  subtitle: "2hr 15m",
                  date: "Oct 28",
                  onTap: () {},
                ),
                HikeHistoryCard(
                  title: "Pha Dok Siew",
                  subtitle: "1hr 45m",
                  date: "Oct 15",
                  onTap: () {},
                ),
                // เพิ่มพื้นที่ว่างด้านล่างกันตกขอบ
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🪄 Widget สร้างแท่งสัญญาณ (Helper)
  Widget _buildSignalBar({
    required double height,
    required bool isActive,
    required Color activeColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 300,
      ), // ใส่ Animation ให้นุ่มนวล
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: isActive
            ? activeColor
            : Colors.grey[300], // ถ้าสัญญาณถึงใช้สีจริง ถ้าไม่ถึงใช้สีเทา
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
