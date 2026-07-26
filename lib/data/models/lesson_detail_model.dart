class LessonVideoModel {
  final int id;
  final String title;
  final int xpPoints;
  final String video;

  LessonVideoModel({
    required this.id,
    required this.title,
    required this.xpPoints,
    required this.video,
  });

  factory LessonVideoModel.fromJson(Map<String, dynamic> json) {
    return LessonVideoModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      xpPoints: json['xp_points'] ?? 0,
      video: json['video']?.toString() ?? '',
    );
  }
}

class CommentUserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final bool emailVerified;
  final String? createdAt;

  CommentUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    required this.emailVerified,
    this.createdAt,
  });

  factory CommentUserModel.fromJson(Map<String, dynamic> json) {
    return CommentUserModel(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
      emailVerified: json['email_verified'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }

  String get fullName => "$firstName $lastName".trim();
}

class LessonCommentModel {
  final int id;
  final String comment;
  final CommentUserModel? user;
  final String? createdAt;
  final String? updatedAt;

  LessonCommentModel({
    required this.id,
    required this.comment,
    required this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory LessonCommentModel.fromJson(Map<String, dynamic> json) {
    return LessonCommentModel(
      id: json['id'] ?? 0,
      comment: json['comment']?.toString() ?? '',
      user: json['user'] != null
          ? CommentUserModel.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class LessonDetailModel {
  final LessonVideoModel? lesson;
  final List<LessonCommentModel> comments;

  LessonDetailModel({
    required this.lesson,
    required this.comments,
  });

  factory LessonDetailModel.fromJson(Map<String, dynamic> json) {
    List<LessonCommentModel> parseComments(dynamic list) {
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => LessonCommentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return LessonDetailModel(
      lesson: json['lesson'] != null
          ? LessonVideoModel.fromJson(Map<String, dynamic>.from(json['lesson']))
          : null,
      comments: parseComments(json['comments']),
    );
  }
}