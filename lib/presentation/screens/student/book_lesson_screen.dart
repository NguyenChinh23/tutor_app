import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/tutor_model.dart';
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
  String _mode = 'online';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 19, minute: 0);
  int _durationMinutes = 60;
  final TextEditingController _noteCtrl = TextEditingController();

  /// 'single' | '1m' | '3m' | '6m'
  String _packageType = 'single';

  /// Các thứ trong tuần được chọn (1=Mon ... 7=Sun)
  List<int> _selectedWeekdays = [DateTime.monday];

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

  int get _weeks {
    switch (_packageType) {
      case '1m':
        return 4;
      case '3m':
        return 12;
      case '6m':
        return 24;
      default:
        return 0;
    }
  }

  int get _estimatedTotalSessions {
    if (_packageType == 'single') return 1;
    if (_weeks == 0 || _selectedWeekdays.isEmpty) return 0;
    return _weeks * _selectedWeekdays.length;
  }

  double get _singlePrice => widget.tutor.price * hours;

  double get _packageTotalPrice {
    if (_packageType == 'single') return _singlePrice;

    double discount;
    switch (_packageType) {
      case '1m':
        discount = 0.05;
        break;
      case '3m':
        discount = 0.1;
        break;
      case '6m':
        discount = 0.15;
        break;
      default:
        discount = 0.0;
    }
    final raw = _singlePrice * _estimatedTotalSessions;
    return raw * (1 - discount);
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

  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<void> _submit() async {
    final auth = context.read<AppAuthProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final student = auth.user;

    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt lịch.')),
      );
      return;
    }

    final tutor = widget.tutor;

    // Gói tháng thì bắt buộc chọn ít nhất 1 ngày trong tuần
    if (_packageType != 'single' && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy chọn ít nhất một ngày học trong tuần.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final startAt = _combine(_selectedDate, _start);
      final endAt = startAt.add(Duration(minutes: _durationMinutes));

      if (!endAt.isAfter(startAt)) {
        throw Exception('Thời lượng không hợp lệ');
      }

      if (_packageType == 'single') {
        // 🔹 1 BUỔI LẺ
        await bookingProvider.createSingleBooking(
          tutorId: tutor.uid,
          tutorName: tutor.name,
          studentId: student.uid,
          studentName: student.displayName ?? 'Student',
          subject: _selectedSubject ?? tutor.subject,
          pricePerHour: tutor.price,
          hours: hours,
          startAt: startAt,
          endAt: endAt,
          note: _noteCtrl.text.trim(),
          mode: _mode,
        );
      } else {
        // 🔹 GÓI NHIỀU BUỔI – BookingProvider tự tạo packageId
        await bookingProvider.createPackageBookings(
          tutorId: tutor.uid,
          tutorName: tutor.name,
          studentId: student.uid,
          studentName: student.displayName ?? 'Student',
          subject: _selectedSubject ?? tutor.subject,
          pricePerHour: tutor.price,
          hours: hours,
          startDate: _selectedDate,
          timeStart: _start,
          timeEnd: TimeOfDay(hour: endAt.hour, minute: endAt.minute),
          packageType: _packageType,
          weekdays: _selectedWeekdays,
          note: _noteCtrl.text.trim(),
          mode: _mode,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _packageType == 'single'
                ? 'Đã gửi yêu cầu. Chờ gia sư xác nhận.'
                : 'Đã tạo yêu cầu gói học. Chờ gia sư xác nhận.',
          ),
        ),
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

  Widget _weekdayChip(String label, int weekday) {
    final isSelected = _selectedWeekdays.contains(weekday);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedWeekdays.remove(weekday);
          } else {
            _selectedWeekdays.add(weekday);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 6, bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
            isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
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
            // ===== Header tutor =====
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
                              style:
                              const TextStyle(color: Colors.grey),
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Thông tin buổi học / gói học",
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Môn học
            Text("Môn học",
                style: TextStyle(
                    color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: Colors.grey.shade300),
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
                  onChanged: (v) =>
                      setState(() => _selectedSubject = v),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Loại đặt lịch
            Text("Loại đặt lịch",
                style: TextStyle(
                    color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<String>(
                    value: 'single',
                    groupValue: _packageType,
                    onChanged: (v) =>
                        setState(() => _packageType = v ?? 'single'),
                    title: const Text('1 buổi lẻ'),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: '1m',
                    groupValue: _packageType,
                    onChanged: (v) =>
                        setState(() => _packageType = v ?? '1m'),
                    title: const Text('Gói 1 tháng'),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: '3m',
                    groupValue: _packageType,
                    onChanged: (v) =>
                        setState(() => _packageType = v ?? '3m'),
                    title: const Text('Gói 3 tháng'),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: '6m',
                    groupValue: _packageType,
                    onChanged: (v) =>
                        setState(() => _packageType = v ?? '6m'),
                    title: const Text('Gói 6 tháng'),
                    dense: true,
                  ),

                  if (_packageType != 'single') ...[
                    const Divider(),
                    const Text(
                      'Chọn các ngày học trong tuần:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      children: [
                        _weekdayChip('T2', DateTime.monday),
                        _weekdayChip('T3', DateTime.tuesday),
                        _weekdayChip('T4', DateTime.wednesday),
                        _weekdayChip('T5', DateTime.thursday),
                        _weekdayChip('T6', DateTime.friday),
                        _weekdayChip('T7', DateTime.saturday),
                        _weekdayChip('CN', DateTime.sunday),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ước tính ~ $_estimatedTotalSessions buổi',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Hình thức
            Text("Hình thức học",
                style: TextStyle(
                    color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'online',
                    groupValue: _mode,
                    onChanged: (v) =>
                        setState(() => _mode = v ?? 'online'),
                    title: const Text(
                        'Online (Google Meet / Zoom)'),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: 'offline_at_student',
                    groupValue: _mode,
                    onChanged: (v) => setState(
                            () => _mode = v ?? 'offline_at_student'),
                    title: const Text(
                        'Offline tại nhà học viên'),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: 'offline_at_tutor',
                    groupValue: _mode,
                    onChanged: (v) => setState(
                            () => _mode = v ?? 'offline_at_tutor'),
                    title: const Text(
                        'Offline tại nhà gia sư'),
                    dense: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Thời gian
            Text("Thời gian bắt đầu (cho buổi đầu tiên)",
                style: TextStyle(
                    color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text(
                        "Ngày học (buổi đầu tiên)"),
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
                    title: const Text("Thời lượng 1 buổi"),
                    subtitle: Text("$_durationMinutes phút"),
                    trailing: DropdownButton<int>(
                      value: _durationMinutes,
                      items: const [
                        DropdownMenuItem(
                            value: 60,
                            child: Text("60 phút")),
                        DropdownMenuItem(
                            value: 90,
                            child: Text("90 phút")),
                        DropdownMenuItem(
                            value: 120,
                            child: Text("120 phút")),
                      ],
                      onChanged: (v) => setState(
                              () => _durationMinutes = v ?? 60),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ghi chú
            Text("Ghi chú cho gia sư (tuỳ chọn)",
                style: TextStyle(
                    color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                'Ví dụ: Ôn lại chương 1, học qua Zoom...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.grey.shade300),
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
                border: Border.all(
                    color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      color: Colors.green),
                  const SizedBox(width: 10),
                  const Text(
                    "Tổng dự kiến:",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    _fmtVnd(
                      _packageType == 'single'
                          ? _singlePrice
                          : _packageTotalPrice,
                    ),
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
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: _saving
                    ? const Text("Đang tạo...")
                    : const Text(
                  "Xác nhận đặt lịch",
                  style: TextStyle(
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
