import 'package:fluent/data/models/level_exception_model.dart';

abstract class LevelExceptionState {}

class LevelExceptionInitial extends LevelExceptionState {}

class LevelExceptionLoading extends LevelExceptionState {}

class LevelExceptionSuccess extends LevelExceptionState {
  final List<LevelExceptionModel> exceptions;
  final String status; // pending | rejected | approved

  LevelExceptionSuccess(this.exceptions, this.status);
}

class LevelExceptionFailure extends LevelExceptionState {
  final String message;
  LevelExceptionFailure(this.message);
}