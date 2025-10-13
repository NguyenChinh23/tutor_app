import 'package:flutter/material.dart';

class BookingRequest {
  final String studentName;
  final String tutorName;
  final String subject;
  final String time;
  String status; // pending, accepted, rejected

  BookingRequest({
    required this.studentName,
    required this.tutorName,
    required this.subject,
    required this.time,
    this.status = "pending",
  });
}

class BookingProvider with ChangeNotifier {
  final List<BookingRequest> _requests = [];

  List<BookingRequest> get requests => _requests;

  void addBooking(BookingRequest booking) {
    _requests.add(booking);
    notifyListeners();
  }

  void acceptBooking(int index) {
    _requests[index].status = "accepted";
    notifyListeners();
  }

  void rejectBooking(int index) {
    _requests[index].status = "rejected";
    notifyListeners();
  }
}
