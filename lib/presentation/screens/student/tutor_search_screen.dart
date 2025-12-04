import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/tutor_provider.dart';
import 'package:tutor_app/presentation/provider/tutor_search_provider.dart';
import 'package:tutor_app/presentation/screens/student/tutor_detail_screen.dart';
import 'package:tutor_app/data/models/tutor_model.dart';
import 'package:tutor_app/data/models/recent_search_item.dart';

String _fmtVnd(num v) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0)
        .format(v);

String _initials(String name) {
  final p = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (p.isEmpty) return '?';
  if (p.length == 1) return p.first[0].toUpperCase();
  return (p.first[0] + p.last[0]).toUpperCase();
}

/// Avatar helper: hỗ trợ link http và base64
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClearQuery(
      TutorSearchProvider search, List<TutorModel> tutors) {
    _controller.clear();
    search.clearQuery(tutors);
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;

    final tutorProvider = context.watch<TutorProvider>();
    final searchProvider = context.watch<TutorSearchProvider>();

    final tutors = tutorProvider.tutors;
    final query = searchProvider.query.trim();
    final hasQuery = query.isNotEmpty;

    final results = searchProvider.results;      // danh sách gia sư sau khi search
    final recents = searchProvider.recent;      // lịch sử gần đây

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
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _handleClearQuery(searchProvider, tutors),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Ô tìm kiếm
            TextField(
              controller: _controller,
              onChanged: (value) {
                searchProvider.onQueryChanged(value, tutors);
              },
              onSubmitted: (value) {
                searchProvider.onSubmitted(value, tutors);
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Nhập tên gia sư hoặc môn học...',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _handleClearQuery(searchProvider, tutors),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔁 Kết quả / Gần đây
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
                            hasQuery ? 'Kết quả cho "$query"' : 'Kết quả gần đây',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (!hasQuery && recents.isNotEmpty)
                            TextButton(
                              onPressed: () => searchProvider.clearAllRecent(),
                              child: const Text('Xóa tất cả'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    Expanded(
                      child: hasQuery
                          ? _buildSearchResults(
                          context, results, searchProvider, primary)
                          : _buildRecentList(
                          context, recents, searchProvider, primary, tutors),
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

// 📘 List kết quả tìm kiếm (CHỈ tutor, không trộn gần đây)
Widget _buildSearchResults(
    BuildContext context,
    List<TutorModel> results,
    TutorSearchProvider searchProvider,
    Color primary,
    ) {
  if (results.isEmpty) {
    return const Center(child: Text('Không tìm thấy gia sư phù hợp'));
  }

  return ListView.builder(
    itemCount: results.length,
    itemBuilder: (_, i) {
      final t = results[i];
      final avatarImage = _buildAvatar(t.avatarUrl);

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: primary.withOpacity(0.08),
          backgroundImage: avatarImage,
          child: avatarImage == null
              ? Text(
            _initials(t.name ?? ''),
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
          )
              : null,
        ),
        title: Text(
          t.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                t.subject ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 2),
            Text(
              (t.rating ?? 0).toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            Text(
              '${_fmtVnd(t.price ?? 0)} đ/h',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        onTap: () async {
          await searchProvider.addTutorToRecent(t);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TutorDetailScreen(tutor: t),
            ),
          );
        },
      );
    },
  );
}

// 📗 List lịch sử gần đây (tutor + keyword)
Widget _buildRecentList(
    BuildContext context,
    List<RecentSearchItem> recents,
    TutorSearchProvider searchProvider,
    Color primary,
    List<TutorModel> allTutors,
    ) {
  if (recents.isEmpty) {
    return const Center(child: Text('Chưa có lịch sử tìm kiếm'));
  }

  return ListView.builder(
    itemCount: recents.length,
    itemBuilder: (_, i) {
      final it = recents[i];
      final isTutor = it.type == 'tutor';
      final displayName = isTutor ? (it.name ?? it.term) : it.term;
      final avatarImage = _buildAvatar(it.avatarUrl);

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            ? Text(
          it.subject ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )
            : Text(
          'Từ khóa',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') {
              searchProvider.removeRecent(it);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'delete',
              child: Text('Xóa khỏi danh sách'),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
        onTap: () async {
          if (isTutor) {
            // tìm tutor thật trong allTutors theo name
            final match = allTutors
                .where((t) => t.name == (it.name ?? it.term))
                .toList();

            if (match.isNotEmpty) {
              await searchProvider.addTutorToRecent(match.first);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TutorDetailScreen(tutor: match.first),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                  Text('Không tìm thấy hồ sơ chi tiết của gia sư này.'),
                ),
              );
            }
          } else {
            // recent là keyword -> search lại với term
            final tutors = allTutors;
            final q = it.term;
            final sp = context.read<TutorSearchProvider>();
            sp.onSubmitted(q, tutors);
          }
        },
      );
    },
  );
}
