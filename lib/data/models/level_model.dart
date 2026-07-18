class LevelCreatorModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final bool emailVerified;
  final String? createdAt;

  LevelCreatorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    required this.emailVerified,
    this.createdAt,
  });

  factory LevelCreatorModel.fromJson(Map<String, dynamic> json) {
    return LevelCreatorModel(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
      emailVerified: json['email_verified'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class LevelModel {
  final int id;
  final String name;
  final int order;
  final int minimumScore;
  final int maximumScore;
  final String price;
  final int estimatedDuration;
  final String status; 
  final LevelCreatorModel? creator;

  LevelModel({
    required this.id,
    required this.name,
    required this.order,
    required this.minimumScore,
    required this.maximumScore,
    required this.price,
    required this.estimatedDuration,
    required this.status,
    this.creator,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      minimumScore: json['minimum_score'] ?? 0,
      maximumScore: json['maximum_score'] ?? 0,
      price: json['price']?.toString() ?? '0',
      estimatedDuration: json['estimated_duration'] ?? 0,
      status: json['status']?.toString() ?? '',
      creator: json['creator'] != null
          ? LevelCreatorModel.fromJson(Map<String, dynamic>.from(json['creator']))
          : null,
    );
  }

  double get priceValue => double.tryParse(price) ?? 0;
}

class StudentLevelsModel {
  final LevelModel? currentLevel;
  final List<LevelModel> completedLevels;
  final List<LevelModel> availableLevels;
  final List<LevelModel> lockedLevels;

  StudentLevelsModel({
    required this.currentLevel,
    required this.completedLevels,
    required this.availableLevels,
    required this.lockedLevels,
  });

  factory StudentLevelsModel.fromJson(Map<String, dynamic> json) {
    List<LevelModel> parseList(dynamic list) {
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => LevelModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return StudentLevelsModel(
      currentLevel: json['current_level'] != null
          ? LevelModel.fromJson(Map<String, dynamic>.from(json['current_level']))
          : null,
      completedLevels: parseList(json['completed_levels']),
      availableLevels: parseList(json['available_levels']),
      lockedLevels: parseList(json['locked_levels']),
    );
  }
}