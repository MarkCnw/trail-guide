import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trail_guide/features/tracking/presentation/provider/location_provider.dart';


class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  @override
  void initState() {
    super.initState();
    // สั่งให้ Provider เริ่มทำงานทันทีที่เปิดหน้านี้
    // ใช้ addPostFrameCallback เพื่อความชัวร์ว่า Build เสร็จแล้ว
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TrailGuide Tracker")),
      body: Center(
        // Consumer จะคอยฟังการเปลี่ยนแปลงจาก Provider
        child: Consumer<LocationProvider>(
          builder: (context, provider, child) {
            final location = provider.currentLocation;

            if (location == null) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("กำลังค้นหาสัญญาณ GPS..."),
                ],
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  "LAT: ${location.latitude.toStringAsFixed(6)}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "LNG: ${location.longitude.toStringAsFixed(6)}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Time: ${location.timestamp.hour}:${location.timestamp.minute}:${location.timestamp.second}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}