import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../provider/auth_provider.dart';
import '../../../config/app_router.dart';
import '../../../config/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final List<String> _statuses = ["pending", "approved", "rejected"];

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    final repo = AuthRepository();
    final reviewerUid = repo.currentUser?.uid ?? "admin";

    final List<Widget> pages = _statuses.map((status) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs
            .collection('tutorApplications')
            .where('status', isEqualTo: status)
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Lỗi tải dữ liệu: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text("📭 Không có hồ sơ nào.", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final name = d['fullName'] ?? 'Chưa có tên';
              final subj = d['subject'] ?? 'Không rõ';
              final exp = d['experience'] ?? '0';
              final desc = d['description'] ?? '';
              final uid = d['uid'];
              final appId = d['id']; // 🔹 Dùng field "id" trong document
              final email = d['email'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(" Môn dạy: $subj"),
                      Text(" Kinh nghiệm: $exp năm"),
                      if (desc.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(" Mô tả: $desc"),
                        ),
                      const SizedBox(height: 12),

                      // Nút hành động
                      if (status == 'pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await repo.approveTutor(
                                    uid: uid,
                                    appId: appId,
                                    reviewerUid: reviewerUid,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                      Text("✅ Đã duyệt hồ sơ của $name ($email)"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Lỗi duyệt: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check),
                              label: const Text("Duyệt"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await repo.rejectTutor(
                                    appId: appId,
                                    reviewerUid: reviewerUid,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("🚫 Đã từ chối hồ sơ"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Lỗi từ chối: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.close),
                              label: const Text("Từ chối"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("️Admin Dashboard"),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            tooltip: "Đăng xuất",
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AppAuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRouter.login, (route) => false);
              }
            },
          )
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions), label: "Chờ duyệt"),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: "Đã duyệt"),
          BottomNavigationBarItem(
              icon: Icon(Icons.cancel_outlined), label: "Từ chối"),
        ],
      ),
    );
  }
}
