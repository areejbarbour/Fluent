import '../../../data/models/level_model.dart';

abstract class StudentLevelsState {}

class StudentLevelsInitial extends StudentLevelsState {}

class StudentLevelsLoading extends StudentLevelsState {}

class StudentLevelsSuccess extends StudentLevelsState {
  final StudentLevelsModel data;
  StudentLevelsSuccess(this.data);
}

class StudentLevelsFailure extends StudentLevelsState {
  final String message;
  StudentLevelsFailure(this.message);
}