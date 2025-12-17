import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Features - P2P
import 'features/p2p/data/repositories/p2p_repository_impl.dart';
import 'features/p2p/domain/repositories/p2p_repository.dart';
import 'features/p2p/domain/usecases/scan_for_peers.dart';
import 'features/p2p/domain/usecases/watch_peers.dart';

// Features - Onboarding
import 'features/onboarding/data/models/user_profile_model.dart';
import 'features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 🧹 1. ล้างค่าเก่าทิ้งก่อน (แก้ปัญหา Hot Restart)
  await sl.reset();

  // ! ===========================
  // ! External (ฐานข้อมูล & Hardware)
  // ! ===========================

  // เปิดใช้งาน Isar Database
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    UserProfileModelSchema,
  ], directory: dir.path);
  sl.registerLazySingleton(() => isar);

  // ! ===========================
  // ! Feature: Onboarding (Profile Setup)
  // ! ===========================

  // Data Source
  sl.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSourceImpl(sl()), // ส่ง Isar เข้าไปตรงๆ
  );

  // ❌ ลบบรรทัด registerFactory อันนี้ทิ้งครับ (เพราะมันซ้ำกับข้างล่าง)
  // sl.registerFactory(() => OnboardingCubit(dataSource: sl()));

  // ✅ ใช้ registerLazySingleton ตัวเดียวพอ (Global State)
  sl.registerLazySingleton<OnboardingCubit>(
    () => OnboardingCubit(dataSource: sl()),
  );

  // ! ===========================
  // ! Feature: P2P (Radar)
  // ! ===========================

  // Repository
  // (ถ้ายังไม่มีเครื่องจริงให้ใช้ MockP2PRepository() แทนได้นะ)
  sl.registerLazySingleton<P2PRepository>(() => P2PRepositoryImpl());

  // Use Cases
  sl.registerLazySingleton(() => ScanForPeers(sl()));
  sl.registerLazySingleton(() => WatchPeers(sl()));
}
