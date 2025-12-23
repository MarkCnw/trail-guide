import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  String _roomPin = ""; // 🆕 PIN Code 6 หลัก
  bool _showPin = true; // สลับโหมดแสดง QR หรือ PIN

  @override
  void initState() {
    super.initState();

    // สร้าง PIN Code 6 หลัก
    _roomPin = _generatePin();

    // ดึงชื่อ User
    final onboardingState = context.read<OnboardingCubit>().state;
    if (onboardingState is OnboardingLoaded) {
      _hostData = "${onboardingState.profile.nickname}#$_roomPin";
    } else {
      _hostData = "TrailGuide-Host#$_roomPin";
    }

    // เริ่ม Advertising
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<P2PBloc>().add(StartAdvertisingEvent(_hostData));
    });
  }

  // 🆕 สร้าง PIN 6 หลัก
  String _generatePin() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  // 🆕 Copy PIN
  void _copyPin() {
    Clipboard.setData(ClipboardData(text: _roomPin));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📋 PIN copied!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () {
            context.read<P2PBloc>().add(StopAdvertisingEvent());
            context.pop();
          },
        ),
        title: const Text(
          "Team Lobby",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 🆕 ปุ่มสลับโหมด QR/PIN
          IconButton(
            icon: Icon(_showPin ? Icons.qr_code_2 : Icons.pin),
            onPressed: () => setState(() => _showPin = !_showPin),
            tooltip: _showPin ? "Show QR Code" : "Show PIN",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // ----------------- 1. แสดง QR หรือ PIN -----------------
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showPin ? _buildPinSection() : _buildQrSection(),
          ),

          const SizedBox(height: 32),

          // ----------------- 2. รายชื่อสมาชิก -----------------
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
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
                        BlocBuilder<P2PBloc, P2PState>(
                          builder: (context, state) {
                            int count = 0;
                            if (state is P2PUpdated)
                              count = state.peers.length;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
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

                  // List สมาชิก
                  Expanded(
                    child: BlocBuilder<P2PBloc, P2PState>(
                      builder: (context, state) {
                        if (state is P2PLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          );
                        }

                        if (state is P2PError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.message,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.red[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is P2PUpdated &&
                            state.peers.isNotEmpty) {
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
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
                                          ? peer.name[0].toUpperCase()
                                          : "?",
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    peer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Connected",
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Waiting for members...",
                                style: TextStyle(color: Colors.grey[400]),
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
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => context.push('/tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Start Adventure",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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

  // 🆕 ส่วน QR Code
  Widget _buildQrSection() {
    return Column(
      key: const ValueKey("qr"),
      children: [
        Text(
          "Scan QR to Join",
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
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
      ],
    );
  }

  // 🆕 ส่วน PIN Code
  Widget _buildPinSection() {
    return Column(
      key: const ValueKey("pin"),
      children: [
        Text(
          "Room PIN Code",
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 16),

        // PIN Display
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // PIN ตัวเลขใหญ่ๆ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _roomPin.split('').map((digit) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      digit,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ปุ่ม Copy
              TextButton.icon(
                onPressed: _copyPin,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text("Copy PIN"),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // คำแนะนำ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "เพื่อนสามารถพิมพ์ PIN นี้ในหน้า Join Team",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
