// lib/presentation/screens/student/tutor_detail_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/config/app_router.dart';
import 'package:tutor_app/data/models/tutor_model.dart';
import 'package:tutor_app/presentation/screens/student/book_lesson_screen.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0)
        .format(v);

String _initials(String name) {
  final parts =
  name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// build avatar cho tutor: hỗ trợ http + base64 + fallback null
ImageProvider? _buildTutorAvatar(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;

  try {
    if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    } else {
      final bytes = base64Decode(avatarUrl);
      return MemoryImage(bytes);
    }
  } catch (e) {
    debugPrint('Tutor avatar decode error: $e');
    return null;
  }
}

class TutorDetailScreen extends StatefulWidget {
  const TutorDetailScreen({
    super.key,
    required this.tutor,
    this.autoOpenBook = false,
  });

  final TutorModel tutor;
  final bool autoOpenBook;

  @override
  State<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoOpenBook) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openBookingScreen();
      });
    }
  }

  void _openBookingScreen() {
    final auth = context.read<AppAuthProvider>();

    // 🔥 GUEST → LOGIN NGAY
    if (auth.status == AuthStatus.guest) {
      Navigator.pushNamed(context, AppRouter.login);
      return;
    }

    // ĐÃ LOGIN → VÀO BOOK
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookLessonScreen(tutor: widget.tutor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final tutor = widget.tutor;

    final name = tutor.name;
    final subject = tutor.subject;
    final price = tutor.price;
    final rating = tutor.rating;
    final avatarUrl = tutor.avatarUrl;
    final bio = tutor.bio;
    final experience = tutor.experience;
    final verified = tutor.isTutorVerified;
    final email = tutor.email;
    final availability = tutor.availabilityNote; // lịch rảnh

    // 🆕 thống kê
    final int totalLessons = tutor.totalLessons;     // cần có trong TutorModel
    final int totalStudents = tutor.totalStudents;   // cần có trong TutorModel

    final avatarImage = _buildTutorAvatar(avatarUrl);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Thông tin gia sư'),
      ),

      // 🧿 BOTTOM BAR: chỉ còn nút Book, bỏ Chat
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.06),
                blurRadius: 8,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _openBookingScreen,
            icon: const Icon(Icons.calendar_today_outlined),
            label: const Text(
              'Book buổi học',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Header =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: primary.withOpacity(0.08),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (verified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text('Verified'),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '  •  ${_fmtVnd(price)} đ/h',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // 🆕 Hàng thống kê số buổi & học viên
                      Row(
                        children: [
                          const Icon(Icons.menu_book_outlined,
                              size: 16, color: Colors.indigo),
                          const SizedBox(width: 4),
                          Text(
                            '$totalLessons buổi dạy',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.people_alt_outlined,
                              size: 16, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            '$totalStudents học viên',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.mail_outline,
                              color: Colors.grey[600], size: 18),
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

          // ===== Kinh nghiệm =====
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

          // ===== Lịch rảnh (Availability) =====
          if (availability.isNotEmpty)
            _Section(
              title: 'Thời gian rảnh',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, size: 18, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      availability,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else
            _Section(
              title: 'Thời gian rảnh',
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Gia sư chưa cập nhật lịch rảnh.'),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ===== Giới thiệu =====
          _Section(
            title: 'Giới thiệu',
            child: Text(
              bio.isEmpty ? 'Chưa có mô tả.' : bio,
              style: const TextStyle(height: 1.45),
            ),
          ),

          const SizedBox(height: 120),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
