import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/data/models/tutor_model.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';

final _currencyFmt = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

class TutorCard extends StatelessWidget {
  const TutorCard({
    super.key,
    required this.tutor,
    this.onBook,
  });

  final TutorModel tutor;
  final VoidCallback? onBook;

  ImageProvider _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/tutor1.png');
    }
    try {
      if (avatarUrl.startsWith('http')) {
        return NetworkImage(avatarUrl);
      } else {
        return MemoryImage(base64Decode(avatarUrl));
      }
    } catch (_) {
      return const AssetImage('assets/tutor1.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: _buildAvatar(tutor.avatarUrl),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tutor.subject,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(tutor.rating.toStringAsFixed(1)),
                    const SizedBox(width: 12),
                    Text(
                      '${_currencyFmt.format(tutor.price)}/h',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.menu_book, size: 14),
                    const SizedBox(width: 4),
                    Text('${tutor.totalLessons} buổi'),
                    const SizedBox(width: 12),
                    const Icon(Icons.people, size: 14),
                    const SizedBox(width: 4),
                    Text('${tutor.totalStudents} học viên'),
                  ],
                ),
              ],
            ),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final ok = auth.requireLogin(context);
              if (!ok) return;

              onBook?.call();
            },
            child: const Text(
              'Book',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
