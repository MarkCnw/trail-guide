


// สืบทอดจาก UserLocation (Domain) เพื่อให้ส่งข้อมูลข้าม Layer ได้
import 'package:geolocator/geolocator.dart';
import 'package:trail_guide/features/tracking/domain/entities/user_location_entity.dart';

class UserLocationModel extends UserLocationEntity {
  const UserLocationModel({
    required super.latitude,
    required super.longitude,
    required super.timestamp,
  });

  // Factory: สร้าง Model จาก Object "Position" ของ Geolocator
  factory UserLocationModel.fromPosition(Position position) {
    return UserLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );
  }
}