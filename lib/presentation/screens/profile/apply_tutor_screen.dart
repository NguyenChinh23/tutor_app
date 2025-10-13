import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../provider/auth_provider.dart';

class ApplyTutorScreen extends StatefulWidget {
  const ApplyTutorScreen({super.key});

  @override
  State<ApplyTutorScreen> createState() => _ApplyTutorScreenState();
}

class _ApplyTutorScreenState extends State<ApplyTutorScreen> {
  final fullName = TextEditingController();
  final subject = TextEditingController();
  final experience = TextEditingController();
  final description = TextEditingController();

  bool submitting = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final repo = AuthRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký làm gia sư')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: fullName, decoration: const InputDecoration(labelText: 'Họ tên')),
          const SizedBox(height: 12),
          TextField(controller: subject, decoration: const InputDecoration(labelText: 'Môn dạy chính')),
          const SizedBox(height: 12),
          TextField(controller: experience, decoration: const InputDecoration(labelText: 'Kinh nghiệm')),
          const SizedBox(height: 12),
          TextField(controller: description, decoration: const InputDecoration(labelText: 'Mô tả ngắn')),
          const SizedBox(height: 20),
          submitting
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: () async {
              if (auth.user == null) return;
              setState(() => submitting = true);
              await repo.applyTutor(
                uid: auth.user!.uid,
                fullName: fullName.text.trim(),
                subject: subject.text.trim(),
                experience: experience.text.trim(),
                description: description.text.trim(),
              );
              setState(() => submitting = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi hồ sơ. Vui lòng chờ duyệt.')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Gửi hồ sơ'),
          ),
          const SizedBox(height: 12),
          if (auth.user?.role == 'tutor' && auth.user?.isTutorVerified == false)
            const Text('Trạng thái: đang chờ duyệt', style: TextStyle(color: Colors.orange)),
        ]),
      ),
    );
  }
}
