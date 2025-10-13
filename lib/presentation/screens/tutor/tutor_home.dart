import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/app_router.dart';
import '../../provider/auth_provider.dart';

class TutorHomeScreen extends StatelessWidget {
  const TutorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Tutor Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            tooltip: "Đăng xuất",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AppAuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 Chào gia sư
            Text(
              "Xin chào, ${user?.displayName ?? 'Gia sư'} 👋",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Chúc bạn có một ngày dạy học hiệu quả!",
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // 📊 Thống kê nhanh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCard(Icons.group, "Học viên", "12"),
                _statCard(Icons.calendar_month, "Lớp đang dạy", "5"),
                _statCard(Icons.star, "Đánh giá", "4.8"),
              ],
            ),
            const SizedBox(height: 32),

            // 🔔 Danh sách lớp học gần nhất
            const Text(
              "Lớp học sắp tới",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _lessonCard("Toán lớp 10", "08:00 - 09:00 • 10/10/2025", "Nguyễn Văn A"),
            _lessonCard("Vật lý lớp 11", "14:00 - 15:30 • 10/10/2025", "Trần Thị B"),
            _lessonCard("Hóa lớp 12", "19:00 - 20:30 • 10/10/2025", "Lê Minh C"),

            const SizedBox(height: 32),

            // 🧾 Gợi ý hành động
            const Text(
              "Tác vụ nhanh",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _actionButton(Icons.chat, "Tin nhắn"),
                _actionButton(Icons.schedule, "Lịch dạy"),
                _actionButton(Icons.assessment, "Báo cáo"),
                _actionButton(Icons.person, "Hồ sơ cá nhân"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Thẻ thống kê
  Widget _statCard(IconData icon, String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo, size: 30),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// Thẻ lớp học sắp tới
  Widget _lessonCard(String title, String time, String student) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(Icons.book, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$time\nHọc viên: $student"),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  /// Nút hành động
  Widget _actionButton(IconData icon, String label) {
    return Container(
      width: 150,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
