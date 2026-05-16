// lib\ui\habit-tracker\widget\habit_detail\models\quote_model.dart
class Quote {
  final String id;
  final String quote;
  final String author;
  final DateTime createdAt;

  Quote({
    required this.id,
    required this.quote,
    required this.author,
    required this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? '',
      quote: json['quote'] ?? '',
      author: json['author'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}