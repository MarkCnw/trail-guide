import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:svg_flutter/svg.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNavBar'));

  @override
  Widget build(BuildContext context) {
    // ดึงค่า Index ปัจจุบันเพื่อเช็คว่า Tab ไหนถูกเลือกอยู่
    final int currentIndex = navigationShell.currentIndex;

    // กำหนดสีธีม (TrailGuide Theme)
    const Color activeColor = Color(0xFF2E7D32); // สีเขียว Forest Green
    const Color inactiveColor = Colors.grey;

    return Scaffold(
      // ส่วนเนื้อหาหน้าจอ (จะเปลี่ยนไปตาม Tab ที่เลือก)
      body: navigationShell,

      // ส่วนแถบเมนูด้านล่าง
      bottomNavigationBar: NavigationBarTheme(
        // ✨ เคล็ดลับ: ใช้ Theme Data ครอบเพื่อลบ Effect แสงวูบวาบ (Splash/Ripple)
        data: NavigationBarThemeData(
          indicatorColor: Colors.transparent, // ลบวงรีสีๆ พื้นหลังไอคอน
          overlayColor: WidgetStateProperty.all(Colors.transparent), // ลบแสงวูบวาบตอนกด
          
          // (Optional) กำหนดสไตล์ตัวหนังสือให้ชัดเจน
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: activeColor);
            }
            return const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: inactiveColor);
          }),
        ),
        
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (int index) {
            navigationShell.goBranch(
              index,
              // ให้กลับไปหน้าแรกของ Tab นั้นๆ ถ้ากดซ้ำ
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          
          backgroundColor: Colors.white,
          elevation: 0, // แบบแบนราบ (Flat)
          height: 65, // ความสูงกำลังดี
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

          destinations: [
            // 1. 🏠 Home Tab
            NavigationDestination(
              icon: SvgPicture.asset(
                'assets/icons/navigation/house-regular.svg',
                width: 24,
                colorFilter: ColorFilter.mode(
                  currentIndex == 0 ? activeColor : inactiveColor, BlendMode.srcIn),
              ),
              selectedIcon: SvgPicture.asset(
                'assets/icons/navigation/house-solid.svg',
                width: 24,
                colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn),
              ),
              label: 'Home',
            ),

            // 2. 📡 Radar Tab (ใช้รูปดาว Star แทนชั่วคราวตาม Asset ที่มี)
            NavigationDestination(
              icon: SvgPicture.asset(
                'assets/icons/navigation/star-regular.svg', 
                width: 24,
                colorFilter: ColorFilter.mode(
                  currentIndex == 1 ? activeColor : inactiveColor, BlendMode.srcIn),
              ),
              selectedIcon: SvgPicture.asset(
                'assets/icons/navigation/star-solid.svg',
                width: 24,
                colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn),
              ),
              label: 'Radar',
            ),

            // 3. 📜 History Tab
            NavigationDestination(
              icon: SvgPicture.asset(
                'assets/icons/navigation/pending.svg',
                width: 23,
                colorFilter: ColorFilter.mode(
                  currentIndex == 2 ? activeColor : inactiveColor, BlendMode.srcIn),
              ),
              selectedIcon: SvgPicture.asset(
                'assets/icons/navigation/clock-nine.svg',
                width: 23,
                colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn),
              ),
              label: 'History',
            ),

            // 4. 👤 Profile Tab
            NavigationDestination(
              icon: SvgPicture.asset(
                'assets/icons/navigation/user-regular.svg',
                width: 20,
                colorFilter: ColorFilter.mode(
                  currentIndex == 3 ? activeColor : inactiveColor, BlendMode.srcIn),
              ),
              selectedIcon: SvgPicture.asset(
                'assets/icons/navigation/user-solid.svg',
                width: 20,
                colorFilter: const ColorFilter.mode(activeColor, BlendMode.srcIn),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}