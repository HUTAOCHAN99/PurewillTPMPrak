class PlanModel {
  final int id;
  final String name;
  final String type;
  final double price;
  final double? originalPrice;
  final String currency;
  final List<String> features;
  final bool isPopular;
  final bool isBestValue;
  final bool isActive;
  final DateTime? promoEndDate;
  final String? badgeText;
  final int? consultationSessions;
  final int? consultationHistoryDays;

  PlanModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.originalPrice,
    this.currency = 'IDR',
    required this.features,
    this.isPopular = false,
    this.isBestValue = false,
    this.isActive = true,
    this.promoEndDate,
    this.badgeText,
    this.consultationSessions,
    this.consultationHistoryDays,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: json['original_price'] != null 
          ? (json['original_price'] as num).toDouble() 
          : null,
      currency: json['currency'] ?? 'IDR',
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['is_popular'] ?? false,
      isBestValue: json['is_best_value'] ?? false,
      isActive: json['is_active'] ?? true,
      promoEndDate: json['promo_end_date'] != null
          ? DateTime.parse(json['promo_end_date'] as String)
          : null,
      badgeText: json['badge_text'],
      consultationSessions: json['consultation_sessions'],
      consultationHistoryDays: json['consultation_history_days'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price': price,
      'original_price': originalPrice,
      'currency': currency,
      'features': features,
      'is_popular': isPopular,
      'is_best_value': isBestValue,
      'is_active': isActive,
      'promo_end_date': promoEndDate?.toIso8601String(),
      'badge_text': badgeText,
      'consultation_sessions': consultationSessions,
      'consultation_history_days': consultationHistoryDays,
    };
  }

  // Getter untuk format harga
  String get formattedPrice {
    if (type == 'free') return 'Gratis';
    return 'Rp${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  String? get formattedOriginalPrice {
    if (originalPrice == null) return null;
    return 'Rp${originalPrice!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  // Cek apakah ada promo
  bool get hasPromo => originalPrice != null && originalPrice! > price;

  // Cek apakah promo masih berlaku
  bool get isPromoActive {
    if (promoEndDate == null) return false;
    return DateTime.now().isBefore(promoEndDate!);
  }

  // Hitung persentase diskon
  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100);
  }
}