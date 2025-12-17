import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/onboarding_local_data_source.dart';
import '../../data/models/user_profile_model.dart';

// State ง่ายๆ
abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingSuccess extends OnboardingState {}

class OnboardingLoaded extends OnboardingState {
  final UserProfileModel profile;
  OnboardingLoaded(this.profile);
}

class OnboardingFailure extends OnboardingState {
  final String message;
  OnboardingFailure(this.message);
}

class OnboardingCubit extends Cubit<OnboardingState> {
  final OnboardingLocalDataSource dataSource;

  OnboardingCubit({required this.dataSource}) : super(OnboardingInitial());

  Future<void> completeSetup(String nickname, String? imagePath) async {
    emit(OnboardingLoading());

    try {
      final profile = UserProfileModel()
        ..nickname = nickname
        ..imagePath = imagePath;

      await dataSource.saveUserProfile(profile);

      // 1. บอกว่าสำเร็จ (เพื่อให้ UI โชว์ SnackBar หรือเปลี่ยนหน้า)
      emit(OnboardingSuccess());

      // ✨ 2. โหลดข้อมูลใหม่ทันที! (เพื่อให้ HomePage อัปเดตชื่อ/รูปใหม่)
      await loadUserProfile();
    } catch (e) {
      emit(OnboardingFailure("บันทึกไม่สำเร็จ: $e"));
    }
  }

  // ใน class Cubit เพิ่มฟังก์ชันนี้
  Future<void> loadUserProfile() async {
    try {
      final profile = await dataSource.getUserProfile();
      if (profile != null) {
        emit(OnboardingLoaded(profile)); // ส่งข้อมูลไปให้ UI
      }
    } catch (e) {
      // Handle error (เงียบไว้ก่อนก็ได้ครับ)
    }
  }
}
