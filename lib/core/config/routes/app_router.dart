import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_guide/features/history/presentation/pages/history_page.dart';
import 'package:trail_guide/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:trail_guide/features/p2p/presentation/pages/home_page.dart';
import 'package:trail_guide/features/p2p/presentation/pages/lobby_page.dart';
import 'package:trail_guide/features/p2p/presentation/pages/scan_page.dart';
import 'package:trail_guide/features/profile/presentation/pages/profile_page.dart';
import 'package:trail_guide/features/settings/presentation/pages/settings_page.dart';
import 'package:trail_guide/injection_container.dart';

// Import หน้าจอที่มีอยู่จริง
import '../../../features/onboarding/presentation/pages/profile_setup_page.dart';
import '../../../features/p2p/presentation/pages/radar_page.dart';
import '../../../features/p2p/presentation/widgets/scaffold_with_navbar.dart'; // Import ตัวกรอบที่เราสร้าง



class AppRouter {
  // Key สำหรับ Navigator หลัก (เต็มจอ)
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();


  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home', 
    redirect: (context, state) async {
      final isLoggedIn = await sl<OnboardingLocalDataSource>().hasUser();
      final isLoggingIn = state.uri.toString() == '/profile_setup';

      if (!isLoggedIn && !isLoggingIn) {
        // ถ้ายังไม่มี User และไม่ได้อยู่หน้า Setup -> ดีดไปหน้า Setup
        return '/profile_setup';
      }

      if (isLoggedIn && isLoggingIn) {
        // ถ้ามี User แล้ว แต่อยากเข้าหน้า Setup -> ดีดไปหน้า Home
        return '/home';
      }

      return null; // ปล่อยผ่าน
    },
    routes: [
      // ====================================================
      // 🟢 GROUP 1: Outside Shell (หน้าเต็มจอ ไม่มีเมนูล่าง)
      // ====================================================
      
      // 1. หน้าตั้งค่าโปรไฟล์ (เข้าครั้งแรก)
      GoRoute(
        path: '/profile_setup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileSetupPage(),
      ),

      // 2. หน้าสแกน QR (กด Join จาก Home -> เด้งมาหน้านี้)
      GoRoute(
        path: '/scan',
        parentNavigatorKey: _rootNavigatorKey, // บังคับเด้งทับ Shell
        builder: (context, state) => const ScanPage(), 
      ),

      // 3. หน้า Lobby (กด Host จาก Home -> เด้งมารอเพื่อน)
      GoRoute(
        path: '/lobby',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LobbyPage(),
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // ====================================================
      // 🔵 GROUP 2: Inside Shell (หน้าหลัก มีเมนูล่าง)
      // ใช้ StatefulShellRoute เพื่อรักษา State (P2P Connection)
      // ====================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // 🏠 Branch 1: Home Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),

          // 📡 Branch 2: Radar Tab (หน้าสำคัญ! ห้าม Dispose)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/radar',
                builder: (context, state) => const RadarPage(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),

          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}