import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Features - P2P
import 'features/p2p/data/repositories/p2p_repository_impl.dart';
import 'features/p2p/domain/repositories/p2p_repository.dart';
import 'features/p2p/domain/usecases/scan_for_peers.dart';
import 'features/p2p/domain/usecases/watch_peers.dart';
import 'features/p2p/presentation/bloc/p2p_bloc.dart';

// Features - Onboarding
import 'features/onboarding/data/models/user_profile_model.dart';
import 'features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 🧹 1. ล้างค่าเก่าทิ้งก่อน (แก้ปัญหา Hot Restart)
  await sl.reset();

  // ! ===========================
  // !  External (ฐานข้อมูล & Hardware)
  // ! ===========================

  // เปิดใช้งาน Isar Database
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    UserProfileModelSchema,
  ], directory: dir. path);
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
  // ! ===========================กฟไก

  // Repository
  sl.registerLazySingleton<P2PRepository>(() => P2PRepositoryImpl());

  // Use Cases
  sl.registerLazySingleton(() => ScanForPeers(sl()));
  sl.registerLazySingleton(() => WatchPeers(sl()));

  // ✅ แก้ไข: ใช้ registerLazySingleton แทน registerFactory
  // เพื่อให้ P2P connection state คงอยู่แม้เปลี่ยนหน้า
  sl.registerLazySingleton<P2PBloc>(
    () => P2PBloc(
      scanForPeers: sl(),
      watchPeers: sl(),
      repository: sl(),
    ),
  );
}