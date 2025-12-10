import 'package:trail_guide/features/tracking/domain/entities/user_location_entity.dart';

import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource dataSource;

  LocationRepositoryImpl({required this.dataSource});

  @override
  Stream<UserLocationEntity> getLocationStream() {
    // รับค่าจาก DataSource แล้วส่งต่อให้ Domain
    // สังเกตว่า Model จะถูกมองว่าเป็น Entity ได้เลยเพราะมัน extends กันมา
    return dataSource.getLocationStream();
  }

  @override
  Future<UserLocationEntity> getCurrentLocation() async {
     // (ถ้าจะทำเพิ่ม) เดี๋ยวค่อยมาเติมครับ เอา Stream ให้รอดก่อน
     throw UnimplementedError();
  }
}