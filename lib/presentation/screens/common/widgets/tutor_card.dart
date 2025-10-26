import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/tutor_model.dart';

class TutorCard extends StatelessWidget {
  final TutorModel tutor;
  final VoidCallback onBook;

  const TutorCard({super.key, required this.tutor, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          // Ảnh đại diện gia sư
          CircleAvatar(
            radius: 30,
            backgroundImage: tutor.avatarUrl != null && tutor.avatarUrl!.isNotEmpty
                ? NetworkImage(tutor.avatarUrl!)
                : const AssetImage('assets/tutor1.png') as ImageProvider,
          ),
          const SizedBox(width: 10),

          // Thông tin gia sư
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tutor.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  tutor.subject,
                  style: const TextStyle(color: Colors.black54),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text((tutor.rating ?? 0).toStringAsFixed(1)),
                    const SizedBox(width: 10),
                    Text("\$${(tutor.price ?? 0).toStringAsFixed(0)}/h"),
                  ],
                ),
              ],
            ),
          ),

          // Nút Book
          ElevatedButton(
            onPressed: onBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Book",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
