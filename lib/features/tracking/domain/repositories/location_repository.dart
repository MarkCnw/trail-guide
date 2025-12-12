
import '../entities/user_location_entity.dart'; // import ให้ถูกตัว

abstract class LocationRepository {
  Stream<UserLocationEntity> getLocationStream();

  Future<UserLocationEntity> getCurrentLocation();
}