import 'dart:math' as math;

class LocationCalculator {
  // รัศมีของโลก (หน่วยเป็นเมตร)
  static const double earthRadius = 6371000;

  // 1. ตัวช่วยแปลงองศาเป็นเรเดียน
  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  // 2. ตัวช่วยแปลงเรเดียนเป็นองศา
  static double _toDegrees(double radian) {
    return radian * 180 / math.pi;
  }

  /// 📍 คำนวณระยะทาง (Distance) ออกมาเป็น "เมตร"
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLat)) *
            math.cos(_toRadians(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// 🧭 คำนวณทิศทาง (Bearing) ออกมาเป็น "องศา (0-360)" เทียบกับทิศเหนือ
  static double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final startLatRad = _toRadians(startLat);
    final startLngRad = _toRadians(startLng);
    final endLatRad = _toRadians(endLat);
    final endLngRad = _toRadians(endLng);

    final dLng = endLngRad - startLngRad;

    final y = math.sin(dLng) * math.cos(endLatRad);
    final x = math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

    final bearingRad = math.atan2(y, x);
    // แปลงกลับเป็นองศา และทำให้ค่าอยู่ในช่วง 0 ถึง 360
    return (_toDegrees(bearingRad) + 360) % 360;
  }
}