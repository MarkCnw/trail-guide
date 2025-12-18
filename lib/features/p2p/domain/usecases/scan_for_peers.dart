import 'package:dartz/dartz.dart';
import 'package:trail_guide/core/usecases/usecase.dart';

import '../../../../core/error/failures.dart';
import '../repositories/p2p_repository.dart';

class ScanForPeers implements UseCase<void, NoParams> {
  final P2PRepository repository;

  ScanForPeers(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    // 1. ตั้งชื่อที่จะไปโชว์บนเครื่อง Host (เดี๋ยวค่อยแก้ให้ดึงจาก Profile จริงๆ ทีหลัง)
    const String userName = "TrailGuide Member"; 
    
    // 2. รูปแบบการเชื่อมต่อ (ต้องใช้แบบเดียวกับ Host)
    const String strategy = "star"; 

    return await repository.startDiscovery(userName, strategy);
  }
}