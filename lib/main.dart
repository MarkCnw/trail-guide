import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 👈 อย่าลืม import
import 'package:trail_guide/core/config/routes/app_router.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🟢 ครอบทั้งแอปด้วย MultiBlocProvider
    return MultiBlocProvider(
      providers: [
        // สร้าง Cubit และโหลดข้อมูล User ทิ้งไว้เลยตั้งแต่เข้าแอป 🚀
        BlocProvider<OnboardingCubit>(
          create: (_) => di.sl<OnboardingCubit>()..loadUserProfile(),
        ),
      ],
      child: MaterialApp.router( // ใช้ router ตามที่คุณวางโครงสร้างไว้
        debugShowCheckedModeBanner: false,
        title: 'TrailGuide',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router, // 👈 ใช้ Router ตัวเก่งของคุณ
      ),
    );
  }
}