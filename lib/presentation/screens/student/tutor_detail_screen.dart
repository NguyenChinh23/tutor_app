import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/tutor_model.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(v);

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class TutorDetailScreen extends StatelessWidget {
  const TutorDetailScreen({super.key, required this.tutor});

  final TutorModel tutor;

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;

    // Map an toàn
    final name = tutor.name;
    final subject = tutor.subject;
    final price = tutor.price;
    final rating = tutor.rating;
    final avatar = tutor.avatarUrl ?? '';
    final bio = tutor.bio;
    final experience = tutor.experience;
    final verified = tutor.isTutorVerified;
    final email = tutor.email;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Thông tin gia sư'),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.06), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: điều hướng chat với tutor.uid
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Mở chat (demo)')));
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // TODO: luồng đặt lịch
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đặt lịch với $name (demo)')),
                    );
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Book'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Header Card ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: primary.withOpacity(0.08),
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? Text(
                    _initials(name),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                              const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (verified)
                            Container(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Đã xác minh',
                                      style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subject, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('  •  ${_fmtVnd(price)} đ/h',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.mail_outline, color: Colors.grey[600], size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email.isEmpty ? 'Không có email' : email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Experience ---
          _Section(
            title: 'Kinh nghiệm',
            child: Row(
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 18, color: Colors.grey[800]),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    experience.isEmpty ? 'Chưa cập nhật' : experience,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Bio ---
          _Section(
            title: 'Giới thiệu',
            child: Text(
              bio.isEmpty ? 'Chưa có mô tả.' : bio,
              style: const TextStyle(height: 1.45),
            ),
          ),

          const SizedBox(height: 16),

          // --- Môn dạy khác (nếu cần mở rộng sau) ---
          // Có thể thêm các section khác: Lịch rảnh, Nhận xét, Ảnh chứng chỉ...
          const SizedBox(height: 120), // chừa chỗ cho bottom buttons
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
