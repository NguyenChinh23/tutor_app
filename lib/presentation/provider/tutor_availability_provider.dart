import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/tutor_availability_model.dart';
import 'package:tutor_app/data/repositories/tutor_availability_repository.dart';

class TutorAvailabilityProvider extends ChangeNotifier {
  final TutorAvailabilityRepository repository;

  TutorAvailabilityProvider({required this.repository});

  TutorAvailability? current;
  bool isLoading = false;
  String? lastError;

  /// load availability cho 1 tutor
  Future<void> loadForTutor(String tutorId) async {
    try {
      isLoading = true;
      lastError = null;
      notifyListeners();

      final data = await repository.getForTutor(tutorId);
      current = data ??
          TutorAvailability(
            tutorId: tutorId,
            slots: [],
          );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      lastError = e.toString();
      notifyListeners();
    }
  }

  /// chỉ dùng khi đang chỉnh sửa trong UI tutor settings
  void updateSlots(List<AvailabilitySlot> newSlots) {
    if (current == null) return;
    current = TutorAvailability(
      tutorId: current!.tutorId,
      slots: newSlots,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> save() async {
    if (current == null) return;
    await repository.saveForTutor(
      TutorAvailability(
        tutorId: current!.tutorId,
        slots: current!.slots,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
