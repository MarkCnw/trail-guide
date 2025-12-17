// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:trail_guide/core/constants/app_colors.dart';

// class AppTheme {
//   AppTheme._();
//   static ThemeData get light => ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.light,
//     colorSchemeSeed: AppColors.primaryGreen,
//     scaffoldBackgroundColor: AppColors.background,
//     // Navigation Bar Theme
//     navigationBarTheme: NavigationBarThemeData(
//       backgroundColor: AppColors.navBackground,
//       indicatorColor: Colors.transparent,
//       overlayColor: WidgetStateProperty.all(Colors.transparent),
//       labelTextStyle: WidgetStateProperty.resolveWith((states) {
//         final isSelected = states.contains(WidgetState.selected);
//         return GoogleFonts.inter(
//           fontSize: 12,
//           fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
//           color: isSelected ? AppColors.navActive : AppColors.navInactive,
//         );
//       }),
//     ),

//     // Text Theme
//     textTheme: GoogleFonts.interTextTheme(),

//     // AppBar Theme
//     appBarTheme: AppBarTheme(
//       backgroundColor: AppColors.background,
//       elevation: 0,
//       centerTitle: true,
//       titleTextStyle: GoogleFonts.inter(
//         fontSize: 20,
//         fontWeight: FontWeight.w600,
//         color: AppColors.textPrimary,
//       ),
//       iconTheme: const IconThemeData(color: AppColors.textPrimary),
//     ),

//     // Card Theme - ✅ แก้ไขตรงนี้
//     cardTheme: CardThemeData(
//       color: AppColors.card,
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//     ),
//   );
// }
