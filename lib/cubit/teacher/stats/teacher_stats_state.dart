import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/teacher_stats_model.dart';
import 'package:fluent/data/models/test_model.dart';

enum TeacherStatsStatus { initial, loading, loaded, error }

class TeacherStatsState {
  final TeacherStatsStatus status;
  final String? message;

  final List<CourseModel> courses;

  final int? selectedCourseId;

  final CourseStats? courseStats;
  final bool courseStatsLoading;

  final List<TestModel> courseTests;

  final Map<int, String> lessonTitlesEn;

  final Map<int, String> questionTitlesEn;

  final int? selectedTestId;
  final TestStats? testStats;
  final bool testStatsLoading;

  const TeacherStatsState({
    this.status = TeacherStatsStatus.initial,
    this.message,
    this.courses = const [],
    this.selectedCourseId,
    this.courseStats,
    this.courseStatsLoading = false,
    this.courseTests = const [],
    this.lessonTitlesEn = const {},
    this.questionTitlesEn = const {},
    this.selectedTestId,
    this.testStats,
    this.testStatsLoading = false,
  });

  CourseModel? get selectedCourse {
    if (selectedCourseId == null) return null;
    try {
      return courses.firstWhere((c) => c.id == selectedCourseId);
    } catch (_) {
      return null;
    }
  }

  TestModel? get selectedTest {
    if (selectedTestId == null) return null;
    try {
      return courseTests.firstWhere((t) => t.id == selectedTestId);
    } catch (_) {
      return null;
    }
  }

  TeacherStatsState copyWith({
    TeacherStatsStatus? status,
    String? message,
    List<CourseModel>? courses,
    int? selectedCourseId,
    bool clearSelectedCourse = false,
    CourseStats? courseStats,
    bool clearCourseStats = false,
    bool? courseStatsLoading,
    List<TestModel>? courseTests,
    Map<int, String>? lessonTitlesEn,
    Map<int, String>? questionTitlesEn,
    int? selectedTestId,
    bool clearSelectedTest = false,
    TestStats? testStats,
    bool clearTestStats = false,
    bool? testStatsLoading,
  }) {
    return TeacherStatsState(
      status: status ?? this.status,
      message: message,
      courses: courses ?? this.courses,
      selectedCourseId: clearSelectedCourse
          ? null
          : (selectedCourseId ?? this.selectedCourseId),
      courseStats: clearCourseStats ? null : (courseStats ?? this.courseStats),
      courseStatsLoading: courseStatsLoading ?? this.courseStatsLoading,
      courseTests: courseTests ?? this.courseTests,
      lessonTitlesEn: lessonTitlesEn ?? this.lessonTitlesEn,
      questionTitlesEn: questionTitlesEn ?? this.questionTitlesEn,
      selectedTestId: clearSelectedTest
          ? null
          : (selectedTestId ?? this.selectedTestId),
      testStats: clearTestStats ? null : (testStats ?? this.testStats),
      testStatsLoading: testStatsLoading ?? this.testStatsLoading,
    );
  }
}
