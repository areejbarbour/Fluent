class CourseModel {
  final int id;
  final String name;
  final int order;
  final int estimatedDuration;
  final String status;
  final String image;
  final String teacherName;

  final int? testId;

  CourseModel({
    required this.id,
    required this.name,
    required this.order,
    required this.estimatedDuration,
    required this.status,
    required this.image,
    required this.teacherName,
    this.testId,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    String teacherName = "Fluent Instructor";

    final teacher = json['teacher'];
    if (teacher is Map) {
      final map = Map<String, dynamic>.from(teacher);
      final first = map['first_name']?.toString() ?? '';
      final last = map['last_name']?.toString() ?? '';
      teacherName = "$first $last".trim();
      if (teacherName.isEmpty) teacherName = "Fluent Instructor";
    }
    final testRaw = json['test_id'];
    return CourseModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      estimatedDuration: json['estimated_duration'] ?? 0,
      status: json['status']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      teacherName: teacherName,
      testId: testRaw == null
          ? null
          : (testRaw is int ? testRaw : int.tryParse(testRaw.toString())),
    );
  }
}

class CoursesProgressModel {
  final int completedCourses;
  final int totalCourses;
  final int progressPercentage;

  const CoursesProgressModel({
    required this.completedCourses,
    required this.totalCourses,
    required this.progressPercentage,
  });

  factory CoursesProgressModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return CoursesProgressModel(
      completedCourses: asInt(json['completed_courses']),
      totalCourses: asInt(json['total_courses']),
      progressPercentage: asInt(json['progress_percentage']),
    );
  }

  double get fraction => (progressPercentage.clamp(0, 100) / 100.0);
}

class StudentCoursesModel {
  final CourseModel? currentCourse;
  final List<CourseModel> completedCourses;
  final List<CourseModel> lockedCourses;
  final CoursesProgressModel? progress;

  StudentCoursesModel({
    required this.currentCourse,
    required this.completedCourses,
    required this.lockedCourses,
    this.progress,
  });

  factory StudentCoursesModel.fromJson(Map<String, dynamic> json) {
    List<CourseModel> parseList(dynamic list) {
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    CoursesProgressModel? progress;
    final rawProgress = json['progress'];
    if (rawProgress is Map) {
      progress = CoursesProgressModel.fromJson(
        Map<String, dynamic>.from(rawProgress),
      );
    }

    return StudentCoursesModel(
      currentCourse: json['current_course'] != null
          ? CourseModel.fromJson(
              Map<String, dynamic>.from(json['current_course'] as Map),
            )
          : null,
      completedCourses: parseList(json['completed_courses']),
      lockedCourses: parseList(json['locked_courses']),
      progress: progress,
    );
  }
}
