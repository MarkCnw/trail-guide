import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6), // สีพื้นหลังเทาอ่อน
      appBar: AppBar(
        title: const Text(
          "History Log",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      // ใช้ ListView เรียกฟังก์ชันสร้างการ์ดทีละใบ
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHistoryCard(
            date: "Today, Oct 24",
            title: "Afternoon Hike",
            duration: "3h 15m",
            teammates: 4,
            onTap: () {},
          ),
          _buildHistoryCard(
            date: "Yesterday, Oct 23",
            title: "Morning Patrol",
            duration: "5h 45m",
            teammates: 2,
            onTap: () {},
          ),
          _buildHistoryCard(
            date: "Oct 20, 2023",
            title: "Ridge Trail",
            duration: "2h 10m",
            teammates: 3,
            onTap: () {},
          ),
          _buildHistoryCard(
            date: "Oct 15, 2023",
            title: "Basecamp Check",
            duration: "1h 30m",
            teammates: 5,
            onTap: () {},
          ),
          _buildHistoryCard(
            date: "Oct 12, 2023",
            title: "Canyon Pass",
            duration: "6h 15m",
            teammates: 2,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ✨ สร้าง UI การ์ดตรงนี้เลย (ไม่ต้องแยก Class)
  Widget _buildHistoryCard({
    required String date,
    required String title,
    required String duration,
    required int teammates,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. วันที่ + เวลา
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),

                // 2. ชื่อทริป
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.grey[200], thickness: 1),
                const SizedBox(height: 12),

                // 3. เพื่อนร่วมทีม
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 20, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      "$teammates Teammates",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}