import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final goalController = TextEditingController();
  File? _avatarFile;
  bool _saving = false;

  @override
  void dispose() {
    nameController.dispose();
    goalController.dispose();
    super.dispose();
  }

  /// 🔹 Mở gallery chọn ảnh
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() => _avatarFile = File(picked.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh đã được chọn ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa chọn ảnh nào.')),
        );
      }
    } catch (e) {
      debugPrint('ImagePicker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  /// 🔹 Upload ảnh lên Firebase Storage
  Future<String?> _uploadAvatar(String uid) async {
    if (_avatarFile == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child('avatars/$uid.jpg');
      await ref.putFile(_avatarFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final user = auth.user;

    nameController.text = user?.displayName ?? '';
    goalController.text = user?.goal ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _avatarFile != null
                    ? FileImage(_avatarFile!)
                    : (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: _avatarFile == null &&
                    (user?.avatarUrl == null ||
                        user!.avatarUrl!.isEmpty)
                    ? const Icon(Icons.camera_alt, size: 32, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Họ và tên"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: goalController,
              decoration: const InputDecoration(labelText: "Mục tiêu học tập"),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _saving
                    ? null
                    : () async {
                  if (user == null) return;
                  setState(() => _saving = true);
                  try {
                    final avatarUrl =
                        await _uploadAvatar(user.uid) ?? user.avatarUrl;

                    await auth.updateProfile(
                      nameController.text.trim(),
                      goalController.text.trim(),
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text("Cập nhật hồ sơ thành công 🎉")),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi: $e")),
                    );
                  } finally {
                    setState(() => _saving = false);
                  }
                },
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Lưu thay đổi",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
