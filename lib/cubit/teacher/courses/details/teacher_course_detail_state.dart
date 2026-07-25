import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';

abstract class TeacherCourseDetailState {}

class TeacherCourseDetailInitial extends TeacherCourseDetailState {}

class TeacherCourseDetailLoading extends TeacherCourseDetailState {}

class TeacherCourseDetailLoaded extends TeacherCourseDetailState {
  final CourseModel course;
  final List<LessonModel> lessons;
  final List<TestModel> tests;
  final bool isRefreshing;

  TeacherCourseDetailLoaded({
    required this.course,
    required this.lessons,
    this.tests = const [],
    this.isRefreshing = false,
  });

  TeacherCourseDetailLoaded copyWith({
    CourseModel? course,
    List<LessonModel>? lessons,
    List<TestModel>? tests,
    bool? isRefreshing,
  }) {
    return TeacherCourseDetailLoaded(
      course: course ?? this.course,
      lessons: lessons ?? this.lessons,
      tests: tests ?? this.tests,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  /// اختبار الكورس (إن وُجد)
  TestModel? get courseTest {
    final matches = tests.where(
      (t) =>
          t.testableType.toLowerCase() == 'course' && t.testableId == course.id,
    );
    return matches.isEmpty ? null : matches.first;
  }

  /// اختبار درس معيّن
  TestModel? testForLesson(int lessonId) {
    final matches = tests.where(
      (t) =>
          t.testableType.toLowerCase() == 'lesson' && t.testableId == lessonId,
    );
    return matches.isEmpty ? null : matches.first;
  }
}

class TeacherCourseDetailFailure extends TeacherCourseDetailState {
  final String error;
  TeacherCourseDetailFailure(this.error);
}
