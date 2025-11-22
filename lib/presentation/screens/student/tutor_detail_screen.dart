import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/tutor_model.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(v);

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// build avatar cho tutor: hỗ trợ http + base64 + fallback null
ImageProvider? _buildTutorAvatar(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;

  try {
    if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    } else {
      // base64
      final bytes = base64Decode(avatarUrl);
      return MemoryImage(bytes);
    }
  } catch (e) {
    debugPrint('Tutor avatar decode error: $e');
    return null;
  }
}

class TutorDetailScreen extends StatefulWidget {
  const TutorDetailScreen({
    super.key,
    required this.tutor,
    this.autoOpenBook = false,
  });

  final TutorModel tutor;
  final bool autoOpenBook;

  @override
  State<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 21, minute: 0);
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoOpenBook) _openBookingSheet();
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final tutor = widget.tutor;

    final name = tutor.name;
    final subject = tutor.subject;
    final price = tutor.price;
    final rating = tutor.rating;
    final avatarUrl = tutor.avatarUrl;
    final bio = tutor.bio;
    final experience = tutor.experience;
    final verified = tutor.isTutorVerified;
    final email = tutor.email;

    final avatarImage = _buildTutorAvatar(avatarUrl);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Thông tin gia sư'),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.06), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Mở chat (demo)')));
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _creating ? null : _openBookingSheet,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: _creating
                      ? const Text('Đang tạo...')
                      : const Text('Book'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Header Card ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: primary.withOpacity(0.08),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                    _initials(name),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (verified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified, size: 16, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text('Verified'),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subject, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('  •  ${_fmtVnd(price)} đ/h',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.mail_outline, color: Colors.grey[600], size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email.isEmpty ? 'Không có email' : email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _Section(
            title: 'Kinh nghiệm',
            child: Row(
              children: [
                Icon(Icons.workspace_premium_outlined, size: 18, color: Colors.grey[800]),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    experience.isEmpty ? 'Chưa cập nhật' : experience,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _Section(
            title: 'Giới thiệu',
            child: Text(
              bio.isEmpty ? 'Chưa có mô tả.' : bio,
              style: const TextStyle(height: 1.45),
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ================= BOOKING SHEET =================

  Future<void> _openBookingSheet() async {
    final df = DateFormat('EEE, dd/MM/yyyy', 'vi_VN');
    final primary = AppTheme.primaryColor;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                    ),
                    Text('Đặt lịch với ${widget.tutor.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 12),

                    // Chọn ngày
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: const Text('Ngày học'),
                      subtitle: Text(df.format(_selectedDate)),
                      trailing: TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 180)),
                            locale: const Locale('vi', 'VN'),
                          );
                          if (d != null) setSheet(() => _selectedDate = d);
                        },
                        child: const Text('Chọn ngày'),
                      ),
                    ),

                    // Giờ bắt đầu
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: const Text('Giờ bắt đầu'),
                      subtitle: Text(_start.format(ctx)),
                      trailing: TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: _start);
                          if (t != null) setSheet(() => _start = t);
                        },
                        child: const Text('Chọn giờ'),
                      ),
                    ),

                    // Giờ kết thúc
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Giờ kết thúc'),
                      subtitle: Text(_end.format(ctx)),
                      trailing: TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: _end);
                          if (t != null) setSheet(() => _end = t);
                        },
                        child: const Text('Chọn giờ'),
                      ),
                    ),

                    // Ghi chú
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú cho gia sư (tuỳ chọn)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nút gửi yêu cầu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _creating
                            ? null
                            : () async {
                          Navigator.of(ctx).pop();
                          await _createBooking();
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Gửi yêu cầu đặt lịch'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ================= FIRESTORE CREATE BOOKING =================

  Future<void> _createBooking() async {
    final auth = context.read<AppAuthProvider>();
    final student = auth.user;

    if (student == null || student.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt lịch.')),
      );
      return;
    }

    DateTime _combine(DateTime d, TimeOfDay t) =>
        DateTime(d.year, d.month, d.day, t.hour, t.minute);

    final startAt = _combine(_selectedDate, _start);
    final endAt = _combine(_selectedDate, _end);

    if (!endAt.isAfter(startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu.')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'tutorId': widget.tutor.uid,
        'studentId': student.uid,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'subject': widget.tutor.subject,
        'price': widget.tutor.price,
        'note': _noteCtrl.text.trim(),
        'status': 'requested',
        'paid': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu. Chờ gia sư xác nhận.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi tạo booking: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
