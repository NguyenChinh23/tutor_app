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
      final auth = context.read<AppAuthProvider>();
      final user = auth.user;
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

    // ===== phân loại Sắp tới / Lịch sử =====
    final upcoming = bookings.where((b) {
      final isFuture = b.startAt.isAfter(now);
      final isWaiting = b.status == BookingStatus.requested ||
          b.status == BookingStatus.accepted;
      return isFuture && isWaiting;
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final history = bookings.where((b) => !upcoming.contains(b)).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));

    final dfDate = DateFormat('dd/MM/yyyy');
    final dfTime = DateFormat('HH:mm');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch học của tôi'),
          backgroundColor: primary,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
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
              child: Text('Chưa có buổi học sắp tới.'),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: upcoming.length,
              itemBuilder: (context, index) {
                final b = upcoming[index];
                return _LessonCard(
                  booking: b,
                  dfDate: dfDate,
                  dfTime: dfTime,
                  showRateButton: false,
                );
              },
            ),

            // ===== TAB LỊCH SỬ =====
            history.isEmpty
                ? const Center(
              child:
              Text('Chưa có buổi học nào trong lịch sử.'),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final b = history[index];

                // chỉ cho đánh giá nếu buổi học đã completed & chưa rating
                final isFinishedNotRated =
                    b.status == BookingStatus.completed &&
                        b.rating == null;

                return _LessonCard(
                  booking: b,
                  dfDate: dfDate,
                  dfTime: dfTime,
                  showRateButton: isFinishedNotRated,
                  onRate: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RateLessonScreen(booking: b),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
      case BookingStatus.requested:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case BookingStatus.requested:
        return 'Đang chờ gia sư';
      case BookingStatus.accepted:
        return 'Đã được xác nhận';
      case BookingStatus.completed:
        return 'Hoàn thành';
      case BookingStatus.rejected:
        return 'Bị từ chối';
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

    final hasCancelReason =
        booking.cancelReason != null &&
            booking.cancelReason!.trim().isNotEmpty;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Môn + ngày
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.subject.isEmpty
                      ? 'Buổi học'
                      : booking.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
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
          // Tutor
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
                  booking.tutorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Thời gian + trạng thái
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
                style: const TextStyle(fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                  _statusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(booking.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _statusColor(booking.status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Nếu bị huỷ và có lý do → hiện lý do
          if (booking.status == BookingStatus.cancelled &&
              hasCancelReason) ...[
            Text(
              'Lý do huỷ: ${booking.cancelReason}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Rating / nút đánh giá
          if (booking.rating != null) ...[
            Row(
              children: [
                const Icon(Icons.star,
                    size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  booking.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (booking.review != null &&
                booking.review!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"${booking.review}"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ] else if (showRateButton) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRate,
                icon: const Icon(Icons.rate_review_outlined,
                    size: 18),
                label: const Text('Đánh giá buổi học'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
