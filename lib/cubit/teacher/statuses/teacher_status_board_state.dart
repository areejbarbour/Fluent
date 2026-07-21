import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';

abstract class TeacherStatusBoardState {}

class TeacherStatusBoardInitial extends TeacherStatusBoardState {}

class TeacherStatusBoardLoading extends TeacherStatusBoardState {}

class TeacherStatusBoardLoaded extends TeacherStatusBoardState {
  final Map<String, List<CourseModel>> coursesByStatus;
  final Map<String, List<LessonModel>> lessonsByStatus;
  final int totalCourses;
  final int totalLessons;
  final bool isRefreshing;

  TeacherStatusBoardLoaded({
    required this.coursesByStatus,
    required this.lessonsByStatus,
    required this.totalCourses,
    required this.totalLessons,
    this.isRefreshing = false,
  });

  TeacherStatusBoardLoaded copyWith({
    Map<String, List<CourseModel>>? coursesByStatus,
    Map<String, List<LessonModel>>? lessonsByStatus,
    int? totalCourses,
    int? totalLessons,
    bool? isRefreshing,
  }) {
    return TeacherStatusBoardLoaded(
      coursesByStatus: coursesByStatus ?? this.coursesByStatus,
      lessonsByStatus: lessonsByStatus ?? this.lessonsByStatus,
      totalCourses: totalCourses ?? this.totalCourses,
      totalLessons: totalLessons ?? this.totalLessons,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class TeacherStatusBoardFailure extends TeacherStatusBoardState {
  final String error;
  TeacherStatusBoardFailure(this.error);
}