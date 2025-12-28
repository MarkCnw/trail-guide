import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RoomListShimmer extends StatelessWidget {
  const RoomListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6, // จำนวนรายการจำลอง
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // 1. 📦 ตัวกล่องพื้นหลัง (Static Background)
        // ใช้สีขาว (White) เป็นพื้นหลังนิ่งๆ เพื่อให้เข้ากับ Light Theme
        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white, // ✅ พื้นหลังสีขาว
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2), // ขอบสีเทาจางๆ
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // เงาจางๆ
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          // 2. ✨ เอฟเฟกต์ Shimmer (เฉพาะเนื้อหาข้างใน)
          // ปรับสีให้เป็นโทน เทา-ขาว (Standard Light Mode Loading)
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!, // สีเทา (ตอนยังไม่วิบวับ)
            highlightColor: Colors.grey[100]!, // สีขาว (ตอนวิบวับ)
            
            child: Row(
              children: [
                // --- Avatar (ซ้าย) ---
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white, // ต้องใส่สีเพื่อให้ Shimmer จับภาพ
                    shape: BoxShape.circle, // เปลี่ยนเป็นวงกลมให้เหมือน Avatar จริง
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // --- Text Info (กลาง) ---
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // จำลองคำว่า "Team"
                      Container(
                        width: 40,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // จำลองชื่อ Host
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // --- Join Button (ขวา) ---
                Container(
                  width: 70,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}