import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trail_guide/features/tracking/domain/entities/user_location_entity.dart';
import 'package:trail_guide/features/tracking/domain/repositories/location_repository.dart';

class LocationProvider extends ChangeNotifier {
  final LocationRepository repository;

  // เก็บตำแหน่งปัจจุบัน (อาจจะเป็น null ได้ถ้ายังหาไม่เจอ)
  UserLocationEntity? _currentLocation;
  StreamSubscription? _locationSubscription;

  LocationProvider({required this.repository});

  // Getter ให้ UI ดึงค่าไปใช้
  UserLocationEntity? get currentLocation => _currentLocation;

  void startTracking() {
    // ยกเลิกอันเก่าก่อน (ถ้ามี) กัน stream ซ้อนกัน
    _locationSubscription?.cancel();

    // เริ่มฟัง Stream จาก Repository
    _locationSubscription = repository.getLocationStream().listen(
      (location) {
        _currentLocation = location;
        notifyListeners(); // 🔔 กริ๊งๆ! บอก UI ว่า "ค่าเปลี่ยนแล้วนะ รีวาดหน้าจอเดี๋ยวนี้"
      },
      onError: (error) {
        // จัดการ Error ตรงนี้ (เช่น ปริ้น Log หรือแจ้งเตือน)
        print("Error getting location: $error");
      },
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel(); // อย่าลืมปิดก๊อกน้ำเมื่อเลิกใช้
    super.dispose();
  }
}
