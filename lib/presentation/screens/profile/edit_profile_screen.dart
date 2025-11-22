import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  // field riêng cho tutor
  late TextEditingController subjectController;
  late TextEditingController priceController;
  late TextEditingController experienceController;
  late TextEditingController bioController;

  File? _avatarFile;
  bool _saving = false;
  bool _loadingExtra = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user;

    nameController = TextEditingController(text: user?.displayName ?? '');
    goalController = TextEditingController(text: user?.goal ?? '');

    subjectController = TextEditingController();
    priceController = TextEditingController();
    experienceController = TextEditingController();
    bioController = TextEditingController();

    if (user != null && user.role == 'tutor') {
      _loadTutorExtra(user.uid);
    }
  }

  Future<void> _loadTutorExtra(String uid) async {
    setState(() => _loadingExtra = true);
    try {
      final snap =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data();
      if (data != null) {
        subjectController.text = (data['subject'] ?? '').toString();
        bioController.text = (data['bio'] ?? '').toString();
        experienceController.text = (data['experience'] ?? '').toString();

        final p = data['price'];
        if (p != null) {
          if (p is int) {
            priceController.text = p.toString();
          } else if (p is num) {
            priceController.text = p.toStringAsFixed(0);
          } else {
            priceController.text = p.toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Load tutor extra error: $e');
    } finally {
      if (mounted) setState(() => _loadingExtra = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    goalController.dispose();
    subjectController.dispose();
    priceController.dispose();
    experienceController.dispose();
    bioController.dispose();
    super.dispose();
  }

  /// Chọn ảnh từ gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
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

  /// Lưu dữ liệu
  Future<void> _save() async {
    final auth = context.read<AppAuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final bool isTutor = user.role == 'tutor';

    setState(() => _saving = true);
    try {
      String? avatarValue = user.avatarUrl;

      // Nếu có chọn ảnh mới → convert sang base64
      if (_avatarFile != null) {
        final bytes = await _avatarFile!.readAsBytes();
        avatarValue = base64Encode(bytes);
        debugPrint('Avatar encoded length = ${avatarValue.length}');
      }

      // goal:
      // - Student: lấy từ TextField
      // - Tutor: giữ nguyên goal cũ (không cho sửa)
      final String finalGoal =
      isTutor ? (user.goal ?? '') : goalController.text.trim();

      String? subject;
      String? bio;
      double? price;
      String? experience;

      if (isTutor) {
        subject = subjectController.text.trim();
        bio = bioController.text.trim();
        experience = experienceController.text.trim();

        final raw = priceController.text
            .trim()
            .replaceAll('.', '')
            .replaceAll(',', '');
        final parsed = double.tryParse(raw);
        if (parsed != null) price = parsed;
      }

      await auth.updateProfile(
        nameController.text.trim(),
        finalGoal,
        avatarUrl: avatarValue,
        subject: subject,
        bio: bio,
        price: price,
        experience: experience,
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
        // Ảnh dạng URL (tutor apply ban đầu)
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
    final isTutor = user.role == 'tutor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
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
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Họ và tên"),
            ),
            const SizedBox(height: 10),

            // 🔹 Chỉ học viên mới có mục tiêu học tập
            if (!isTutor) ...[
              TextField(
                controller: goalController,
                decoration:
                const InputDecoration(labelText: "Mục tiêu học tập"),
              ),
            ],

            // === field dành cho tutor ===
            if (isTutor) ...[
              const SizedBox(height: 20),
              if (_loadingExtra)
                const Center(child: CircularProgressIndicator())
              else ...[
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: "Môn dạy (ví dụ: Math)",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Giá mỗi buổi (VND)",
                    hintText: "Ví dụ: 200000",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: experienceController,
                  decoration: const InputDecoration(
                    labelText: "Kinh nghiệm",
                    hintText: "Ví dụ: 5 năm",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Giới thiệu bản thân (bio)",
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ],

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
