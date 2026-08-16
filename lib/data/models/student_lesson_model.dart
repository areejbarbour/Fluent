class StudentLessonModel {
  final int id;
  final String title;
  final int order;
  final int xpPoints;

  StudentLessonModel({
    required this.id,
    required this.title,
    required this.order,
    required this.xpPoints,
  });

  factory StudentLessonModel.fromJson(Map<String, dynamic> json) {
    return StudentLessonModel(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      order: json['order'] ?? 0,
      xpPoints: json['xp_points'] ?? 0,
    );
  }
}

/// Mirrors the `progress` object returned by the backend:
/// { "completed_lessons": 1, "total_lessons": 3, "progress_percentage": 33 }
class LessonsProgressSummary {
  final int completedLessons;
  final int totalLessons;
  final double progressPercentage;

  const LessonsProgressSummary({
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercentage,
  });

  factory LessonsProgressSummary.fromJson(Map<String, dynamic> json) {
    return LessonsProgressSummary(
      completedLessons: json['completed_lessons'] ?? 0,
      totalLessons: json['total_lessons'] ?? 0,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  static const empty =
      LessonsProgressSummary(completedLessons: 0, totalLessons: 0, progressPercentage: 0);
}

class StudentLessonsModel {
  final StudentLessonModel? currentLesson;
  final List<StudentLessonModel> completedLessons;
  final List<StudentLessonModel> lockedLessons;
  final LessonsProgressSummary progress;

  StudentLessonsModel({
    required this.currentLesson,
    required this.completedLessons,
    required this.lockedLessons,
    this.progress = LessonsProgressSummary.empty,
  });

  factory StudentLessonsModel.fromJson(Map<String, dynamic> json) {
    List<StudentLessonModel> parseList(dynamic list) {
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) =>
              StudentLessonModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return StudentLessonsModel(
      currentLesson: json['current_lesson'] != null
          ? StudentLessonModel.fromJson(
              Map<String, dynamic>.from(json['current_lesson']))
          : null,
      completedLessons: parseList(json['completed_lessons']),
      lockedLessons: parseList(json['locked_lessons']),
      progress: json['progress'] is Map
          ? LessonsProgressSummary.fromJson(
              Map<String, dynamic>.from(json['progress']))
          : LessonsProgressSummary.empty,
    );
  }
}