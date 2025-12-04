// lib/presentation/provider/tutor_search_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:tutor_app/data/models/tutor_model.dart';
import 'package:tutor_app/data/models/recent_search_item.dart';
import 'package:tutor_app/data/repositories/recent_search_repository.dart';

class TutorSearchProvider extends ChangeNotifier {
  final RecentSearchRepository _repo;
  Timer? _debounce;

  TutorSearchProvider({RecentSearchRepository? repo})
      : _repo = repo ?? RecentSearchRepository() {
    _loadRecent();
  }

  String _query = '';
  List<TutorModel> _results = [];
  List<RecentSearchItem> _recent = [];

  String get query => _query;
  List<TutorModel> get results => _results;
  List<RecentSearchItem> get recent => _recent;

  // 🟢 load lịch sử
  Future<void> _loadRecent() async {
    _recent = await _repo.load();
    notifyListeners();
  }

  // 🟢 clear all recent
  Future<void> clearAllRecent() async {
    _recent = await _repo.clear();
    notifyListeners();
  }

  // 🟢 xóa 1 item recent
  Future<void> removeRecent(RecentSearchItem it) async {
    _recent = await _repo.remove(_recent, it);
    notifyListeners();
  }

  // 🟢 khi gõ text (debounce + filter)
  void onQueryChanged(String q, List<TutorModel> allTutors) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = q;
      _applyFilter(allTutors);
    });
  }

  // 🟢 khi ấn nút search trên bàn phím
  Future<void> onSubmitted(String q, List<TutorModel> allTutors) async {
    _query = q;
    _recent = await _repo.addTerm(_recent, q);
    _applyFilter(allTutors);
  }

  // 🟢 clear text search
  void clearQuery(List<TutorModel> allTutors) {
    _query = '';
    _results = [];
    notifyListeners();
  }

  // 🟢 lưu tutor vào recent
  Future<void> addTutorToRecent(TutorModel t) async {
    _recent = await _repo.addTutor(
      _recent,
      name: t.name ?? '',
      subject: t.subject ?? '',
      price: (t.price ?? 0).toDouble(),
      rating: (t.rating ?? 0).toDouble(),
      avatarUrl: t.avatarUrl,
    );
    notifyListeners();
  }

  // 🧠 filter tutors theo query + sort rating ↓
  void _applyFilter(List<TutorModel> allTutors) {
    final s = _query.trim().toLowerCase();
    if (s.isEmpty) {
      _results = [];
    } else {
      _results = allTutors.where((t) {
        final name = (t.name ?? '').toLowerCase();
        final subject = (t.subject ?? '').toLowerCase();
        return name.contains(s) || subject.contains(s);
      }).toList()
        ..sort((a, b) => ((b.rating ?? 0).compareTo(a.rating ?? 0)));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
