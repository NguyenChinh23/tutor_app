import 'dart:async';
import 'dart:convert'; // 👈 THÊM

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/tutor_provider.dart';
import 'package:tutor_app/data/models/recent_search_item.dart';
import 'package:tutor_app/data/repositories/recent_search_repository.dart';
import 'package:tutor_app/presentation/screens/student/tutor_detail_screen.dart';
import 'package:tutor_app/data/models/tutor_model.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(v);

String _initials(String name) {
  final p = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (p.isEmpty) return '?';
  if (p.length == 1) return p.first[0].toUpperCase();
  return (p.first[0] + p.last[0]).toUpperCase();
}

/// Avatar helper: hỗ trợ cả link http và base64
ImageProvider? _buildAvatar(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;

  try {
    if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    } else {
      final bytes = base64Decode(avatarUrl);
      return MemoryImage(bytes);
    }
  } catch (e) {
    debugPrint('Search avatar decode error: $e');
    return null;
  }
}

class TutorSearchScreen extends StatefulWidget {
  const TutorSearchScreen({super.key});
  @override
  State<TutorSearchScreen> createState() => _TutorSearchScreenState();
}

class _TutorSearchScreenState extends State<TutorSearchScreen> {
  final _controller = TextEditingController();
  final _repo = RecentSearchRepository();
  Timer? _debounce;

  String _query = '';
  List<RecentSearchItem> _recent = [];

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

  Future<void> _loadRecent() async {
    _recent = await _repo.load();
    if (mounted) setState(() {});
  }

  Future<void> _clearAllRecentQuick() async {
    _recent = await _repo.clear();
    if (mounted) setState(() {});
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = q);
    });
  }

  Future<void> _onSubmitted(String q) async {
    _recent = await _repo.addTerm(_recent, q);
    if (mounted) setState(() => _query = q);
  }

  void _clearQuery() {
    _controller.clear();
    setState(() => _query = '');
  }

  //  Chỉ trả kết quả khi có từ khóa
  List<dynamic> _filter(List<dynamic> tutors, String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return const [];
    return tutors.where((t) {
      final name = (t.name ?? '').toString().toLowerCase();
      final subject = (t.subject ?? '').toString().toLowerCase();
      return name.contains(s) || subject.contains(s);
    }).toList();
  }

  List<RecentSearchItem> _buildUnified(List<dynamic> tutors) {
    final results = _filter(tutors, _query);
    final out = <RecentSearchItem>[
      for (final t in results)
        RecentSearchItem(
          type: 'tutor',
          term: (t.name ?? '').toString(),
          name: (t.name ?? '').toString(),
          subject: (t.subject ?? '').toString(),
          avatarUrl: t.avatarUrl,
          price: (t.price as num?)?.toDouble() ?? 0,
          rating: (t.rating as num?)?.toDouble() ?? 0,
        ),
    ];
    final exists = out.map((e) => e.term.toLowerCase()).toSet();
    final src = _recent.length > 5 ? _recent.sublist(0, 5) : _recent;
    for (final r in src) {
      if (!exists.contains(r.term.toLowerCase())) out.add(r);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final provider = context.watch<TutorProvider>();
    final tutors = provider.tutors;

    final unified = _buildUnified(tutors);
    final onlyRecent = _query.trim().isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Tìm kiếm gia sư'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear), onPressed: _clearQuery),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //  Ô tìm kiếm
            TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              onSubmitted: _onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Nhập tên gia sư hoặc môn học...',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close), onPressed: _clearQuery)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Kết quả & gần đây
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: Row(
                        children: [
                          Text(
                            onlyRecent ? 'Gần đây' : 'Kết quả & gần đây',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (_recent.isNotEmpty)
                            TextButton(
                              onPressed: _clearAllRecentQuick,
                              child: const Text('Xóa tất cả'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    Expanded(
                      child: ListView.builder(
                        itemCount: unified.length,
                        itemBuilder: (_, i) {
                          final it = unified[i];
                          final isTutor = it.type == 'tutor';
                          final displayName = isTutor ? (it.name ?? it.term) : it.term;

                          final avatarImage = _buildAvatar(it.avatarUrl); // 👈 dùng helper

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: primary.withOpacity(0.08),
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? Text(
                                _initials(displayName),
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                                  : null,
                            ),
                            title: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: isTutor
                                ? Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    it.subject ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.star,
                                    size: 14, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  ((it.rating ?? 0).toStringAsFixed(1)),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "${_fmtVnd(it.price ?? 0)} đ/h",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            )
                                : Text('Từ khóa',
                                style: TextStyle(color: Colors.grey[600])),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  _recent = await _repo.remove(_recent, it);
                                  setState(() {});
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Xóa khỏi danh sách')),
                              ],
                              icon: const Icon(Icons.more_vert),
                            ),
                            onTap: () async {
                              if (isTutor) {
                                // Lưu vào recent nếu là tutor
                                _recent = await _repo.addTutor(
                                  _recent,
                                  name: it.name ?? it.term,
                                  subject: it.subject ?? '',
                                  price: it.price ?? 0,
                                  rating: it.rating ?? 0,
                                  avatarUrl: it.avatarUrl,
                                );
                                setState(() {});

                                //  Tìm TutorModel thật từ provider theo name (tạm thời)
                                final provider = context.read<TutorProvider>();
                                final List<TutorModel> match = provider.tutors
                                    .where((t) =>
                                t.name == (it.name ?? it.term))
                                    .toList();

                                if (match.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TutorDetailScreen(tutor: match.first),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Không tìm thấy hồ sơ chi tiết của gia sư này.')),
                                  );
                                }
                              } else {
                                _controller.text = it.term;
                                _controller.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(offset: it.term.length),
                                    );
                                await _onSubmitted(it.term);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
