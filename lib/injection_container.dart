import 'package:get_it/get_it.dart';
import 'package:trail_guide/features/p2p/data/repositories/p2p_repository_impl.dart';


// Import ไฟล์ Bloc
import 'features/p2p/presentation/bloc/p2p_bloc.dart';

// Import ไฟล์ Repository และ UseCases
// import 'features/p2p/data/repositories/p2p_repository_impl.dart'; // ❌ ปิดตัวจริงไว้ก่อน

import 'features/p2p/domain/repositories/p2p_repository.dart';
import 'features/p2p/domain/usecases/scan_for_peers.dart';
import 'features/p2p/domain/usecases/watch_peers.dart';

// สร้างตัวแปร sl (Service Locator) ให้เรียกใช้ง่ายๆ
final sl = GetIt.instance;

Future<void> init() async {
  //! Features - P2P Radar
  // เราจะเริ่มลงทะเบียนจาก "วงนอกสุด" (External) เข้ามาหา "วงใน" (Domain)

  // 1. Data Layer (Repository Implementation)

  // ❌ Comment ตัวจริง (Real Implementation) ไว้ก่อน
  sl.registerLazySingleton<P2PRepository>(
    () => P2PRepositoryImpl(),
  );

  // ✅ ใช้ตัว Mock (Fake Implementation) แทน เพื่อให้รันบน Simulator ได้
  // sl.registerLazySingleton<P2PRepository>(() => MockP2PRepository());

  // 2. Domain Layer (Use Cases)
  // ลงทะเบียนคำสั่งต่างๆ
  sl.registerLazySingleton(() => ScanForPeers(sl()));
  sl.registerLazySingleton(() => WatchPeers(sl()));

  // 3. Presentation Layer (Bloc)
  // ลงทะเบียน Bloc (ใช้ registerFactory เพื่อให้สร้างใหม่ทุกครั้งที่เข้าหน้า)
  sl.registerFactory(() => P2PBloc(scanForPeers: sl(), watchPeers: sl()));
}
