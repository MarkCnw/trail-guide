import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;


import 'package:flutter/material.dart';

/// Helper class สำหรับจัดการรูปภาพ
class ImageHelper {
  /// ขนาดรูปที่ต้องการ (150x150 px)
  static const int targetSize = 150;

  /// อ่านรูปจาก path แล้ว compress และแปลงเป็น Base64
  /// Return null ถ้าไม่มีรูปหรือเกิด error
  static Future<String?> compressAndEncode(String?  imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    try {
      final file = File(imagePath);
      if (! await file.exists()) {
        return null;
      }

      // อ่านไฟล์
      final bytes = await file.readAsBytes();

      // Decode รูป และ resize
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetSize,
        targetHeight: targetSize,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // แปลงเป็น bytes (PNG)
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      final compressedBytes = byteData. buffer.asUint8List();

      // แปลงเป็น Base64
      final base64String = base64Encode(compressedBytes);

      debugPrint('ImageHelper: Compressed image size: ${(base64String.length / 1024).toStringAsFixed(2)} KB');

      return base64String;
    } catch (e) {
      debugPrint('ImageHelper: Error compressing image: $e');
      return null;
    }
  }

  /// แปลง Base64 กลับเป็น Uint8List (สำหรับแสดงรูป)
  static Uint8List?  decodeBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }

    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('ImageHelper: Error decoding base64: $e');
      return null;
    }
  }
}