import '../models/recent_search_item.dart';
import '../services/recent_search_service.dart';

class RecentSearchRepository {
  final RecentSearchService _svc;
  final int _limit;

  RecentSearchRepository({RecentSearchService? service, int limit = 20})
      : _svc = service ?? RecentSearchService(),
        _limit = limit;

  Future<List<RecentSearchItem>> load() async {
    final raw = await _svc.loadRaw();
    return raw.map((e) => RecentSearchItem.tryParse(e)).whereType<RecentSearchItem>().toList();
  }

  Future<void> _save(List<RecentSearchItem> list) async {
    await _svc.saveRaw(list.map((e) => e.encode()).toList());
  }

  Future<List<RecentSearchItem>> addTerm(List<RecentSearchItem> cur, String term) async {
    final t = term.trim();
    if (t.isEmpty) return cur;
    cur.removeWhere((e) => e.term.toLowerCase() == t.toLowerCase());
    cur.insert(0, RecentSearchItem(type: 'term', term: t));
    if (cur.length > _limit) cur = cur.sublist(0, _limit);
    await _save(cur);
    return cur;
  }

  Future<List<RecentSearchItem>> addTutor(
      List<RecentSearchItem> cur, {
        required String name,
        required String subject,
        required double price,
        required double rating,
        String? avatarUrl,
      }) async {
    final term = name.trim();
    if (term.isEmpty) return cur;
    cur.removeWhere((e) => e.term.toLowerCase() == term.toLowerCase());
    cur.insert(0, RecentSearchItem(
      type: 'tutor', term: term, name: name, subject: subject,
      price: price, rating: rating, avatarUrl: avatarUrl,
    ));
    if (cur.length > _limit) cur = cur.sublist(0, _limit);
    await _save(cur);
    return cur;
  }

  Future<List<RecentSearchItem>> remove(List<RecentSearchItem> cur, RecentSearchItem it) async {
    cur.remove(it);
    await _save(cur);
    return cur;
  }

  Future<List<RecentSearchItem>> clear() async {
    await _save([]);
    return [];
  }
}
