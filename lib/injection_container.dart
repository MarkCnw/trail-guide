import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Features - P2P
import 'features/p2p/data/repositories/p2p_repository_impl.dart';
import 'features/p2p/domain/repositories/p2p_repository.dart';
import 'features/p2p/domain/usecases/scan_for_peers.dart';
import 'features/p2p/domain/usecases/watch_peers.dart';
import 'features/p2p/presentation/bloc/p2p_bloc.dart'; // 👈 อย่าลืม import อันนี้

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
    () => OnboardingLocalDataSourceImpl(sl()),
  );

  // Cubit (Global State)
  sl.registerLazySingleton<OnboardingCubit>(
    () => OnboardingCubit(dataSource: sl()),
  );

  // ! ===========================
  // ! Feature: P2P (Radar & Host)
  // ! ===========================

  // Repository
  sl.registerLazySingleton<P2PRepository>(() => P2PRepositoryImpl());

  // Use Cases
  sl.registerLazySingleton(() => ScanForPeers(sl()));
  sl.registerLazySingleton(() => WatchPeers(sl()));

  // ✨ Bloc (เพิ่มส่วนนี้) ✨
  // ใช้ registerFactory เพราะ Bloc ควรถูกสร้างใหม่ทุกครั้งที่เรียกใช้ (เช่น เข้าออกหน้าใหม่)
  sl.registerFactory(
    () => P2PBloc(
      scanForPeers: sl(),
      watchPeers: sl(),
      repository: sl(), // 👈 ส่ง repository เข้าไปตามที่แก้ใน Bloc
    ),
  );
}