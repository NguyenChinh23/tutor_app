import 'package:flutter/material.dart';

/// 🔍 Màn hình tìm kiếm gia sư (TutorSearchScreen)
/// Sẽ mở khi người dùng bấm vào thanh search trong trang Home
class TutorSearchScreen extends StatelessWidget {
  const TutorSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text("Tìm kiếm gia sư"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Nhập tên môn học hoặc gia sư...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Text(
                  "Kết quả tìm kiếm sẽ hiển thị tại đây 🔎",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
