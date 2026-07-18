class CourseModel {
  final int id;
  final String name;
  final int order;
  final int estimatedDuration;
  final String status;
  final String image;

  CourseModel({
    required this.id,
    required this.name,
    required this.order,
    required this.estimatedDuration,
    required this.status,
    required this.image,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      estimatedDuration: json['estimated_duration'] ?? 0,
      status: json['status']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
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
              Map<String, dynamic>.from(json['current_course']))
          : null,
      completedCourses: parseList(json['completed_courses']),
      lockedCourses: parseList(json['locked_courses']),
    );
  }
}