import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/provider/booking_provider.dart';
import 'package:tutor_app/presentation/screens/student/rate_lesson_screen.dart';

class StudentMyLessonsScreen extends StatefulWidget {
  const StudentMyLessonsScreen({super.key});

  @override
  State<StudentMyLessonsScreen> createState() =>
      _StudentMyLessonsScreenState();
}

class _StudentMyLessonsScreenState extends State<StudentMyLessonsScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AppAuthProvider>().user;
      if (user != null) {
        context.read<BookingProvider>().listenForStudent(user.uid);
        _initialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final bookingProvider = context.watch<BookingProvider>();
    final bookings = bookingProvider.studentBookings;
    final now = DateTime.now();

    // ===== PHÂN LOẠI ĐÚNG NGHIỆP VỤ =====

    // 🔹 SẮP TỚI: chưa học buổi nào + còn trong tương lai
    final upcoming = bookings.where((b) {
      return b.status == BookingStatus.accepted &&
          b.completedSessions == 0 &&
          b.startAt.isAfter(now);
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    // 🔹 LỊCH SỬ: đã học >=1 buổi HOẶC đã completed / cancelled
    final history = bookings.where((b) {
      return b.completedSessions > 0 ||
          b.status == BookingStatus.completed ||
          b.status == BookingStatus.cancelled;
    }).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));

    final dfDate = DateFormat('dd/MM/yyyy');
    final dfTime = DateFormat('HH:mm');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch học của tôi'),
          backgroundColor: primary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sắp tới'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ===== TAB SẮP TỚI =====
            upcoming.isEmpty
                ? const Center(
              child: Text('Chưa có lịch học sắp tới.'),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: upcoming.length,
              itemBuilder: (_, i) => _LessonCard(
                booking: upcoming[i],
                dfDate: dfDate,
                dfTime: dfTime,
                showRateButton: false,
              ),
            ),

            // ===== TAB LỊCH SỬ =====
            history.isEmpty
                ? const Center(
              child: Text('Chưa có lịch sử học.'),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (_, i) {
                final b = history[i];
                final canRate =
                    b.status == BookingStatus.completed &&
                        b.rating == null;

                return _LessonCard(
                  booking: b,
                  dfDate: dfDate,
                  dfTime: dfTime,
                  showRateButton: canRate,
                  onRate: canRate
                      ? () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RateLessonScreen(booking: b),
                      ),
                    );
                  }
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// ========================== LESSON CARD ================================
// ======================================================================

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.booking,
    required this.dfDate,
    required this.dfTime,
    this.showRateButton = false,
    this.onRate,
  });

  final BookingModel booking;
  final DateFormat dfDate;
  final DateFormat dfTime;
  final bool showRateButton;
  final VoidCallback? onRate;

  Color _statusColor(String status) {
    switch (status) {
      case BookingStatus.accepted:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case BookingStatus.accepted:
        return booking.completedSessions > 0
            ? 'Đang học'
            : 'Sắp học';
      case BookingStatus.completed:
        return 'Hoàn thành';
      case BookingStatus.cancelled:
        return 'Đã huỷ';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = booking.startAt;
    final end = booking.endAt;

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
          // ===== SUBJECT + DATE =====
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(dfDate.format(start)),
            ],
          ),

          const SizedBox(height: 4),

          // ===== TUTOR =====
          Text(
            booking.tutorName,
            style: const TextStyle(fontSize: 13),
          ),

          const SizedBox(height: 4),

          // ===== TIME + STATUS =====
          Row(
            children: [
              Text(
                '${dfTime.format(start)} - ${dfTime.format(end)}',
                style: const TextStyle(fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(booking.status),
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor(booking.status),
                  ),
                ),
              ),
            ],
          ),

          // ===== PACKAGE PROGRESS =====
          if (booking.isPackage) ...[
            const SizedBox(height: 6),
            Text(
              'Tiến độ: ${booking.completedSessions} / ${booking.totalSessions} buổi',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: booking.completedSessions / booking.totalSessions,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.primaryColor,
            ),
          ],

          // ===== RATING =====
          if (booking.rating != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star,
                    size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(booking.rating!.toStringAsFixed(1)),
              ],
            ),
          ] else if (showRateButton) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRate,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Đánh giá'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
