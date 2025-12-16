import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/onboarding_local_data_source.dart';
import '../../data/models/user_profile_model.dart';

// State ง่ายๆ
abstract class OnboardingState {}
class OnboardingInitial extends OnboardingState {}
class OnboardingLoading extends OnboardingState {}
class OnboardingSuccess extends OnboardingState {}

class OnboardingFailure extends OnboardingState {
  final String message;
  OnboardingFailure(this.message);
}

class OnboardingCubit extends Cubit<OnboardingState> {
  final OnboardingLocalDataSource dataSource;

  OnboardingCubit({required this.dataSource}) : super(OnboardingInitial());

  Future<void> completeSetup(String nickname, String? imagePath) async {
    if (nickname.trim().isEmpty) {
      emit(OnboardingFailure("กรุณากรอกชื่อเล่น"));
      return;
    }

    emit(OnboardingLoading());

    try {
      final profile = UserProfileModel()
        ..nickname = nickname
        ..imagePath = imagePath; // ถ้าเป็น null คือใช้รูป default

      await dataSource.saveUserProfile(profile);

      emit(OnboardingSuccess());
    } catch (e) {
      emit(OnboardingFailure("บันทึกข้อมูลไม่สำเร็จ: $e"));
    }
  }
}
