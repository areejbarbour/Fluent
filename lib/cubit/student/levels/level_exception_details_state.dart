import 'package:fluent/data/models/level_exception_model.dart';

abstract class LevelExceptionDetailsState {}

class LevelExceptionDetailsInitial extends LevelExceptionDetailsState {}

class LevelExceptionDetailsLoading extends LevelExceptionDetailsState {}

class LevelExceptionDetailsSuccess extends LevelExceptionDetailsState {
  final LevelExceptionModel details;
  LevelExceptionDetailsSuccess(this.details);
}

class LevelExceptionDetailsFailure extends LevelExceptionDetailsState {
  final String message;
  LevelExceptionDetailsFailure(this.message);
}