import 'package:dartz/dartz.dart';
import 'package:trail_guide/core/usecases/usecase.dart';

import '../../../../core/error/failures.dart';
import '../repositories/p2p_repository.dart';

class ScanForPeers implements UseCase<void, NoParams> {
  final P2PRepository repository;

  ScanForPeers(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.startDiscovery();
  }
}