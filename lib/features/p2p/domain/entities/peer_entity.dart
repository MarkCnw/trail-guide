// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class PeerEntity extends Equatable {
  final String id;          // Device ID หรือ Mac Address
  final String name;        // ชื่อเพื่อน
  final int rssi;           // ความแรงสัญญาณ (ใช้คำนวณระยะห่างคร่าวๆ)
  final bool isLost;        // สถานะ: หลุดระยะหรือไม่?

  
  const PeerEntity({
    required this.id,
    required this.name,
    required this.rssi,
    required this.isLost,
  });



  // ใช้ Equatable เพื่อให้เปรียบเทียบ Object ได้ง่าย (ตรวจสอบว่าเพื่อนคนเดิมหรือไม่)
  @override
  List<Object?> get props => [id, name, rssi, isLost];
}
