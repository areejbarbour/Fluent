/// Matches backend [RateResource]: { id, stars }
class RateModel {
  final int id;
  final int stars;

  const RateModel({
    required this.id,
    required this.stars,
  });

  factory RateModel.fromJson(Map<String, dynamic> json) {
    return RateModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      stars: json['stars'] is int
          ? json['stars'] as int
          : int.tryParse(json['stars']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stars': stars,
      };

  RateModel copyWith({int? id, int? stars}) {
    return RateModel(
      id: id ?? this.id,
      stars: stars ?? this.stars,
    );
  }

  bool get isValid => id > 0 && stars >= 1 && stars <= 5;
}
