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

class StudentLessonsModel {
  final StudentLessonModel? currentLesson;
  final List<StudentLessonModel> completedLessons;
  final List<StudentLessonModel> lockedLessons;

  StudentLessonsModel({
    required this.currentLesson,
    required this.completedLessons,
    required this.lockedLessons,
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
    );
  }
}