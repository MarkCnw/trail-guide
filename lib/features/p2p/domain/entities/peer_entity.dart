import 'package:equatable/equatable.dart';



class PeerEntity extends Equatable {
  final String id;
  final String name;
  final int rssi;
  final bool isLost;
  final String? imageBase64;
  final bool isHost;
  final double? latitude;  // 🆕 เก็บละติจูด
  final double? longitude; // 🆕 เก็บจิจูด

  const PeerEntity({
    required this.id,
    required this.name,
    this.rssi = 0,
    this.isLost = false,
    this.imageBase64,
    this.isHost = false,
    this.latitude,
    this.longitude,
  });

  PeerEntity copyWith({
    String? id,
    String? name,
    int? rssi,
    bool? isLost,
    String? imageBase64,
    bool? isHost,
    double? latitude,
    double? longitude,
  }) {
    return PeerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      isLost: isLost ?? this.isLost,
      imageBase64: imageBase64 ?? this.imageBase64,
      isHost: isHost ?? this.isHost,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [id, name, rssi, isLost, imageBase64, isHost, latitude, longitude];
}