class CourseModel {
  final int id;
  final String name;
  final int order;
  final int estimatedDuration;
  final String status;
  final String image;
  final String teacherName; // ← جديد

  /// Published course test id (CourseResource.test_id).
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
    String teacherName = "Fluent Instructor"; // قيمة افتراضية

    final teacher = json['teacher'];
    if (teacher is Map<String, dynamic>) {
      final first = teacher['first_name']?.toString() ?? '';
      final last = teacher['last_name']?.toString() ?? '';
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

class StudentCoursesModel {
  final CourseModel? currentCourse;
  final List<CourseModel> completedCourses;
  final List<CourseModel> lockedCourses;

  StudentCoursesModel({
    required this.currentCourse,
    required this.completedCourses,
    required this.lockedCourses,
  });

  factory StudentCoursesModel.fromJson(Map<String, dynamic> json) {
    List<CourseModel> parseList(dynamic list) {
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return StudentCoursesModel(
      currentCourse: json['current_course'] != null
          ? CourseModel.fromJson(
              Map<String, dynamic>.from(json['current_course']),
            )
          : null,
      completedCourses: parseList(json['completed_courses']),
      lockedCourses: parseList(json['locked_courses']),
    );
  }
}
