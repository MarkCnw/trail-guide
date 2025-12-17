import 'package:isar/isar.dart';
import '../models/user_profile_model.dart'; //implement local data source for user profile management

abstract class OnboardingLocalDataSource {
  Future<void> saveUserProfile(UserProfileModel profile);
  Future<UserProfileModel?> getUserProfile();
  Future<bool> hasUser();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  final Isar isar;

  OnboardingLocalDataSourceImpl(this.isar);

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    await isar.writeTxn(() async {
      // ลบของเก่าออกก่อน (เพราะเราให้มี User ได้คนเดียวในเครื่อง)
      await isar.userProfileModels.clear();
      await isar.userProfileModels.put(profile);
    });
  }

  @override
  Future<UserProfileModel?> getUserProfile() async {
    return await isar.userProfileModels.where().findFirst();
  }

  @override
  Future<bool> hasUser() async {
    final count = await isar.userProfileModels.count();
    return count > 0;
  }
}
