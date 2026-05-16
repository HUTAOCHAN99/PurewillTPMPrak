class CategoryModel {
  final int id;
  final String name;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // print('=== PARSING CATEGORY JSON ===');
    // print('Raw JSON: $json');
    
    DateTime parseCreatedAt(dynamic date) {
      if (date is String) {
        return DateTime.parse(date);
      }
      return DateTime.now();
    }

    final category = CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      createdAt: parseCreatedAt(json['created_at']),
    );

    // print('Parsed Category: ${category.id} - ${category.name}');
    return category;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CategoryModel{id: $id, name: $name}';
  }
}