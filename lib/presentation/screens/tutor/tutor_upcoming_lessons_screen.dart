import 'package:cloud_firestore/cloud_firestore.dart';
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

class TutorUpcomingLessonsScreen extends StatelessWidget {
  const TutorUpcomingLessonsScreen({
    super.key,
    required this.tutorId,
  });

  final String tutorId;

  // ----- BẤM HOÀN THÀNH -----
  Future<void> _markCompleted(
      BuildContext context,
      BookingModel booking,
      ) async {
    final bookingProvider = context.read<BookingProvider>();
    final notif = context.read<NotificationProvider>();

    // ⭐ GỌI PROVIDER:
    //   - update status = completed
    //   - tăng totalLessons + totalStudents cho gia sư (trong BookingProvider / Repository)
    await bookingProvider.tutorCompleteBooking(booking);

    // Gửi thông báo cho học viên
    await notif.createLessonCompletedNotification(booking: booking);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu buổi học hoàn thành')),
    );
  }

  // ----- BẤM HỦY BUỔI -----
  Future<void> _cancelLesson(
      BuildContext context,
      BookingModel booking,
      ) async {
    final reasonCtrl = TextEditingController();
    final primary = AppTheme.primaryColor;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Huỷ buổi học'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
            ),
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

    // Gửi thông báo huỷ cho học viên
    await notif.createLessonCancelledNotification(
      booking: booking,
      reason: reason.isEmpty ? null : reason,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Buổi học đã được huỷ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final dfDate = DateFormat('dd/MM/yyyy');
    final dfTime = DateFormat('HH:mm');

    // 🔥 lấy TẤT CẢ buổi status = "accepted" của tutor
    final stream = FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: tutorId)
        .where('status', isEqualTo: 'accepted')
        .orderBy('startAt')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch dạy của bạn'),
        backgroundColor: primary,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi khi tải dữ liệu: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Hiện chưa có buổi học nào.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            );
          }

          final now = DateTime.now();
          final bookings = docs
              .map((d) => BookingModel.fromDoc(d))
              .toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              final start = booking.startAt;
              final end = booking.endAt;
              final subject = booking.subject;
              final studentName = booking.studentName;
              final total = booking.price;

              final hasStarted = start.isBefore(now);
              final hasEnded = end.isBefore(now);

              final canCancel = !hasStarted;      // chưa bắt đầu -> huỷ được
              final canMarkCompleted = hasEnded;  // đã kết thúc -> hoàn thành được

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
                            subject.isEmpty ? 'Môn học' : subject,
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

                    // Tên học viên
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
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Thời gian + tiền
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
                        Text(
                          _fmtVnd(total),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ===== Nút hành động =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (canCancel)
                          TextButton.icon(
                            onPressed: () =>
                                _cancelLesson(context, booking),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Huỷ buổi học',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        if (canMarkCompleted)
                          TextButton.icon(
                            onPressed: () =>
                                _markCompleted(context, booking),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: const Text('Đánh dấu đã dạy xong'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
