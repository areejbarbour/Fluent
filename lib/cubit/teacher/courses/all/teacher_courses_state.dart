import 'package:fluent/data/models/course_model.dart';

abstract class TeacherCoursesState {}

class TeacherCoursesInitial extends TeacherCoursesState {}
class TeacherCoursesLoading extends TeacherCoursesState {}

class TeacherCoursesLoaded extends TeacherCoursesState {
  final List<CourseModel> allCourses;
  final List<CourseModel> filteredCourses;
  final String currentFilter; // 'all', 'published', 'pending', etc.
  final String searchQuery;

  TeacherCoursesLoaded({
    required this.allCourses,
    required this.filteredCourses,
    required this.currentFilter,
    this.searchQuery = '',
  });

  TeacherCoursesLoaded copyWith({
    List<CourseModel>? allCourses,
    List<CourseModel>? filteredCourses,
    String? currentFilter,
    String? searchQuery,
  }) {
    return TeacherCoursesLoaded(
      allCourses: allCourses ?? this.allCourses,
      filteredCourses: filteredCourses ?? this.filteredCourses,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TeacherCoursesFailure extends TeacherCoursesState {
  final String error;
  TeacherCoursesFailure(this.error);
}