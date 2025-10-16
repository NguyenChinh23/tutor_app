import 'package:flutter/material.dart';
import 'package:tutor_app/config/theme.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚙️ Dữ liệu mẫu – sau này thay bằng Firestore
    final dummyChats = [
      {
        "name": "Alice Nguyen",
        "message": "See you tomorrow!",
        "time": "09:30 AM",
        "avatar": "assets/images/avatar.png"
      },
      {
        "name": "John Tran",
        "message": "Sure, I'll send materials.",
        "time": "08:15 AM",
        "avatar": "assets/images/avatar.png"
      },
      {
        "name": "Tutor Mai Linh",
        "message": "The next class is at 7pm.",
        "time": "Yesterday",
        "avatar": "assets/images/avatar.png"
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        elevation: 0,
      ),

      // 📜 Danh sách chat
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: dummyChats.length,
        itemBuilder: (context, index) {
          final chat = dummyChats[index];
          return _chatTile(
            context,
            name: chat["name"]!,
            message: chat["message"]!,
            time: chat["time"]!,
            avatarPath: chat["avatar"]!,
          );
        },
      ),
    );
  }

  // 🧩 Widget hiển thị từng chat
  Widget _chatTile(
      BuildContext context, {
        required String name,
        required String message,
        required String time,
        required String avatarPath,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                chatName: name,
                avatarUrl: avatarPath,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: AssetImage(avatarPath),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            message,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ),
        trailing: Text(
          time,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
