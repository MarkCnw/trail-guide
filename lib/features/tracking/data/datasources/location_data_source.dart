import 'package:geolocator/geolocator.dart';
import '../models/user_location_model.dart';

abstract class LocationDataSource {
  Stream<UserLocationModel> getLocationStream();
}

class LocationDataSourceImpl implements LocationDataSource {
  @override
  Stream<UserLocationModel> getLocationStream() {
    // กำหนดความแม่นยำ (High เหมาะกับเดินป่า)
    // distanceFilter: 5 หมายถึง ถ้าเดินไม่ถึง 5 เมตร ไม่ต้องส่งค่ามา (ประหยัดแบต)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).map((Position position) => UserLocationModel.fromPosition(position));
  }
}
