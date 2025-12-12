import 'package:equatable/equatable.dart';

// แม่แบบหลัก (Abstract Class)
abstract class Failure extends Equatable {
  final String message;
  
  const Failure([this.message = 'Unexpected Error']);

  @override
  List<Object> get props => [message];
}

// สร้าง Error ย่อยๆ เตรียมไว้ (สำหรับเคสทั่วไป)
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Error']);
}

// สร้าง Error สำหรับ P2P โดยเฉพาะ (ใส่เพิ่มได้เลย)
class P2PFailure extends Failure {
  const P2PFailure([super.message = 'P2P Connection Error']);
}