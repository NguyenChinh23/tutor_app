import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../provider/auth_provider.dart';
import '../../../config/app_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _confirmAction(
      BuildContext context, {
        required String title,
        required String content,
        required Future<void> Function() onConfirm,
      }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onConfirm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title thành công! ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    final repo = AuthRepository();
    final reviewerUid = repo.currentUser?.uid ?? 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ Admin Dashboard - Duyệt Gia Sư'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
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
      backgroundColor: const Color(0xFFF9FAFB),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs
            .collection('tutorApplications')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                'Lỗi tải dữ liệu: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '📭 Chưa có hồ sơ gia sư nào đang chờ duyệt.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final uid = d['uid'] ?? '';
              final name = d['fullName'] ?? 'Chưa có tên';
              final subj = d['subject'] ?? 'Không rõ';
              final status = d['status'] ?? 'pending';
              final appId = docs[i].id;

              final statusColor = switch (status) {
                'approved' => Colors.green,
                'rejected' => Colors.red,
                _ => Colors.orange,
              };

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text('📘 Môn: $subj\n📄 Trạng thái: $status',
                      style: TextStyle(color: statusColor)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status != 'approved')
                        ElevatedButton(
                          onPressed: () => _confirmAction(
                            context,
                            title: 'Duyệt hồ sơ',
                            content: 'Bạn có chắc muốn duyệt hồ sơ này?',
                            onConfirm: () async {
                              await repo.approveTutor(
                                uid: uid,
                                appId: appId,
                                reviewerUid: reviewerUid,
                              );
                            },
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Duyệt'),
                        ),
                      const SizedBox(width: 8),
                      if (status != 'rejected')
                        ElevatedButton(
                          onPressed: () => _confirmAction(
                            context,
                            title: 'Từ chối hồ sơ',
                            content:
                            'Bạn có chắc muốn từ chối hồ sơ này không?',
                            onConfirm: () async {
                              await fs
                                  .collection('tutorApplications')
                                  .doc(appId)
                                  .set(
                                {
                                  'status': 'rejected',
                                  'reviewedBy': reviewerUid,
                                  'reviewedAt': FieldValue.serverTimestamp(),
                                },
                                SetOptions(merge: true),
                              );
                            },
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Từ chối'),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
