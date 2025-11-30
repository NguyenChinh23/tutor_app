import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/tutor_availability_model.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/provider/tutor_availability_provider.dart';

class TutorAvailabilityScreen extends StatefulWidget {
  const TutorAvailabilityScreen({super.key});

  @override
  State<TutorAvailabilityScreen> createState() =>
      _TutorAvailabilityScreenState();
}

class _TutorAvailabilityScreenState extends State<TutorAvailabilityScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = context.read<AppAuthProvider>();
      final user = auth.user;
      if (user != null) {
        context
            .read<TutorAvailabilityProvider>()
            .loadForTutor(user.uid);
        _initialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TutorAvailabilityProvider>();
    final avail = provider.current;

    final primary = AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch rảnh của tôi'),
        backgroundColor: primary,
      ),
      body: provider.isLoading || avail == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Thiết lập các khung giờ rảnh trong tuần. '
                  'Học viên sẽ chỉ đặt được buổi học trùng với những khung giờ này.',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                final weekday = index + 1; // 1..7
                final slotsForDay = avail.slots
                    .where((s) => s.weekday == weekday)
                    .toList();
                final weekdayName =
                _weekdayName(weekday); // T2...CN

                return ExpansionTile(
                  title: Text(weekdayName),
                  subtitle: slotsForDay.isEmpty
                      ? Text(
                    'Chưa có khung giờ',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13),
                  )
                      : Text(
                    '${slotsForDay.length} khung giờ',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 13,
                    ),
                  ),
                  children: [
                    ...slotsForDay.map((slot) {
                      return ListTile(
                        title: Text('${slot.start} - ${slot.end}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            final newSlots = List<AvailabilitySlot>.from(
                                avail.slots);
                            newSlots.removeWhere((s) =>
                            s.weekday == slot.weekday &&
                                s.start == slot.start &&
                                s.end == slot.end);
                            provider.updateSlots(newSlots);
                          },
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () =>
                          _addSlotForDay(context, weekday, avail),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm khung giờ'),
                    ),
                    const SizedBox(height: 6),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await provider.save();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text('Đã lưu lịch rảnh của bạn.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Lưu lịch rảnh',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      case DateTime.sunday:
        return 'Chủ nhật';
      default:
        return '';
    }
  }

  Future<void> _addSlotForDay(
      BuildContext context,
      int weekday,
      TutorAvailability avail,
      ) async {
    TimeOfDay? start;
    TimeOfDay? end;

    Future<TimeOfDay?> pick(TimeOfDay initial) async {
      return await showTimePicker(
        context: context,
        initialTime: initial,
      );
    }

    start = await pick(const TimeOfDay(hour: 18, minute: 0));
    if (start == null) return;
    end = await pick(const TimeOfDay(hour: 20, minute: 0));
    if (end == null) return;

    final df = DateFormat('HH:mm');
    final startDate = DateTime(2020, 1, 1, start.hour, start.minute);
    final endDate = DateTime(2020, 1, 1, end.hour, end.minute);

    if (!endDate.isAfter(startDate)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giờ kết thúc phải sau giờ bắt đầu.'),
        ),
      );
      return;
    }

    final newSlot = AvailabilitySlot(
      weekday: weekday,
      start: df.format(startDate),
      end: df.format(endDate),
    );

    final provider = context.read<TutorAvailabilityProvider>();
    final newSlots = List<AvailabilitySlot>.from(avail.slots)..add(newSlot);
    provider.updateSlots(newSlots);
  }
}
