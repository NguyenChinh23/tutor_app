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
      return MemoryImage(base64Decode(avatarUrl));
    }
  } catch (_) {
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

  /// single | 1m | 3m | 6m
  String _packageType = 'single';

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

  double get hours => _durationMinutes / 60;

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
    return _weeks * _selectedWeekdays.length;
  }

  double get _singlePrice => widget.tutor.price * hours;

  double get _packageTotalPrice {
    if (_packageType == 'single') return _singlePrice;

    final discount = switch (_packageType) {
      '1m' => 0.05,
      '3m' => 0.10,
      '6m' => 0.15,
      _ => 0.0,
    };

    return _singlePrice * _estimatedTotalSessions * (1 - discount);
  }

  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<void> _submit() async {
    final auth = context.read<AppAuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    if (_packageType != 'single' && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ít nhất một ngày học trong tuần')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final startAt = _combine(_selectedDate, _start);
      final endAt = startAt.add(Duration(minutes: _durationMinutes));

      await bookingProvider.createBooking(
        tutorId: widget.tutor.uid,
        tutorName: widget.tutor.name,
        studentId: auth.user!.uid,
        studentName: auth.user!.displayName ?? 'Student',
        subject: _selectedSubject ?? widget.tutor.subject,
        pricePerHour: widget.tutor.price,
        hours: hours,
        startAt: startAt,
        endAt: endAt,
        note: _noteCtrl.text.trim(),
        mode: _mode,
        packageType: _packageType,
        totalSessions:
        _packageType == 'single' ? 1 : _estimatedTotalSessions,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt lịch thành công')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _weekdayChip(String label, int weekday) {
    final selected = _selectedWeekdays.contains(weekday);
    return GestureDetector(
      onTap: () {
        setState(() {
          selected
              ? _selectedWeekdays.remove(weekday)
              : _selectedWeekdays.add(weekday);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 6, bottom: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
            selected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutor;
    final df = DateFormat('EEE, dd/MM/yyyy', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch học'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Tutor header =====
            ListTile(
              leading: CircleAvatar(
                backgroundImage: _buildTutorAvatar(tutor.avatarUrl),
              ),
              title: Text(tutor.name),
              subtitle: Text(tutor.subject),
              trailing: Text(
                _fmtVnd(tutor.price),
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            // ===== Package =====
            RadioListTile(
              value: 'single',
              groupValue: _packageType,
              onChanged: (v) => setState(() => _packageType = v!),
              title: const Text('1 buổi lẻ'),
            ),
            RadioListTile(
              value: '1m',
              groupValue: _packageType,
              onChanged: (v) => setState(() => _packageType = v!),
              title: const Text('Gói 1 tháng'),
            ),
            RadioListTile(
              value: '3m',
              groupValue: _packageType,
              onChanged: (v) => setState(() => _packageType = v!),
              title: const Text('Gói 3 tháng'),
            ),
            RadioListTile(
              value: '6m',
              groupValue: _packageType,
              onChanged: (v) => setState(() => _packageType = v!),
              title: const Text('Gói 6 tháng'),
            ),

            if (_packageType != 'single') ...[
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
              Text('~ $_estimatedTotalSessions buổi'),
            ],

            const SizedBox(height: 16),

            // ===== Time =====
            ListTile(
              title: const Text('Ngày bắt đầu'),
              subtitle: Text(df.format(_selectedDate)),
              trailing: TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
                child: const Text('Chọn'),
              ),
            ),

            ListTile(
              title: const Text('Giờ bắt đầu'),
              subtitle: Text(_start.format(context)),
              trailing: TextButton(
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _start,
                  );
                  if (t != null) setState(() => _start = t);
                },
                child: const Text('Chọn'),
              ),
            ),

            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
              ),
            ),

            const SizedBox(height: 20),

            // ===== Total =====
            Text(
              'Tổng tiền: ${_fmtVnd(_packageType == 'single' ? _singlePrice : _packageTotalPrice)}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppTheme.primaryColor,
              ),
              child:
              Text(_saving ? 'Đang tạo...' : 'Xác nhận đặt lịch'),
            ),
          ],
        ),
      ),
    );
  }
}
