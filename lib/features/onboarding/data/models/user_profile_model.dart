import 'package:isar/isar.dart';
part 'user_profile_model.g.dart'; // ให้ Isar Gen โค้ดให้
@collection
class UserProfileModel {
  Id id = Isar.autoIncrement; // ไอดีอัตโนมัติ

  late String nickname; //ชื่อเล่น บังคับใส่

  String? imagePath; // ที่อยู่ไฟล์รูป (ถ้าไม่ใส่จะเป็น null)

  // เพิ่ม Medical ID เผื่อไว้
  String? bloodType;
  String? allergies;
}
