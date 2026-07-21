// teacher_home_state.dart

abstract class TeacherHomeState {
  @override
  List<Object?> get props => [];
}

class TeacherHomeInitial extends TeacherHomeState {}

class TeacherHomeLoading extends TeacherHomeState {}

class TeacherHomeLoaded extends TeacherHomeState {
  final int totalCourses;
  final int totalLessons;
  final int totalQuestions;

  TeacherHomeLoaded({
    required this.totalCourses,
    required this.totalLessons,
    required this.totalQuestions,
  });

  @override
  List<Object?> get props => [totalCourses, totalLessons, totalQuestions];
}

class TeacherHomeFailure extends TeacherHomeState {
  final String error;
  TeacherHomeFailure(this.error);

  @override
  List<Object?> get props => [error];
}
