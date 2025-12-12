import 'package:flutter/material.dart';
import 'package:trail_guide/features/p2p/presentation/pages/radar_page.dart';
import 'injection_container.dart' as di; // ตั้งชื่อเล่นว่า di จะได้ไม่งง

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // เรียกใช้ฟังก์ชัน init ที่เราเพิ่งเขียน
  await di.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrailGuide',
      theme: ThemeData(
        primarySwatch: Colors.green,
        // ปรับธีมให้ดูเป็นแอปเดินป่าหน่อย
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: RadarPage()
      ),
    );
  }
}