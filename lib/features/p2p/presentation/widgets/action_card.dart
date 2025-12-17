import 'package:flutter/material.dart';

class ActionGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor; // เปลี่ยนชื่อให้ชัดว่าคือสีไอคอน
  final VoidCallback onTap;
  final Gradient? gradient; // 👈 1. เพิ่มตัวแปร Gradient
  final Color? backgroundColor;
  final Color textColor; // 👈 2. เพิ่มตัวแปรสีตัวหนังสือ (เพื่อให้ปรับเป็นขาวได้)

  const ActionGridCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.gradient, // รับค่า Gradient
    this.backgroundColor,
    this.textColor = Colors.white, // ค่าเริ่มต้นเป็นสีขาว (เหมาะกับปุ่มเข้ม)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180, // ปรับความสูงตามความเหมาะสม
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white, // ถ้าไม่มี Gradient ใช้สีพื้นนี้
        gradient: gradient, // 👈 3. ใส่ Gradient ตรงนี้
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15), // เพิ่มเงาให้เข้มขึ้นนิดนึง
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Circle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // 👈 พื้นหลังไอคอนจางๆ สีขาว (ดูดีบน Gradient)
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 40),
                ),

                const SizedBox(height: 16), // เว้นระยะ

                // Text Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor, // 👈 ใช้สีตัวหนังสือที่กำหนด
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Text Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.8), // 👈 สีจางลงนิดนึง
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}