import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';

abstract class TeacherCourseDetailState {}

class TeacherCourseDetailInitial extends TeacherCourseDetailState {}
class TeacherCourseDetailLoading extends TeacherCourseDetailState {}

class TeacherCourseDetailLoaded extends TeacherCourseDetailState {
  final CourseModel course;
  final List<LessonModel> lessons;
  final bool isRefreshing;

  TeacherCourseDetailLoaded({
    required this.course,
    required this.lessons,
    this.isRefreshing = false,
  });

  TeacherCourseDetailLoaded copyWith({
    CourseModel? course,
    List<LessonModel>? lessons,
    bool? isRefreshing,
  }) {
    return TeacherCourseDetailLoaded(
      course: course ?? this.course,
      lessons: lessons ?? this.lessons,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class TeacherCourseDetailFailure extends TeacherCourseDetailState {
  final String error;
  TeacherCourseDetailFailure(this.error);
}