// lib/cubit/teacher/statuses/teacher_status_board_state.dart
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart'; // أضف هذا الاستيراد

abstract class TeacherStatusBoardState {}

class TeacherStatusBoardInitial extends TeacherStatusBoardState {}

class TeacherStatusBoardLoading extends TeacherStatusBoardState {}

class TeacherStatusBoardLoaded extends TeacherStatusBoardState {
  final Map<String, List<CourseModel>> coursesByStatus;
  final Map<String, List<LessonModel>> lessonsByStatus;
  final Map<String, List<TestModel>> testsByStatus; // جديد
  final int totalCourses;
  final int totalLessons;
  final int totalTests; // جديد
  final bool isRefreshing;

  TeacherStatusBoardLoaded({
    required this.coursesByStatus,
    required this.lessonsByStatus,
    required this.testsByStatus,
    required this.totalCourses,
    required this.totalLessons,
    required this.totalTests,
    this.isRefreshing = false,
  });

  TeacherStatusBoardLoaded copyWith({
    Map<String, List<CourseModel>>? coursesByStatus,
    Map<String, List<LessonModel>>? lessonsByStatus,
    Map<String, List<TestModel>>? testsByStatus,
    int? totalCourses,
    int? totalLessons,
    int? totalTests,
    bool? isRefreshing,
  }) {
    return TeacherStatusBoardLoaded(
      coursesByStatus: coursesByStatus ?? this.coursesByStatus,
      lessonsByStatus: lessonsByStatus ?? this.lessonsByStatus,
      testsByStatus: testsByStatus ?? this.testsByStatus,
      totalCourses: totalCourses ?? this.totalCourses,
      totalLessons: totalLessons ?? this.totalLessons,
      totalTests: totalTests ?? this.totalTests,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class TeacherStatusBoardFailure extends TeacherStatusBoardState {
  final String error;
  TeacherStatusBoardFailure(this.error);
}
