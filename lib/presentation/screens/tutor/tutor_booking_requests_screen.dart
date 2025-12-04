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

  /// Những group đã xử lý (accepted / rejected) => ẩn khỏi UI ngay
  final Set<String> _hiddenGroupIds = {};

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

    // ====== Tất cả booking status=requested ======
    final allRequests = booking.tutorBookings
        .where((b) => b.status == BookingStatus.requested)
        .toList();

    // ====== GROUP THEO packageId (nếu null thì mỗi booking là 1 group) ======
    final Map<String, List<BookingModel>> grouped = {};
    for (final b in allRequests) {
      final key =
      (b.packageId == null || b.packageId!.isEmpty) ? b.id : b.packageId!;
      grouped.putIfAbsent(key, () => []).add(b);
    }

    // Lọc bỏ các group đã xử lý (đã ẩn)
    final groups = grouped.entries
        .where((e) => !_hiddenGroupIds.contains(e.key))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu đặt lịch'),
        backgroundColor: primary,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: groups.isEmpty
          ? Center(
        child: Text(
          'Hiện chưa có yêu cầu đặt lịch nào.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final entry = groups[index];
          final groupId = entry.key;        // 👈 dùng để ẩn group
          final sessions = entry.value;

          // Buổi đầu để hiển thị
          final first = sessions.first;

          final bool isPackage =
              (first.packageId != null && first.packageId!.isNotEmpty) &&
                  sessions.length > 1;

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
                        'Học viên: ${first.studentName.isNotEmpty ? first.studentName : first.studentId.substring(0, 6) + '...'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      first.subject.isEmpty ? 'Môn học' : first.subject,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                if (isPackage)
                  Text(
                    'Gói ~ ${sessions.length} buổi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),

                const SizedBox(height: 6),

                // Dòng 2: Ngày + khung giờ của buổi đầu
                Row(
                  children: [
                    const Icon(Icons.event,
                        size: 16, color: Colors.indigo),
                    const SizedBox(width: 4),
                    Text(
                      dfDate.format(first.startAt),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.schedule,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${dfTime.format(first.startAt)} - ${dfTime.format(first.endAt)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Dòng 3: Tiền buổi đầu
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      isPackage
                          ? 'Dự kiến: ${_fmtVnd(first.price)} / buổi'
                          : 'Dự kiến: ${_fmtVnd(first.price)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                if (first.note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ghi chú: ${first.note}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                Row(
                  children: [
                    // ❌ TỪ CHỐI (buổi lẻ hoặc cả gói)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.redAccent),
                        ),
                        onPressed: () async {
                          if (isPackage &&
                              first.packageId != null &&
                              first.packageId!.isNotEmpty) {
                            await booking.updateBookingStatusGroup(
                              first.packageId!,
                              BookingStatus.rejected,
                            );
                          } else {
                            await booking.updateBookingStatus(
                              first.id,
                              BookingStatus.rejected,
                            );
                          }

                          // Ẩn group khỏi UI ngay
                          setState(() {
                            _hiddenGroupIds.add(groupId);
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isPackage
                                      ? 'Đã từ chối yêu cầu gói.'
                                      : 'Đã từ chối yêu cầu.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.close,
                            color: Colors.redAccent, size: 18),
                        label: const Text(
                          'Từ chối',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ✅ CHẤP NHẬN (buổi lẻ hoặc cả gói)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          // 1. Update trạng thái
                          if (isPackage &&
                              first.packageId != null &&
                              first.packageId!.isNotEmpty) {
                            await booking.updateBookingStatusGroup(
                              first.packageId!,
                              BookingStatus.accepted,
                            );
                          } else {
                            await booking.updateBookingStatus(
                              first.id,
                              BookingStatus.accepted,
                            );
                          }

                          // Ẩn group khỏi UI ngay
                          setState(() {
                            _hiddenGroupIds.add(groupId);
                          });

                          // 2. Gửi thông báo cho học viên
                          final notif =
                          context.read<NotificationProvider>();
                          final tutorName =
                              user.displayName ?? 'Gia sư';

                          await notif.createBookingAcceptedNotification(
                            studentId: first.studentId,
                            tutorName: tutorName,
                            subject: first.subject,
                            startAt: first.startAt,
                            bookingId: isPackage ? null : first.id,
                            packageId:
                            isPackage ? first.packageId : null,
                            isPackage: isPackage,
                            totalSessions:
                            isPackage ? sessions.length : null,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isPackage
                                      ? 'Đã chấp nhận yêu cầu gói học.'
                                      : 'Đã chấp nhận yêu cầu đặt lịch.',
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