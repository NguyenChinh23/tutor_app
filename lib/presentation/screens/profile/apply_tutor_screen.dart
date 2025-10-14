import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../provider/auth_provider.dart';
import 'package:tutor_app/config/app_router.dart';

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
      appBar: AppBar(
        title: const Text(
          'Đăng ký làm gia sư',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Thông tin hồ sơ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 🔹 Họ tên
            TextField(
              controller: fullName,
              decoration: const InputDecoration(
                labelText: 'Họ tên',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // 🔹 Môn dạy chính
            TextField(
              controller: subject,
              decoration: const InputDecoration(
                labelText: 'Môn dạy chính',
                prefixIcon: Icon(Icons.book_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // 🔹 Kinh nghiệm
            TextField(
              controller: experience,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kinh nghiệm (năm)',
                prefixIcon: Icon(Icons.school_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // 🔹 Mô tả ngắn
            TextField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả ngắn',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 Nút gửi hồ sơ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: submitting
                    ? null
                    : () async {
                  if (auth.user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng đăng nhập lại.'),
                      ),
                    );
                    return;
                  }

                  final name = fullName.text.trim();
                  final sub = subject.text.trim();
                  final exp = experience.text.trim();
                  final desc = description.text.trim();

                  if ([name, sub, exp, desc].any((e) => e.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập đầy đủ thông tin.'),
                      ),
                    );
                    return;
                  }

                  setState(() => submitting = true);
                  try {
                    print(' Gửi hồ sơ lên Firestore...');
                    await repo.applyTutor(
                      uid: auth.user!.uid,
                      email: auth.user!.email ?? '',
                      fullName: name,
                      subject: sub,
                      experience: exp,
                      description: desc,
                    );
                    print('Gửi hồ sơ thành công');

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã gửi hồ sơ. Vui lòng chờ admin duyệt.'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    //  Chuyển sang trang StudentHome và xóa route cũ
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.studentHome,
                          (route) => false,
                    );
                  } on FirebaseException catch (e) {
                    print('Firebase lỗi: ${e.code} - ${e.message}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Firebase lỗi: ${e.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    print('Lỗi khác: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi không xác định: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => submitting = false);
                  }
                },
                child: submitting
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Text(
                  'Gửi hồ sơ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Hiển thị trạng thái
            if (auth.user?.role == 'tutor' &&
                auth.user?.isTutorVerified == false)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.hourglass_empty),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Trạng thái: Hồ sơ của bạn đang chờ được duyệt.",
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
