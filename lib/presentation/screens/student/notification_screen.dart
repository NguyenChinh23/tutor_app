import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/presentation/provider/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationProvider>();
    final df = DateFormat('dd/MM/yyyy HH:mm');

    final items = notif.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
      ),
      body: items.isEmpty
          ? Center(
        child: Text(
          notif.lastError != null
              ? 'Lỗi: ${notif.lastError}'
              : 'Không có thông báo nào.',
        ),
      )
          : ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) =>
        const Divider(height: 0, thickness: 0.4),
        itemBuilder: (context, index) {
          final n = items[index];

          final isRead = n.read;

          return ListTile(
            leading: Icon(
              Icons.notifications,
              color: isRead ? Colors.grey : Colors.blueAccent,
            ),
            title: Text(
              n.title,
              style: TextStyle(
                fontWeight:
                isRead ? FontWeight.w400 : FontWeight.w600,
                color: isRead ? Colors.grey[800] : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.body,
                  style: TextStyle(
                    color: isRead ? Colors.grey[700] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  df.format(n.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            // 🔴 Chấm đỏ chỉ hiện nếu CHƯA đọc
            trailing: isRead
                ? null
                : const Icon(
              Icons.circle,
              size: 10,
              color: Colors.red,
            ),
            onTap: () async {
              // 👉 Chỉ mark read nếu đang là chưa đọc
              if (!isRead) {
                await context
                    .read<NotificationProvider>()
                    .markAsRead(n.id);
              }
            },
          );
        },
      ),
    );
  }
}
