import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_guide/features/p2p/presentation/bloc/p2p_bloc.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 1. เริ่ม Animation เรดาร์หมุนติ้วๆ
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // หมุนครบรอบใน 4 วิ
    )..repeat();

    // 2. 🚀 สั่ง Bloc ให้เริ่มค้นหา (Start Discovery) ทันทีที่เข้าหน้า
    context.read<P2PBloc>().add(StartDiscoveryEvent());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // พื้นหลังสีมืดๆ ดู Pro
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // TODO: สั่ง Stop Discovery ก่อนออก (ถ้าต้องการ)
            context.pop();
          },
        ),
        title: const Text(
          "Scanning for Team",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ----------------- 1. Radar Animation -----------------
          // วงกลมเรดาร์
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
          // เส้นวงกลมเฉยๆ ตกแต่ง
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
            child: BlocBuilder<P2PBloc, P2PState>(
              builder: (context, state) {
                if (state is P2PUpdated && state.peers.isNotEmpty) {
                  // ถ้าเจอ Host โชว์เป็น Card ให้กด Connect
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
                        const Text(
                          "Found Teams",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ลิสต์รายชื่อ (เอาแค่ 3 คนแรกพอ พื้นที่มีจำกัด)
                        ...state.peers
                            .take(3)
                            .map(
                              (peer) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: const Icon(
                                    Icons.hub,
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(peer.name), // ชื่อ Host
                                subtitle: const Text(
                                  "Signal: Strong",
                                ), // RSSI
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    // ✅ ส่งคำสั่ง Connect ไปที่ Bloc
                                    context.read<P2PBloc>().add(
                                      ConnectToPeerEvent(peer.id),
                                    );

                                    // (Optional) โชว์ Loading เล็กๆ หรือ Feedback ให้รู้ว่ากดแล้ว
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Connecting to ${peer.name}...",
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text("Join"),
                                ),
                              ),
                            ),
                      ],
                    ),
                  );
                }

                // ถ้ายังไม่เจอใคร
                return const Center(
                  child: Text(
                    "Searching...",
                    style: TextStyle(color: Colors.white54),
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
