import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

class AdminProvider extends ChangeNotifier {
  final _repo = AuthRepository();
  bool _loading = false;
  bool get isLoading => _loading;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  /// ✅ Duyệt hồ sơ gia sư
  Future<void> approveTutor({
    required String uid,
    required String appId,
    required String reviewerUid,
  }) async {
    _setLoading(true);
    try {
      await _repo.approveTutor(uid: uid, appId: appId, reviewerUid: reviewerUid);
    } catch (e) {
      debugPrint("❌ Lỗi duyệt hồ sơ: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ❌ Từ chối hồ sơ
  Future<void> rejectTutor({
    required String appId,
    required String reviewerUid,
  }) async {
    _setLoading(true);
    try {
      await _repo.rejectTutor(appId: appId, reviewerUid: reviewerUid);
    } catch (e) {
      debugPrint("❌ Lỗi từ chối hồ sơ: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
