import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/p2p_bloc.dart';

class RadarPage extends StatelessWidget {
  const RadarPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. "ฉีด" Bloc เข้าสู่ Widget Tree
    return BlocProvider(
      create: (_) => sl<P2PBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('TrailGuide Radar')),
        // 2. ส่วนแสดงผล
        body: BlocBuilder<P2PBloc, P2PState>(
          builder: (context, state) {
            if (state is P2PLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is P2PError) {
              return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
            } else if (state is P2PUpdated) {
              if (state.peers.isEmpty) {
                return const Center(child: Text('ยังไม่เจอเพื่อน... กด Scan เลย!'));
              }
              // แสดงรายชื่อเพื่อน
              return ListView.builder(
                itemCount: state.peers.length,
                itemBuilder: (context, index) {
                  final peer = state.peers[index];
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      color: peer.isLost ? Colors.red : Colors.green,
                    ),
                    title: Text(peer.name),
                    subtitle: Text('ID: ${peer.id.substring(0, 5)}...'),
                  );
                },
              );
            }
            return const Center(child: Text('พร้อมใช้งาน'));
          },
        ),
        // 3. ปุ่มกด
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                // เรียกใช้ Bloc เพื่อส่ง Event
                context.read<P2PBloc>().add(StartDiscoveryEvent());
              },
              child: const Icon(Icons.radar),
            );
          },
        ),
      ),
    );
  }
}