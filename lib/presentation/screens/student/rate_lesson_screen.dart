import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/presentation/provider/booking_provider.dart';

class RateLessonScreen extends StatefulWidget {
  final BookingModel booking;

  const RateLessonScreen({super.key, required this.booking});

  @override
  State<RateLessonScreen> createState() => _RateLessonScreenState();
}

class _RateLessonScreenState extends State<RateLessonScreen> {
  double _rating = 5.0;
  final TextEditingController _reviewCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await context.read<BookingProvider>().submitRating(
        booking: widget.booking,
        rating: _rating,
        review: _reviewCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã đánh giá buổi học!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final b = widget.booking;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá buổi học'),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b.subject.isEmpty
                  ? 'Buổi học với ${b.tutorName}'
                  : '${b.subject} - ${b.tutorName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đánh giá của bạn:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isFull = _rating >= starIndex;
                return IconButton(
                  onPressed: () {
                    setState(() => _rating = starIndex.toDouble());
                  },
                  icon: Icon(
                    Icons.star,
                    color: isFull ? Colors.amber : Colors.grey[400],
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Nhận xét (tuỳ chọn)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Gửi đánh giá',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
