import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/provider/booking_provider.dart';
import 'package:tutor_app/presentation/provider/notification_provider.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(v);

class TutorBookingRequestsScreen extends StatefulWidget {
  const TutorBookingRequestsScreen({super.key});

  @override
  State<TutorBookingRequestsScreen> createState() =>
      _TutorBookingRequestsScreenState();
}

class _TutorBookingRequestsScreenState
    extends State<TutorBookingRequestsScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = context.read<AppAuthProvider>();
      final booking = context.read<BookingProvider>();
      final user = auth.user;
      if (user != null) {
        booking.listenForTutor(user.uid);
        _initialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final booking = context.watch<BookingProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final primary = AppTheme.primaryColor;
    final dfDate = DateFormat('dd/MM/yyyy');
    final dfTime = DateFormat('HH:mm');

    final requests = booking.tutorBookings
        .where((b) => b.status == BookingStatus.requested)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu đặt lịch'),
        backgroundColor: primary,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: requests.isEmpty
          ? Center(
        child: Text(
          'Hiện chưa có yêu cầu đặt lịch nào.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final b = requests[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dòng 1: Học viên + môn
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Học viên: ${b.studentId.substring(0, 6)}...',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      b.subject.isEmpty ? 'Môn học' : b.subject,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Dòng 2: Ngày + khung giờ
                Row(
                  children: [
                    const Icon(Icons.event,
                        size: 16, color: Colors.indigo),
                    const SizedBox(width: 4),
                    Text(
                      dfDate.format(b.startAt),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.schedule,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${dfTime.format(b.startAt)} - ${dfTime.format(b.endAt)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Dòng 3: Tiền
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Dự kiến: ${_fmtVnd(b.price)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                if (b.note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ghi chú: ${b.note}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                Row(
                  children: [
                    // ❌ TỪ CHỐI
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.redAccent),
                        ),
                        onPressed: () async {
                          await booking.updateStatus(
                            bookingId: b.id,
                            status: BookingStatus.rejected,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content:
                                Text('Đã từ chối yêu cầu.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.close,
                            color: Colors.redAccent, size: 18),
                        label: const Text(
                          'Từ chối',
                          style: TextStyle(
                              color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ✅ CHẤP NHẬN
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          // 1. Cập nhật trạng thái booking
                          await booking.updateStatus(
                            bookingId: b.id,
                            status: BookingStatus.accepted,
                          );

                          // 2. Tạo thông báo cho học viên
                          final notif = context
                              .read<NotificationProvider>();
                          final tutorName =
                              user.displayName ?? 'Gia sư';

                          await notif
                              .createBookingAcceptedNotification(
                            studentId: b.studentId,
                            tutorName: tutorName,
                            bookingId: b.id,
                            subject: b.subject,
                            startAt: b.startAt,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã chấp nhận yêu cầu đặt lịch.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check,
                            color: Colors.white, size: 18),
                        label: const Text(
                          'Chấp nhận',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
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
