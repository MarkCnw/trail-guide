import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

// Import ของในโปรเจกต์ (ปรับ Path ตามจริงของคุณ)
import '../../../../injection_container.dart';

// import '../../../../core/constants/app_strings.dart'; // ถ้ามี
import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<OnboardingCubit>()..loadUserProfile(), child: const _ProfileView());
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  // 🔑 Key สำหรับตรวจสอบ Form
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  String? _imagePath;

  late TextEditingController _nameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _bloodTypeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _bloodTypeController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<OnboardingCubit>().state;
      if (state is OnboardingLoaded) {
        _nameController.text = state.profile.nickname;
        if (mounted) setState(() => _imagePath = state.profile.imagePath);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emergencyPhoneController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }

  // 🛠️ Logic: สลับโหมดแก้ไข
  void _toggleEditMode() {
    setState(() => _isEditing = !_isEditing);
  }

  // 🛠️ Logic: เลือกรูปภาพ
  Future<void> _pickImage() async {
    if (!_isEditing) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _imagePath = pickedFile.path);
    }
  }

  // 🛠️ Logic: บันทึกข้อมูล
  void _saveProfile() {
    // 1. ตรวจสอบข้อมูลก่อนบันทึก (Validation)
    if (_formKey.currentState!.validate()) {
      // 2. เรียก Cubit ให้ทำงาน
      context.read<OnboardingCubit>().completeSetup(
        _nameController.text,
        _imagePath,
        // TODO: ส่งข้อมูล emergency/bloodType ไปเพิ่มใน Cubit ภายหลัง
      );

      // 3. แจ้งเตือนและกลับสู่โหมดดู
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully! ✅')));
      _toggleEditMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 Theme Colors (ใช้ตัวแปรเพื่อให้แก้สีง่ายในอนาคต)
    const primaryColor = Color(0xFF2E7D32);
    const backgroundColor = Color(0xFFF6F8F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            // ใช้ Logic ที่แยกไว้แล้ว ทำให้โค้ดอ่านง่าย
            onPressed: _isEditing ? _saveProfile : _toggleEditMode,
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            label: Text(_isEditing ? "Save" : "Edit"),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingLoaded) {
            // อัปเดตข้อมูลเมื่อโหลดเสร็จ (เฉพาะตอนไม่ได้แก้ไขอยู่)
            if (!_isEditing) {
              _nameController.text != state.profile.nickname;
              _imagePath = state.profile.imagePath;
              // _emergencyPhoneController.text = state.profile.phone ?? '';
            }
          }
        },
        builder: (context, state) {
          if (state is OnboardingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = (state is OnboardingLoaded) ? state.profile : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 👤 1. ส่วนรูปโปรไฟล์ (แยก Widget)
                  _ProfileImageSelector(
                    imagePath: _isEditing ? _imagePath : profile?.imagePath,
                    isEditing: _isEditing,
                    onTap: _pickImage,
                    primaryColor: primaryColor,
                  ),

                  const SizedBox(height: 30),

                  // 📝 2. ฟอร์มข้อมูล (แยก Widget)
                  _CustomTextField(
                    label: "Nickname / Call Sign",
                    icon: Icons.badge,
                    controller: _nameController,
                    isEditing: _isEditing,
                    activeColor: primaryColor,
                    // ✅ Validation Logic
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your nickname' : null,
                  ),
                  const SizedBox(height: 16),

                  _CustomTextField(
                    label: "Emergency Contact (SOS)",
                    icon: Icons.phone_in_talk,
                    controller: _emergencyPhoneController,
                    isEditing: _isEditing,
                    inputType: TextInputType.phone,
                    hint: "เบอร์ติดต่อฉุกเฉิน",
                    activeColor: primaryColor,
                  ),
                  const SizedBox(height: 16),

                  _CustomTextField(
                    label: "Blood Type / Medical Info",
                    icon: Icons.medical_services,
                    controller: _bloodTypeController,
                    isEditing: _isEditing,
                    hint: "กรุ๊ปเลือด, โรคประจำตัว, ยาที่แพ้",
                    activeColor: primaryColor,
                  ),

                  const SizedBox(height: 40),

                  // 📊 3. ส่วนสถิติ (แยก Widget)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Hiking Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: const [
                      _StatCard(title: "Trips", value: "0", icon: Icons.map, color: primaryColor),
                      SizedBox(width: 16),
                      _StatCard(title: "Distance", value: "0 km", icon: Icons.directions_walk, color: primaryColor),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🧩 Extracted Widgets (Clean Code Area)
// -----------------------------------------------------------------------------

class _ProfileImageSelector extends StatelessWidget {
  final String? imagePath;
  final bool isEditing;
  final VoidCallback onTap;
  final Color primaryColor;

  const _ProfileImageSelector({required this.imagePath, required this.isEditing, required this.onTap, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: imagePath != null ? FileImage(File(imagePath!)) : null,
              child: imagePath == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
            ),
          ),
          if (isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isEditing;
  final TextInputType inputType;
  final String? hint;
  final Color activeColor;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.isEditing,
    required this.activeColor,
    this.inputType = TextInputType.text,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: isEditing,
      keyboardType: inputType,
      validator: validator, // ✅ ใส่ Validation ได้แล้ว
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: isEditing ? activeColor : Colors.grey),
        border: _buildBorder(Colors.grey[300]!),
        enabledBorder: _buildBorder(Colors.grey[300]!),
        focusedBorder: _buildBorder(activeColor),
        disabledBorder: _buildBorder(Colors.transparent), // ตอนดู ให้ไม่มีขอบหรือขอบจางๆ
        filled: true,
        fillColor: isEditing ? Colors.white : Colors.grey[200],
      ),
      style: TextStyle(color: isEditing ? Colors.black : Colors.black87, fontWeight: isEditing ? FontWeight.normal : FontWeight.w500),
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
