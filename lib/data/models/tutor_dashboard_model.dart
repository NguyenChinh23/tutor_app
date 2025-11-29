// lib/data/models/tutor_dashboard_model.dart
import 'package:flutter/material.dart';

enum TutorOnlineStatus { online, busy, offline }

class TutorStats {
  final int pendingRequests;
  final int upcomingLessons;
  final double monthlyEarnings;
  final double avgRating;

  const TutorStats({
    required this.pendingRequests,
    required this.upcomingLessons,
    required this.monthlyEarnings,
    required this.avgRating,
  });

  static const empty = TutorStats(
    pendingRequests: 0,
    upcomingLessons: 0,
    monthlyEarnings: 0,
    avgRating: 0,
  );
}

class TutorRequest {
  final String id;
  final String studentName;
  final String? studentAvatarUrl;
  final String subject;
  final String level;
  final DateTime desiredTime;
  final double price;
  final String note;

  const TutorRequest({
    required this.id,
    required this.studentName,
    this.studentAvatarUrl,
    required this.subject,
    required this.level,
    required this.desiredTime,
    required this.price,
    required this.note,
  });
}

class TutorLesson {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String subject;

  const TutorLesson({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.subject,
  });
}

class ChatPreview {
  final String id;
  final String studentName;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime time;

  const ChatPreview({
    required this.id,
    required this.studentName,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
  });
}

class TutorNotificationItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isImportant;

  const TutorNotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isImportant = false,
  });
}
