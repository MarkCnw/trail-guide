import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import ไฟล์ที่เราสร้างไว้ (เช็ค Path ให้ถูกนะ)
import 'features/tracking/data/datasources/location_data_source.dart';
import 'features/tracking/data/repositories/location_repository_impl.dart';
import 'features/tracking/presentation/provider/location_provider.dart';
import 'features/tracking/presentation/pages/tracking_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. สร้าง DataSource (ตัวดึง GPS)
    final dataSource = LocationDataSourceImpl();

    // 2. สร้าง Repository (ตัวจัดการข้อมูล) โดยยัด DataSource เข้าไป
    final repository = LocationRepositoryImpl(dataSource: dataSource);

    return MultiProvider(
      providers: [
        // 3. สร้าง Provider (ตัวคุม State) โดยยัด Repository เข้าไป
        ChangeNotifierProvider(
          create: (_) => LocationProvider(repository: repository),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TrailGuide',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
          ), // ธีมสีเขียวเดินป่า
          useMaterial3: true,
        ),
        // 4. เปิดมาให้เจอหน้า TrackingPage ของเราเลย
        home: const TrackingPage(),
      ),
    );
  }
}
