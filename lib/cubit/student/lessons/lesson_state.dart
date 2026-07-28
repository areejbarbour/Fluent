import '../../../data/models/student_lesson_model.dart';

abstract class StudentLessonsState {}

class StudentLessonsInitial extends StudentLessonsState {}

class StudentLessonsLoading extends StudentLessonsState {}

class StudentLessonsSuccess extends StudentLessonsState {
  final StudentLessonsModel data;
  StudentLessonsSuccess(this.data);
}

class StudentLessonsFailure extends StudentLessonsState {
  final String message;
  StudentLessonsFailure(this.message);
}