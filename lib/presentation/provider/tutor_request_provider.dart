import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tutor_app/data/models/tutor_request_model.dart';
import 'package:tutor_app/data/repositories/tutor_request_repository.dart';

class TutorRequestProvider extends ChangeNotifier {
  final TutorRequestRepository _repo;

  TutorRequestProvider(this._repo);

  List<TutorRequestModel> _pending = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<TutorRequestModel>>? _sub;

  List<TutorRequestModel> get pendingRequests => _pending;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToTutorRequests(String tutorId) {
    if (tutorId.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _repo.streamRequests(tutorId).listen(
          (requests) {
        _pending =
            requests.where((r) => r.status == 'pending').toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> accept(TutorRequestModel request) async {
    try {
      await _repo.acceptRequest(request);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> reject(TutorRequestModel request) async {
    try {
      await _repo.rejectRequest(request);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
