import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNavBar'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ส่วนเนื้อหาที่จะเปลี่ยนไปเรื่อยๆ (Home, Radar) โดยยังคง State ไว้
      body: navigationShell, 
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          // สั่งให้ Router เปลี่ยน Branch (Tab)
          navigationShell.goBranch(
            index,
            // (Optional) กดซ้ำเพื่อกลับไปหน้าแรกของ Tab นั้น
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar),
            label: 'Radar',
          ),
          // เพิ่ม Tab อื่นๆ ตรงนี้ได้ เช่น History, Settings
        ],
      ),
    );
  }
}