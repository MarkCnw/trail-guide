import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';
import '../bloc/p2p_bloc.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _userName = "TrailGuide Member";

  // 🆕 ตัวแปรสำหรับ PIN Input
  final _pinController = TextEditingController();
  bool _showPinInput = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final onboardingState = context.read<OnboardingCubit>().state;
    if (onboardingState is OnboardingLoaded) {
      _userName = onboardingState.profile.nickname ?? "TrailGuide Member";
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<P2PBloc>().add(StartDiscoveryEvent(_userName));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // 🆕 ฟังก์ชันค้นหา Host ด้วย PIN
  void _joinWithPin() {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาใส่ PIN 6 หลัก"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // หา Host ที่มี PIN ตรงกัน
    final p2pState = context.read<P2PBloc>().state;
    if (p2pState is P2PUpdated) {
      final matchingPeer = p2pState.peers.firstWhere(
        (peer) => peer.name.contains("#$pin"),
        orElse: () => throw Exception("Not found"),
      );

      // พบ Host! ส่งคำสั่ง Connect
      context.read<P2PBloc>().add(ConnectToPeerEvent(matchingPeer.id));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("กำลังเชื่อมต่อกับ ${matchingPeer.name}..."),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ไม่พบห้องที่ตรงกับ PIN นี้"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getSignalStrength(int? rssi) {
    if (rssi == null) return "Signal: Unknown";
    if (rssi >= -50) return "Signal: Excellent";
    if (rssi >= -60) return "Signal: Strong";
    if (rssi >= -70) return "Signal: Good";
    return "Signal: Weak";
  }

  Color _getSignalColor(int? rssi) {
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
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
          // 🆕 ปุ่มสลับโหมด PIN
          IconButton(
            icon: Icon(
              _showPinInput ? Icons.radar : Icons.pin,
              color: Colors.white,
            ),
            onPressed: () =>
                setState(() => _showPinInput = !_showPinInput),
            tooltip: _showPinInput ? "Scan Mode" : "PIN Mode",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showPinInput ? _buildPinInputMode() : _buildRadarMode(),
      ),
    );
  }

  // 🆕 โหมดพิมพ์ PIN
  Widget _buildPinInputMode() {
    return Center(
      key: const ValueKey("pin_input"),
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pin, size: 60, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              "Enter Room PIN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "ใส่ PIN 6 หลักที่ได้จาก Host",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 24),

            // ช่องพิมพ์ PIN
            TextField(
              controller: _pinController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                hintText: "000000",
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),

            const SizedBox(height: 24),

            // ปุ่ม Join
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _joinWithPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Join Room",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // โหมด Radar (เดิม)
  Widget _buildRadarMode() {
    return Stack(
      key: const ValueKey("radar"),
      alignment: Alignment.center,
      children: [
        // Radar Animation
        RotationTransition(
          turns: _controller,
          child: Container(
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
                  Colors.green.withOpacity(0.2),
                  Colors.green.withOpacity(0.5),
                ],
                stops: const [0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),
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
              color: Colors.green.withOpacity(0.7),
              width: 1,
            ),
          ),
        ),
        const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Colors.black, size: 30),
        ),

        // Host List
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: BlocBuilder<P2PBloc, P2PState>(
            builder: (context, state) {
              if (state is P2PLoading) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
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
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

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
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${state.peers.length} found",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...state.peers
                          .take(3)
                          .map(
                            (peer) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: const Icon(
                                    Icons.hub,
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(
                                  peer.name.split('#')[0], // ซ่อน PIN
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  _getSignalStrength(peer.rssi),
                                  style: TextStyle(
                                    color: _getSignalColor(peer.rssi),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    context.read<P2PBloc>().add(
                                      ConnectToPeerEvent(peer.id),
                                    );
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "กำลังเชื่อมต่อกับ ${peer.name}...",
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
                                      horizontal: 20,
                                    ),
                                  ),
                                  child: const Text("Join"),
                                ),
                              ),
                            ),
                          ),
                      if (state.peers.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: Text(
                              "+${state.peers.length - 3} more teams",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Searching...",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "หรือกดปุ่ม PIN ด้านบนเพื่อใส่รหัสห้อง",
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
    );
  }
}
