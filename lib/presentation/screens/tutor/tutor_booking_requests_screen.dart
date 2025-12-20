import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/provider/booking_provider.dart';

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
      final user = context.read<AppAuthProvider>().user;
      if (user != null) {
        context.read<BookingProvider>().listenForTutor(user.uid);
        _initialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final bookingProvider = context.watch<BookingProvider>();

    // 👉 TẤT CẢ booking đã auto accepted
    final bookings = bookingProvider.tutorBookings
        .where((b) => b.status == BookingStatus.accepted)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final dfDate = DateFormat('dd/MM/yyyy');
    final dfTime = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch học mới'),
        backgroundColor: primary,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: bookings.isEmpty
          ? Center(
        child: Text(
          'Chưa có lịch học mới.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final b = bookings[index];

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
                // ===== STUDENT + SUBJECT =====
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Học viên: ${b.studentName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      b.subject,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // ===== PACKAGE INFO =====
                if (b.isPackage) ...[
                  Text(
                    'Gói học: ${b.totalSessions} buổi',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tiến độ: ${b.completedSessions} / ${b.totalSessions}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: b.completedSessions / b.totalSessions,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    color: primary,
                  ),
                  const SizedBox(height: 6),
                ],

                // ===== TIME =====
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

                const SizedBox(height: 6),

                // ===== PRICE =====
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(b.price)}',
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
              ],
            ),
          );
        },
      ),
    );
  }
}
