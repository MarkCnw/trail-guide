import 'package:flutter/material.dart';


class RadarPage extends StatelessWidget {
  const RadarPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. "ฉีด" Bloc เข้าสู่ Widget Tree
    return  Scaffold(
      appBar: AppBar(title: const Text("Radar Log")),
      body: const Center(child: Text("เรด้าUI (Coming Soon)")),
    );
  }
}