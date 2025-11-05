import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchService {
  static const _key = 'recent_tutor_searches_v2';

  Future<List<String>> loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  Future<void> saveRaw(List<String> raw) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, raw);
  }
}
