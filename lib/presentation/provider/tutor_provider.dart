import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/tutor_model.dart';
import 'package:tutor_app/data/repositories/tutor_repository.dart';

class TutorProvider extends ChangeNotifier {
  final TutorRepository _repo = TutorRepository();

  List<TutorModel> _tutors = [];
  bool _loading = false;

  List<TutorModel> get tutors => _tutors;
  bool get isLoading => _loading;

  TutorProvider() {
    refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();

    try {
      _repo.getApprovedTuTor().listen(
            (list) {
          _tutors = list;
          _loading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint("TutorProvider Stream Error: $e");
          _loading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint("TutorProvider Error: $e");
      _loading = false;
      notifyListeners();
    }
  }
}
