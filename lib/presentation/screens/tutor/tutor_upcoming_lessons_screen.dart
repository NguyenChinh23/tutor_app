import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/presentation/provider/booking_provider.dart';
import 'package:tutor_app/presentation/provider/notification_provider.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(v);

class TutorUpcomingLessonsScreen extends StatefulWidget {
  const TutorUpcomingLessonsScreen({
    super.key,
    required this.tutorId,
  });

  final String tutorId;

  @override
  State<TutorUpcomingLessonsScreen> createState() =>
      _TutorUpcomingLessonsScreenState();
}

class _TutorUpcomingLessonsScreenState
    extends State<TutorUpcomingLessonsScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      context.read<BookingProvider>().listenForTutor(widget.tutorId);
      _initialized = true;
    }
  }

  // ===== HOÀN THÀNH 1 BUỔI =====
  Future<void> _completeSession(
      BuildContext context,
      BookingModel booking,
      ) async {
    final bookingProvider = context.read<BookingProvider>();
    final notif = context.read<NotificationProvider>();

    await bookingProvider.tutorCompleteSession(booking);
    await notif.createLessonCompletedNotification(booking: booking);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hoàn thành 1 buổi học')),
    );
  }

  // ===== HUỶ BOOKING =====
  Future<void> _cancelBooking(
      BuildContext context,
      BookingModel booking,
      ) async {
    final reasonCtrl = TextEditingController();
    final primary = AppTheme.primaryColor;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Huỷ lịch dạy'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do huỷ (tuỳ chọn)',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận huỷ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final bookingProvider = context.read<BookingProvider>();
    final notif = context.read<NotificationProvider>();
    final reason = reasonCtrl.text.trim();

    await bookingProvider.tutorCancelBooking(
      booking,
      reason: reason.isEmpty ? null : reason,
    );

    await notif.createLessonCancelledNotification(
      booking: booking,
      reason: reason.isEmpty ? null : reason,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã huỷ lịch dạy')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final dfDate = DateFormat('dd/MM/yyyy');
    final dfTime = DateFormat('HH:mm');

    final bookingProvider = context.watch<BookingProvider>();

    // ✅ CHỈ LẤY BOOKING ĐANG DẠY
    final bookings = bookingProvider.tutorBookings
        .where((b) => b.status == BookingStatus.accepted)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch dạy của bạn'),
        backgroundColor: primary,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: bookingProvider.loadingTutor
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
          ? Center(
        child: Text(
          'Hiện chưa có lịch dạy nào.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final start = booking.startAt;
          final end = booking.endAt;

          final now = DateTime.now();
          final canCancel = start.isAfter(now);
          final canCompleteSession =
              end.isBefore(now) &&
                  booking.completedSessions < booking.totalSessions;

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
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      dfDate.format(start),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ===== STUDENT =====
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ===== TIME + PRICE =====
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.indigo),
                    const SizedBox(width: 4),
                    Text(
                      '${dfTime.format(start)} - ${dfTime.format(end)}',
                    ),
                    const Spacer(),
                    Text(
                      _fmtVnd(booking.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                // ===== GÓI HỌC (TIẾN ĐỘ) =====
                if (booking.isPackage) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tiến độ: ${booking.completedSessions} / ${booking.totalSessions} buổi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: booking.completedSessions /
                        booking.totalSessions,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    color: primary,
                  ),
                ],

                const SizedBox(height: 8),

                // ===== ACTIONS =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canCancel)
                      TextButton.icon(
                        onPressed: () =>
                            _cancelBooking(context, booking),
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.red),
                        label: const Text(
                          'Huỷ',
                          style:
                          TextStyle(color: Colors.red),
                        ),
                      ),
                    if (canCompleteSession)
                      TextButton.icon(
                        onPressed: () =>
                            _completeSession(context, booking),
                        icon: const Icon(
                            Icons.check_circle_outline),
                        label:
                        const Text('Hoàn thành buổi'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
