// teacher_home_state.dart

import 'package:fluent/data/models/test_model.dart';

abstract class TeacherHomeState {
  @override
  List<Object?> get props => [];
}

class TeacherHomeInitial extends TeacherHomeState {}

class TeacherHomeLoading extends TeacherHomeState {}

class TeacherHomeLoaded extends TeacherHomeState {
  final int totalCourses;
  final int totalLessons;
  final int totalQuestions;
  final int totalTests;

  // ✅ تفصيل حالات الاختبارات
  final int publishedTests;
  final int draftTests;
  final int pendingTests;
  final int inReviewTests;
  final int approvedTests;
  final int archivedTests;
  final int closedTests;
  final int changesRequestedTests;

  // ✅ أحدث الاختبارات (حتى 3)
  final List<TestModel> recentTests;

  TeacherHomeLoaded({
    required this.totalCourses,
    required this.totalLessons,
    required this.totalQuestions,
    required this.totalTests,
    this.publishedTests = 0,
    this.draftTests = 0,
    this.pendingTests = 0,
    this.inReviewTests = 0,
    this.approvedTests = 0,
    this.archivedTests = 0,
    this.closedTests = 0,
    this.changesRequestedTests = 0,
    this.recentTests = const [],
  });

  @override
  List<Object?> get props => [
    totalCourses,
    totalLessons,
    totalQuestions,
    totalTests,
    publishedTests,
    draftTests,
    pendingTests,
    inReviewTests,
    approvedTests,
    archivedTests,
    closedTests,
    changesRequestedTests,
    recentTests,
  ];
}

class TeacherHomeFailure extends TeacherHomeState {
  final String error;
  TeacherHomeFailure(this.error);

  @override
  List<Object?> get props => [error];
}
