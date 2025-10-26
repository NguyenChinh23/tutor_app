import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutor_app/presentation/provider/tutor_provider.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0)
        .format(v); // ví dụ: 200.000 (ta sẽ thêm " đ/h" phía sau)

class TutorSearchScreen extends StatefulWidget {
  const TutorSearchScreen({super.key});

  @override
  State<TutorSearchScreen> createState() => _TutorSearchScreenState();
}

class _TutorSearchScreenState extends State<TutorSearchScreen> {
  static const _prefsKeyRecent = 'recent_tutor_searches';
  static const _recentLimit = 10;

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  String _query = '';
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ---------------- Recent Search ----------------
  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recent = prefs.getStringList(_prefsKeyRecent) ?? [];
    });
  }

  Future<void> _saveRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKeyRecent, _recent);
  }

  Future<void> _addRecent(String term) async {
    final q = term.trim();
    if (q.isEmpty) return;
    _recent.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    _recent.insert(0, q);
    if (_recent.length > _recentLimit) {
      _recent = _recent.sublist(0, _recentLimit);
    }
    await _saveRecent();
    setState(() {});
  }

  Future<void> _removeRecent(String term) async {
    _recent.remove(term);
    await _saveRecent();
    setState(() {});
  }

  Future<void> _clearAllRecent() async {
    _recent.clear();
    await _saveRecent();
    setState(() {});
  }

  // ---------------- Search handlers ----------------
  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = q);
    });
  }

  void _onSubmitted(String q) async {
    await _addRecent(q);
    setState(() => _query = q);
  }

  void _clearQuery() {
    _controller.clear();
    setState(() => _query = '');
  }

  // ---------------- Helpers ----------------
  List<dynamic> _filter(List<dynamic> tutors, String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return tutors; // hiển thị ALL khi rỗng
    return tutors.where((t) {
      final name = (t.name ?? '').toString().toLowerCase();
      final subject = (t.subject ?? '').toString().toLowerCase();
      return name.contains(s) || subject.contains(s);
    }).toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tutorProvider = context.watch<TutorProvider>();
    final all = tutorProvider.tutors;
    final results = _filter(all, _query);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text("Tìm kiếm gia sư"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Xóa nội dung',
              icon: const Icon(Icons.clear),
              onPressed: _clearQuery,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ô tìm kiếm
            TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              onSubmitted: _onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Nhập tên gia sư hoặc môn học...",
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearQuery,
                  tooltip: 'Xóa',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tìm kiếm gần đây
            if (_recent.isNotEmpty) ...[
              Row(
                children: [
                  const Text('Tìm kiếm gần đây',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _clearAllRecent,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa hết'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recent
                    .map((term) => InputChip(
                  label: Text(term),
                  avatar: const Icon(Icons.history, size: 16),
                  onPressed: () {
                    _controller.text = term;
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: term.length),
                    );
                    _onSubmitted(term); // lưu & tìm lại
                  },
                  onDeleted: () => _removeRecent(term), // xóa từng mục
                ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Danh sách kết quả (KHÔNG có Divider)
            Expanded(
              child: tutorProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : results.isEmpty
                  ? _Empty(query: _query, hasData: all.isNotEmpty)
                  : ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final t = results[index];
                  final String name = (t.name ?? '').toString();
                  final String subject = (t.subject ?? '').toString();
                  final double rating =
                      (t.rating as num?)?.toDouble() ?? 0.0;
                  final double price =
                      (t.price as num?)?.toDouble() ?? 0.0;
                  final String? avatarUrl = t.avatarUrl;

                  return InkWell(
                    onTap: () async {
                      // Ví dụ: mở chi tiết hoặc chỉ lưu lịch sử theo tên
                      await _addRecent(name);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar: url -> ảnh; null -> initials
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.indigo.shade50,
                            backgroundImage: (avatarUrl != null &&
                                avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null ||
                                avatarUrl.isEmpty)
                                ? Text(
                              _initials(name),
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Thông tin
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subject,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // rating + price
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16,
                                        color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontWeight:
                                          FontWeight.w600),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "${_fmtVnd(price)} đ/h",
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.query, required this.hasData});
  final String query;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final msg = !hasData
        ? "Chưa có dữ liệu gia sư."
        : (query.trim().isEmpty
        ? "Không có dữ liệu hiển thị."
        : "Không tìm thấy gia sư cho: \"$query\"");
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          msg,
          style: TextStyle(color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
