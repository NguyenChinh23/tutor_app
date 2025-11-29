import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tutor_app/config/theme.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(v);

class TutorUpcomingLessonsScreen extends StatelessWidget {
  const TutorUpcomingLessonsScreen({
    super.key,
    required this.tutorId,
  });

  final String tutorId;

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final dfDate = DateFormat('dd/MM/yyyy');
    final dfTime = DateFormat('HH:mm');

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
          final now = DateTime.now();

          // chỉ lấy buổi ở tương lai
          final upcomingDocs = docs.where((doc) {
            final start =
            (doc.data()['startAt'] as Timestamp).toDate();
            return !start.isBefore(now);
          }).toList();

          if (upcomingDocs.isEmpty) {
            return Center(
              child: Text(
                'Hiện chưa có buổi học nào sắp tới.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcomingDocs.length,
            itemBuilder: (context, index) {
              final doc = upcomingDocs[index];
              final data = doc.data();
              final start =
              (data['startAt'] as Timestamp).toDate();
              final end =
              (data['endAt'] as Timestamp).toDate();
              final subject =
              (data['subject'] ?? '').toString();
              final studentName =
              (data['studentName'] ?? 'Học viên').toString();

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
