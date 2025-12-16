import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart'; // อย่าลืมลง pkg นี้เพิ่ม
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart'; // เพื่อเรียก sl()
import '../cubit/onboarding_cubit.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OnboardingCubit>(), // เรียก Cubit จาก DI
      child: const _ProfileSetupView(),
    );
  }
}

class _ProfileSetupView extends StatefulWidget {
  const _ProfileSetupView();

  @override
  State<_ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<_ProfileSetupView> {
  final _nameController = TextEditingController();
  String? _selectedImagePath; // เก็บ path รูปที่เลือก
  final _formKey = GlobalKey<FormState>();

  // ฟังก์ชันเลือกรูป
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Your Profile")),
      body: BlocListener<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingSuccess) {
            // บันทึกเสร็จแล้ว -> ไปหน้า Home/Lobby
            context.go('/home'); 
          } else if (state is OnboardingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // 1. ส่วนเลือกรูปโปรไฟล์
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _selectedImagePath != null
                        ? FileImage(File(_selectedImagePath!))
                        : null,
                    child: _selectedImagePath == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Tap to change photo", style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 40),

                // 2. ช่องกรอกชื่อ (บังคับ)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nickname (Required)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your nickname';
                    }
                    return null;
                  },
                ),

                const Spacer(),

                // 3. ปุ่ม Complete Setup
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // ส่งข้อมูลไปบันทึก
                        context.read<OnboardingCubit>().completeSetup(
                          _nameController.text,
                          _selectedImagePath,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800], // สีธีมเดินป่า
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Complete Setup"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}