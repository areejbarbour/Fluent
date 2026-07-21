import 'package:fluent/data/models/lesson_model.dart';

abstract class LessonFormState {}

class LessonFormInitial extends LessonFormState {}
class LessonFormLoading extends LessonFormState {}

class LessonFormSuccess extends LessonFormState {
  final LessonModel lesson;
  LessonFormSuccess(this.lesson);
}

class LessonFormFailure extends LessonFormState {
  final String error;
  final Map<String, dynamic>? errors;
  LessonFormFailure(this.error, {this.errors});
}