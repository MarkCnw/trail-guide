import 'package:flutter/material.dart';

class HikeHistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final VoidCallback onTap;

  const HikeHistoryCard({
    super.key,
    required this.title,
    required this.subtitle, // เช่น "4hr 20m"
    required this.date, // เช่น "Nov 12"
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ), // เว้นระยะห่างระหว่างการ์ด
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // โค้งมน
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // เงาจางๆ
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 1. ไอคอนปฏิทิน (สีเขียวอ่อน)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), // สีเขียวอ่อนมาก
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF2E7D32), // สีเขียวเข้ม
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                // 2. ข้อมูล (ชื่อ + เวลา)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          // จุดคั่นกลาง
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            child: Icon(
                              Icons.circle,
                              size: 4,
                              color: Colors.grey[400],
                            ),
                          ),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. ลูกศรขวา
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
