import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/tutor_model.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/provider/booking_provider.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(v);

ImageProvider? _buildTutorAvatar(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;

  try {
    if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    } else {
      final bytes = base64Decode(avatarUrl);
      return MemoryImage(bytes);
    }
  } catch (e) {
    debugPrint('Tutor avatar decode error (book screen): $e');
    return null;
  }
}

class BookLessonScreen extends StatefulWidget {
  final TutorModel tutor;

  const BookLessonScreen({super.key, required this.tutor});

  @override
  State<BookLessonScreen> createState() => _BookLessonScreenState();
}

class _BookLessonScreenState extends State<BookLessonScreen> {
  String? _selectedSubject;
  String _mode = 'online'; // online / offline_at_student / offline_at_tutor
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 19, minute: 0);
  int _durationMinutes = 60;
  final TextEditingController _noteCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.tutor.subject;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  double get hours => _durationMinutes / 60.0;

  double get totalPrice {
    final pricePerHour = widget.tutor.price;
    return pricePerHour * hours;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      locale: const Locale('vi', 'VN'),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
    }
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _start,
    );
    if (t != null) {
      setState(() => _start = t);
    }
  }

  Future<void> _createBooking() async {
    final auth = context.read<AppAuthProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final student = auth.user;

    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt lịch.')),
      );
      return;
    }

    DateTime combine(DateTime d, TimeOfDay t) =>
        DateTime(d.year, d.month, d.day, t.hour, t.minute);

    final startAt = combine(_selectedDate, _start);
    final endAt = startAt.add(Duration(minutes: _durationMinutes));

    if (!endAt.isAfter(startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời lượng không hợp lệ.')),
      );
      return;
    }

    final tutor = widget.tutor;

    setState(() => _saving = true);

    try {
      final booking = BookingModel(
        id: '',
        tutorId: tutor.uid,
        studentId: student.uid,
        tutorName: tutor.name,
        studentName: student.displayName ?? 'Student',
        subject: _selectedSubject ?? tutor.subject,
        pricePerHour: tutor.price,
        hours: hours,
        price: totalPrice, // totalPrice = pricePerHour * hours
        note: _noteCtrl.text.trim(),
        startAt: startAt,
        endAt: endAt,
        status: BookingStatus.requested,
        paid: false,
        paymentMethod: null,
        cancelReason: null,
        createdAt: DateTime.now(),
        updatedAt: null,
        mode: _mode,
      );

      await bookingProvider.createBooking(booking);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu. Chờ gia sư xác nhận.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo booking: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final tutor = widget.tutor;
    final df = DateFormat('EEE, dd/MM/yyyy', 'vi_VN');

    final avatarImage = _buildTutorAvatar(tutor.avatarUrl);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Đặt lịch học'),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header tutor summary + availability
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: primary.withOpacity(0.1),
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                          tutor.name.isNotEmpty
                              ? tutor.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tutor.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tutor.subject,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 3),
                                Text(
                                  tutor.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "${_fmtVnd(tutor.price)} / giờ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (tutor.availabilityNote.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: Colors.indigo,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Thời gian rảnh: ${tutor.availabilityNote}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Thông tin buổi học",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Môn học
            Text("Môn học",
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  items: [
                    DropdownMenuItem(
                      value: tutor.subject,
                      child: Text(tutor.subject),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedSubject = v),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hình thức
            Text("Hình thức học",
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'online',
                    groupValue: _mode,
                    onChanged: (v) =>
                        setState(() => _mode = v ?? 'online'),
                    title: const Text('Online (Google Meet / Zoom)'),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: 'offline_at_student',
                    groupValue: _mode,
                    onChanged: (v) => setState(
                            () => _mode = v ?? 'offline_at_student'),
                    title: const Text('Offline tại nhà học viên'),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: 'offline_at_tutor',
                    groupValue: _mode,
                    onChanged: (v) =>
                        setState(() => _mode = v ?? 'offline_at_tutor'),
                    title: const Text('Offline tại nhà gia sư'),
                    dense: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Thời gian
            Text("Thời gian",
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text("Ngày học"),
                    subtitle: Text(df.format(_selectedDate)),
                    trailing: TextButton(
                      onPressed: _pickDate,
                      child: const Text("Chọn ngày"),
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: const Text("Giờ bắt đầu"),
                    subtitle: Text(_start.format(context)),
                    trailing: TextButton(
                      onPressed: _pickStartTime,
                      child: const Text("Chọn giờ"),
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timelapse),
                    title: const Text("Thời lượng"),
                    subtitle: Text("$_durationMinutes phút"),
                    trailing: DropdownButton<int>(
                      value: _durationMinutes,
                      items: const [
                        DropdownMenuItem(
                            value: 60, child: Text("60 phút")),
                        DropdownMenuItem(
                            value: 90, child: Text("90 phút")),
                        DropdownMenuItem(
                            value: 120, child: Text("120 phút")),
                      ],
                      onChanged: (v) =>
                          setState(() => _durationMinutes = v ?? 60),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ghi chú
            Text("Ghi chú cho gia sư (tuỳ chọn)",
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Ôn lại chương 1, học qua Zoom...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tổng tiền
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      color: Colors.green),
                  const SizedBox(width: 10),
                  const Text(
                    "Tổng tiền:",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    _fmtVnd(totalPrice),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _createBooking,
                icon: const Icon(Icons.check_circle_outline),
                label: _saving
                    ? const Text("Đang tạo...")
                    : const Text(
                  "Xác nhận đặt lịch",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
