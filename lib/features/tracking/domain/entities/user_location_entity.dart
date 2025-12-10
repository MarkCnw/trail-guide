class UserLocationEntity {
  
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const UserLocationEntity({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  String toString() =>
      'UserLocationEntity(latitude: $latitude, longtitude: $longitude, timestamp: $timestamp)';
}
