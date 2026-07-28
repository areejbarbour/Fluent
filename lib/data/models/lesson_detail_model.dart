
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
      title: json['title']?.toString() ?? '',
      xpPoints: json['xp_points'] ?? 0,
      video: json['video']?.toString() ?? '',
    );
  }
}

class LessonCommentUserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  LessonCommentUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName =>
      [firstName, lastName].where((e) => e.trim().isNotEmpty).join(' ');

  factory LessonCommentUserModel.fromJson(Map<String, dynamic> json) {
    return LessonCommentUserModel(
      id: json['id'] ?? 0,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class LessonCommentModel {
  final int id;
  final String comment;
  final LessonCommentUserModel? user;
  final String? createdAt;
  final bool isOwn;

  LessonCommentModel({
    required this.id,
    required this.comment,
    required this.user,
    required this.createdAt,
    this.isOwn = false,
  });

  LessonCommentModel copyWith({bool? isOwn}) {
    return LessonCommentModel(
      id: id,
      comment: comment,
      user: user,
      createdAt: createdAt,
      isOwn: isOwn ?? this.isOwn,
    );
  }

  factory LessonCommentModel.fromJson(Map<String, dynamic> json) {
    return LessonCommentModel(
      id: json['id'] ?? 0,
      comment: json['comment']?.toString() ?? '',
      user: json['user'] != null
          ? LessonCommentUserModel.fromJson(
              Map<String, dynamic>.from(json['user']))
          : null,
      createdAt: json['created_at']?.toString(),
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
    final commentsList =
        (json['comments'] is List) ? json['comments'] as List : [];

    return LessonDetailModel(
      lesson: json['lesson'] != null
          ? LessonVideoModel.fromJson(Map<String, dynamic>.from(json['lesson']))
          : null,
      comments: commentsList
          .whereType<Map>()
          .map((e) => LessonCommentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}