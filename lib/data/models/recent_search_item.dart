import 'dart:convert';

class RecentSearchItem {
  final String type;
  final String term;
  final String? name, subject, avatarUrl;
  final double? price, rating;

  const RecentSearchItem({
    required this.type,
    required this.term,
    this.name,
    this.subject,
    this.avatarUrl,
    this.price,
    this.rating,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'term': term,
    'name': name,
    'subject': subject,
    'avatarUrl': avatarUrl,
    'price': price,
    'rating': rating,
  };

  factory RecentSearchItem.fromJson(Map<String, dynamic> j) => RecentSearchItem(
    type: j['type'] ?? 'term',
    term: j['term'] ?? '',
    name: j['name'],
    subject: j['subject'],
    avatarUrl: j['avatarUrl'],
    price: (j['price'] as num?)?.toDouble(),
    rating: (j['rating'] as num?)?.toDouble(),
  );

  static RecentSearchItem? tryParse(String s) {
    try { return RecentSearchItem.fromJson(jsonDecode(s)); } catch (_) { return null; }
  }

  String encode() => jsonEncode(toJson());
}
