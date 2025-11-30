import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/screens/tutor/tutor_booking_requests_screen.dart';
import 'package:tutor_app/presentation/screens/tutor/tutor_upcoming_lessons_screen.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(v);

/// Build avatar cho user: hỗ trợ http + base64 + fallback asset
ImageProvider _buildUserAvatar(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) {
    return const AssetImage('assets/tutor1.png');
  }

  try {
    if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    } else {
      // base64
      final bytes = base64Decode(avatarUrl);
      return MemoryImage(bytes);
    }
  } catch (e) {
    debugPrint('Dashboard avatar decode error: $e');
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

    // Stream: các booking đang chờ
    final pendingStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'requested')
        .snapshots();

    // Stream: TẤT CẢ buổi học đã accepted, order theo thời gian
    final upcomingStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'accepted')
        .orderBy('startAt')
        .snapshots();

    // Stream: user doc để lấy rating, ratingCount
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
            // ====== HEADER: Thông tin gia sư ======
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.isTutorVerified
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.isTutorVerified
                                    ? Icons.verified
                                    : Icons.hourglass_top,
                                size: 16,
                                color: user.isTutorVerified
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.isTutorVerified
                                    ? 'Verified Tutor'
                                    : 'Đang chờ duyệt',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: user.isTutorVerified
                                      ? Colors.green
                                      : Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== HÀNG THỐNG KÊ NHANH ======
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: pendingStream,
              builder: (context, snapPending) {
                final pendingCount =
                snapPending.hasData ? snapPending.data!.docs.length : 0;

                return Row(
                  children: [
                    // Card: yêu cầu chờ
                    Expanded(
                      child: _StatCard(
                        title: 'Yêu cầu chờ',
                        value: pendingCount.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const TutorBookingRequestsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card: Rating (lấy realtime từ users/{uid})
                    Expanded(
                      child: StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: userDocStream,
                        builder: (context, snapUserDoc) {
                          double rating = 0.0;
                          int ratingCount = 0;

                          if (snapUserDoc.hasData &&
                              snapUserDoc.data!.data() != null) {
                            final data = snapUserDoc.data!.data()!;
                            rating =
                                (data['rating'] as num?)?.toDouble() ?? 0.0;
                            ratingCount =
                                (data['ratingCount'] as num?)?.toInt() ?? 0;
                          }

                          // value hiển thị: "4.8" hoặc "0.0"
                          final valueText = rating.toStringAsFixed(1);

                          return _StatCard(
                            title: ratingCount > 0
                                ? 'Rating ($ratingCount đánh giá)'
                                : 'Rating',
                            value: valueText,
                            icon: Icons.star,
                            color:
                            Colors.amber[700] ?? Colors.amber,
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 22),

            // ====== DANH SÁCH BUỔI HỌC SẮP TỚI (preview 3 buổi) ======
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
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Lỗi khi tải dữ liệu: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final now = DateTime.now();

                // Lọc chỉ những buổi ở TƯƠNG LAI
                final upcomingDocs = docs.where((doc) {
                  final start =
                  (doc.data()['startAt'] as Timestamp).toDate();
                  return !start.isBefore(now);
                }).toList();

                if (upcomingDocs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Chưa có buổi học nào sắp diễn ra.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  );
                }

                final dfDate = DateFormat('dd/MM/yyyy');
                final dfTime = DateFormat('HH:mm');

                // Chỉ hiển thị TỐI ĐA 3 buổi trên Dashboard
                final preview = upcomingDocs.take(3).toList();

                return Column(
                  children: preview.map((doc) {
                    final data = doc.data();
                    final start =
                    (data['startAt'] as Timestamp).toDate();
                    final end =
                    (data['endAt'] as Timestamp).toDate();
                    final subject =
                    (data['subject'] ?? '').toString();
                    final studentName =
                    (data['studentName'] ?? 'Học viên')
                        .toString();

                    final rawTotal =
                        data['totalPrice'] ?? data['price'] ?? 0;
                    double total;
                    if (rawTotal is int) {
                      total = rawTotal.toDouble();
                    } else if (rawTotal is num) {
                      total = rawTotal.toDouble();
                    } else {
                      total = 0;
                    }

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
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subject.isEmpty
                                      ? 'Môn học'
                                      : subject,
                                  style: const TextStyle(
                                    fontWeight:
                                    FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                dfDate.format(start),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  studentName,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${dfTime.format(start)} - ${dfTime.format(end)}',
                                style: const TextStyle(
                                    fontSize: 13),
                              ),
                              const Spacer(),
                              Text(
                                _fmtVnd(total),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // ====== BUTTON XEM YÊU CẦU ĐẶT LỊCH ======
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                      color: primary.withOpacity(0.7)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const TutorBookingRequestsScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.pending_actions,
                    color: primary),
                label: Text(
                  'Xem tất cả yêu cầu đặt lịch',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
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

/// ====== Card thống kê nhỏ trên Dashboard ======
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
