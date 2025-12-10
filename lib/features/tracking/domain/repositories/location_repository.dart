// lib/features/tracking/domain/repositories/location_repository.dart

import '../entities/user_location_entity.dart'; // import ให้ถูกตัว

abstract class LocationRepository {
  // 1. แก้ชื่อจาก getLocation เป็น getLocationStream (ให้ตรงกับ Impl)
  // 2. แก้ type return เป็น UserLocationEntity (ให้ตรงกับ Impl)
  Stream<UserLocationEntity> getLocationStream();

  Future<UserLocationEntity> getCurrentLocation();
}