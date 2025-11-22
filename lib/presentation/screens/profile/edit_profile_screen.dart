import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController goalController;
  File? _avatarFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user;
    nameController = TextEditingController(text: user?.displayName ?? '');
    goalController = TextEditingController(text: user?.goal ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    goalController.dispose();
    super.dispose();
  }

  /// Chọn ảnh từ gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // nén bớt cho nhẹ
      );

      if (picked != null) {
        setState(() => _avatarFile = File(picked.path));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh đã được chọn')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa chọn ảnh nào.')),
        );
      }
    } catch (e) {
      debugPrint('ImagePicker error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  /// Lưu dữ liệu: name, goal, avatar (base64 hoặc giữ nguyên)
  Future<void> _save() async {
    final auth = context.read<AppAuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      String? avatarValue = user.avatarUrl;

      // Nếu có chọn ảnh mới → convert sang base64
      if (_avatarFile != null) {
        final bytes = await _avatarFile!.readAsBytes();
        avatarValue = base64Encode(bytes);
        debugPrint('Avatar encoded length = ${avatarValue.length}');
      }

      await auth.updateProfile(
        nameController.text.trim(),
        goalController.text.trim(),
        avatarUrl: avatarValue,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật hồ sơ thành công 🎉")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ImageProvider? _buildAvatarImage(AppAuthProvider auth) {
    final user = auth.user;
    if (_avatarFile != null) {
      return FileImage(_avatarFile!);
    }
    final url = user?.avatarUrl;
    if (url == null || url.isEmpty) return null;

    try {
      if (url.startsWith('http')) {
        // Ảnh dạng URL (tutor cũ / default)
        return NetworkImage(url);
      } else {
        // Ảnh lưu dạng base64 trong Firestore
        final bytes = base64Decode(url);
        return MemoryImage(bytes);
      }
    } catch (e) {
      debugPrint('Avatar decode error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final avatarImage = _buildAvatarImage(auth);

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
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? const Icon(
                  Icons.camera_alt,
                  size: 32,
                  color: Colors.grey,
                )
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
              decoration:
              const InputDecoration(labelText: "Mục tiêu học tập"),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Lưu thay đổi",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
