import 'package:equatable/equatable.dart';

class PeerEntity extends Equatable {
  final String id;
  final String name;
  final int rssi;
  final bool isLost;
  final String? imageBase64;
  final bool isHost;

  const PeerEntity({
    required this.id,
    required this.name,
    this.rssi = 0,
    this.isLost = false,
    this.imageBase64,
    this.isHost = false,
  });

  PeerEntity copyWith({
    String? id,
    String? name,
    int? rssi,
    bool? isLost,
    String? imageBase64,
    bool? isHost,
  }) {
    return PeerEntity(
      id: id ??  this.id,
      name: name ?? this.name,
      rssi: rssi ?? this. rssi,
      isLost: isLost ?? this.isLost,
      imageBase64: imageBase64 ?? this. imageBase64,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  List<Object?> get props => [id, name, rssi, isLost, imageBase64, isHost];

  @override
  String toString() {
    return 'PeerEntity(id: $id, name: $name, isHost: $isHost)';
  }
}