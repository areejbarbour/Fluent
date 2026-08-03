import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';

abstract class LevelExceptionDeleteState {}

class LevelExceptionDeleteInitial extends LevelExceptionDeleteState {}

class LevelExceptionDeleteLoading extends LevelExceptionDeleteState {
  final int id;
  LevelExceptionDeleteLoading(this.id);
}

class LevelExceptionDeleteSuccess extends LevelExceptionDeleteState {
  final int id;
  final String message;
  LevelExceptionDeleteSuccess({required this.id, required this.message});
}

class LevelExceptionDeleteFailure extends LevelExceptionDeleteState {
  final String message;
  LevelExceptionDeleteFailure(this.message);
}