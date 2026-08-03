import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';

abstract class LevelExceptionCreateState {}

class LevelExceptionCreateInitial extends LevelExceptionCreateState {}

class LevelExceptionCreateLoading extends LevelExceptionCreateState {}

class LevelExceptionCreateSuccess extends LevelExceptionCreateState {
  final LevelExceptionModel? data;
  final String message;
  LevelExceptionCreateSuccess({this.data, required this.message});
}

class LevelExceptionCreateFailure extends LevelExceptionCreateState {
  final String message;
  LevelExceptionCreateFailure(this.message);
}