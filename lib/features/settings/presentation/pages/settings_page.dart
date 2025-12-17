import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // สำหรับ context.pop()

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State จำลอง (เอาไว้เก็บค่าเปิด/ปิด)
  bool _isDarkMode = false;
  bool _keepScreenOn = true;
  int _unitSystemIndex = 0; // 0 = Metric, 1 = Imperial
  double _sensitivity = 50; // 0-100

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6), // สีพื้นหลังเทาอ่อน
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(), // ย้อนกลับ
        ),
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ----------------- DISPLAY SECTION -----------------
          _buildSectionHeader("DISPLAY"),
          _buildCardContainer(
            children: [
              _buildSwitchRow(
                icon: Icons.dark_mode_rounded,
                iconColor: Colors.indigo,
                title: "Dark Mode",
                value: _isDarkMode,
                onChanged: (val) => setState(() => _isDarkMode = val),
              ),
              const Divider(height: 1, indent: 60), // เส้นคั่น
              _buildSwitchRow(
                icon: Icons.smartphone_rounded,
                iconColor: Colors.blue,
                title: "Keep Screen On",
                value: _keepScreenOn,
                onChanged: (val) => setState(() => _keepScreenOn = val),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ----------------- PREFERENCES SECTION -----------------
          _buildSectionHeader("PREFERENCES",),
          _buildCardContainer(
            children: [
              // 1. Unit System
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildIconBox(Icons.straighten_rounded, Colors.blue),
                        const SizedBox(width: 16),
                        const Text(
                          "Unit System",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Custom Segmented Control (ปุ่มเลือก Metric/Imperial)
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _buildSegmentButton("Metric", 0),
                          _buildSegmentButton("Imperial", 1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1, indent: 20, endIndent: 20),

              // 2. Alert Sensitivity
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildIconBox(Icons.notifications_active_rounded, Colors.blue),
                        const SizedBox(width: 16),
                        const Text(
                          "Alert Sensitivity",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        // Badge "Medium"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getSensitivityLabel(),
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.blue[600],
                        inactiveTrackColor: Colors.grey[200],
                        thumbColor: Colors.blue[600],
                        trackHeight: 4,
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      ),
                      child: Slider(
                        value: _sensitivity,
                        min: 0,
                        max: 100,
                        onChanged: (val) => setState(() => _sensitivity = val),
                      ),
                    ),
                    // Labels Low - High
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Low", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          Text("High", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          
          // Version Text
          Center(
            child: Text(
              "TrailGuide v1.0.2",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPER WIDGETS ----------------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildIconBox(icon, iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue[600],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ปุ่มเลือก Metric / Imperial
  Widget _buildSegmentButton(String text, int index) {
    final isSelected = _unitSystemIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _unitSystemIndex = index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.blue[700] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  String _getSensitivityLabel() {
    if (_sensitivity < 30) return "Low";
    if (_sensitivity > 70) return "High";
    return "Medium";
  }
}