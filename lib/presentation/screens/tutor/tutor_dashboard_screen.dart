import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/screens/tutor/tutor_upcoming_lessons_screen.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(v);

/// Avatar: hỗ trợ http / base64 / fallback asset
ImageProvider _buildUserAvatar(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) {
    return const AssetImage('assets/tutor1.png');
  }
  try {
    if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    } else {
      return MemoryImage(base64Decode(avatarUrl));
    }
  } catch (_) {
    return const AssetImage('assets/tutor1.png');
  }
}

class TutorDashboardScreen extends StatelessWidget {
  const TutorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final primary = AppTheme.primaryColor;

    /// 🔥 Chỉ lấy booking ĐÃ ACCEPTED
    final upcomingStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'accepted')
        .orderBy('startAt')
        .snapshots();

    /// Rating tổng từ users/{uid}
    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Tutor Dashboard'),
        backgroundColor: primary,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER =====
            _Header(user: user),

            const SizedBox(height: 20),

            // ===== RATING CARD =====
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userDocStream,
              builder: (context, snap) {
                double rating = 0.0;
                int ratingCount = 0;

                if (snap.hasData && snap.data!.data() != null) {
                  final data = snap.data!.data()!;
                  rating =
                      (data['rating'] as num?)?.toDouble() ?? 0.0;
                  ratingCount =
                      (data['ratingCount'] as num?)?.toInt() ?? 0;
                }

                return _StatCard(
                  title: 'Đánh giá từ học viên',
                  value: rating.toStringAsFixed(1),
                  subtitle: ratingCount > 0
                      ? '$ratingCount lượt đánh giá'
                      : 'Chưa có đánh giá',
                  icon: Icons.star,
                  color: Colors.amber,
                );
              },
            ),

            const SizedBox(height: 24),

            // ===== BUỔI HỌC SẮP TỚI =====
            Row(
              children: [
                const Text(
                  'Buổi học sắp tới',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TutorUpcomingLessonsScreen(tutorId: user.uid),
                      ),
                    );
                  },
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: upcomingStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final now = DateTime.now();
                final docs = snapshot.data!.docs.where((doc) {
                  final start =
                  (doc['startAt'] as Timestamp).toDate();
                  return start.isAfter(now);
                }).take(3).toList();

                if (docs.isEmpty) {
                  return _EmptyBox('Chưa có buổi học sắp tới.');
                }

                final dfDate = DateFormat('dd/MM/yyyy');
                final dfTime = DateFormat('HH:mm');

                return Column(
                  children: docs.map((doc) {
                    final d = doc.data();
                    final start =
                    (d['startAt'] as Timestamp).toDate();
                    final end =
                    (d['endAt'] as Timestamp).toDate();

                    return _LessonPreview(
                      subject: d['subject'] ?? 'Môn học',
                      studentName:
                      d['studentName'] ?? 'Học viên',
                      date: dfDate.format(start),
                      time:
                      '${dfTime.format(start)} - ${dfTime.format(end)}',
                      price: _fmtVnd(d['price'] ?? 0),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= UI COMPONENTS ================= */

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: _buildUserAvatar(user.avatarUrl),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Tutor',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonPreview extends StatelessWidget {
  const _LessonPreview({
    required this.subject,
    required this.studentName,
    required this.date,
    required this.time,
    required this.price,
  });

  final String subject;
  final String studentName;
  final String date;
  final String time;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject,
              style:
              const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(studentName,
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('$date • $time',
                  style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[700]),
      ),
    );
  }
}
