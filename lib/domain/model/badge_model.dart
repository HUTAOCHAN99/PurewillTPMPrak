class Badge {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final String triggerType;
  final int triggerValue;
  final DateTime? earnedAt;
  final bool isUnlocked;
  final int progress; // Progress saat ini menuju badge
  
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.triggerType,
    required this.triggerValue,
    this.earnedAt,
    required this.isUnlocked,
    required this.progress,
  });
  
  factory Badge.fromJson(Map<String, dynamic> json, String userId) {
    final userBadges = json['user_badges'] as List?;
    final isUnlocked = userBadges != null && userBadges.isNotEmpty;
    DateTime? earnedAt;
    
    if (isUnlocked && userBadges!.first['earned_at'] != null) {
      earnedAt = DateTime.parse(userBadges.first['earned_at']);
    }
    
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      triggerType: json['trigger_type'],
      triggerValue: json['trigger_value'],
      earnedAt: earnedAt,
      isUnlocked: isUnlocked,
      progress: 0, // Will be calculated separately
    );
  }
  
  // Add copyWith method
  Badge copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    String? triggerType,
    int? triggerValue,
    DateTime? earnedAt,
    bool? isUnlocked,
    int? progress,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      triggerType: triggerType ?? this.triggerType,
      triggerValue: triggerValue ?? this.triggerValue,
      earnedAt: earnedAt ?? this.earnedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
    );
  }
}