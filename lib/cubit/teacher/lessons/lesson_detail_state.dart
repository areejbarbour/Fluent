import 'package:fluent/data/models/test_model.dart';

abstract class LessonDetailState {}

class LessonDetailInitial extends LessonDetailState {}

class LessonDetailLoading extends LessonDetailState {}

class LessonDetailLoaded extends LessonDetailState {
  final dynamic lesson;
  final List<TestModel> tests;
  final List<dynamic> comments;

  LessonDetailLoaded({
    required this.lesson,
    required this.tests,
    required this.comments,
  });
}

class LessonDetailError extends LessonDetailState {
  final String message;

  LessonDetailError({required this.message});
}

class DeletingTest extends LessonDetailState {}

class TestDeletedSuccess extends LessonDetailState {
  final String message;

  TestDeletedSuccess({required this.message});
}
