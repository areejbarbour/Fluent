import '../../../data/models/course_model.dart';

abstract class StudentCoursesState {}

class StudentCoursesInitial extends StudentCoursesState {}

class StudentCoursesLoading extends StudentCoursesState {}

class StudentCoursesSuccess extends StudentCoursesState {
  final StudentCoursesModel data;
  StudentCoursesSuccess(this.data);
}

class StudentCoursesFailure extends StudentCoursesState {
  final String message;
  StudentCoursesFailure(this.message);
}