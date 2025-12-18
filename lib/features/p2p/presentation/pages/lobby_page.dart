import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart'; // 👈 อย่าลืม import
import '../bloc/p2p_bloc.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  // สมมติว่าชื่อ Host คือ User ID หรือชื่อเครื่อง
  final String hostData = "TrailGuide-Host-001"; 

  @override
  void initState() {
    super.initState();
    // 🚀 เริ่มปล่อยสัญญาณ (Advertising) ทันทีที่เข้าหน้านี้
    // หมายเหตุ: คุณต้องไปเพิ่ม Event 'StartAdvertisingEvent' ใน Bloc ก่อนนะ
    // context.read<P2PBloc>().add(StartAdvertisingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () {
            // TODO: หยุด Advertising ก่อนออก
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              // ✨ สร้าง QR Code จากข้อมูล Host
              child: QrImageView(
                data: hostData,
                version: QrVersions.auto,
                size: 200.0,
                foregroundColor: const Color(0xFF2E7D32), // สีเขียวธีมป่า
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  hostData,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                color: Color(0xFFF6F8F6), // พื้นหลังเทาอ่อนโซนลิสต์
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
                        // Badge บอกจำนวนคน
                        BlocBuilder<P2PBloc, P2PState>(
                          builder: (context, state) {
                            int count = 0;
                            if (state is P2PUpdated) count = state.peers.length;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  
                  // List รายชื่อเพื่อน
                  Expanded(
                    child: BlocBuilder<P2PBloc, P2PState>(
                      builder: (context, state) {
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
                                      peer.name[0].toUpperCase(),
                                      style: TextStyle(color: Colors.blue[700]),
                                    ),
                                  ),
                                  title: Text(
                                    peer.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Connected",
                                    style: TextStyle(color: Colors.green[600], fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                                ),
                              );
                            },
                          );
                        }
                        
                        // กรณีไม่มีเพื่อน
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1_rounded, size: 48, color: Colors.grey[300]),
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
            onPressed: () {
              // TODO: ส่งข้อมูล map ไปให้ลูกทีม แล้วเริ่มเดินทาง
              context.push('/tracking'); 
            },
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