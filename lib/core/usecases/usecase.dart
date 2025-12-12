import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

// สัญญาว่าทุก UseCase ต้องมีฟังก์ชัน call เสมอ
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// คลาสสำหรับ UseCase ที่ไม่ต้องส่งค่าอะไรเข้าไป (เช่น การกดปุ่ม Scan เฉยๆ)
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}