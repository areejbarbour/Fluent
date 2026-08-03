import 'package:fluent/data/models/level_exception_model.dart';
abstract class LevelExceptionUpdateState {}

class LevelExceptionUpdateInitial extends LevelExceptionUpdateState {}

class LevelExceptionUpdateLoading extends LevelExceptionUpdateState {}

class LevelExceptionUpdateSuccess extends LevelExceptionUpdateState {
  final LevelExceptionModel? updated;
  final String message;
  LevelExceptionUpdateSuccess({this.updated, required this.message});
}

class LevelExceptionUpdateFailure extends LevelExceptionUpdateState {
  final String message;
  LevelExceptionUpdateFailure(this.message);
}