// lib/cubit/teacher/courses/form/lesson_delete_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/lesson_repository.dart';

abstract class LessonDeleteState {}
class LessonDeleteInitial extends LessonDeleteState {}
class LessonDeleteLoading extends LessonDeleteState {}
class LessonDeleteSuccess extends LessonDeleteState {
  final String message;
  LessonDeleteSuccess(this.message);
}
class LessonDeleteFailure extends LessonDeleteState {
  final String error;
  LessonDeleteFailure(this.error);
}
