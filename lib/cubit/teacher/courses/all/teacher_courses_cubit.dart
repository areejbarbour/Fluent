import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'teacher_courses_state.dart';

class TeacherCoursesCubit extends Cubit<TeacherCoursesState> {
  final LessonRepository lessonRepository;
  TeacherCoursesCubit(this.lessonRepository) : super(TeacherCoursesInitial());

  Future<void> loadCourses() async {
    emit(TeacherCoursesLoading());
    try {
      final result = await lessonRepository.getTeacherCourses();
      if (result['success'] == true) {
        final courses = result['data'] as List<CourseModel>;
        emit(TeacherCoursesLoaded(
          allCourses: courses,
          filteredCourses: courses,
          currentFilter: 'all',
        ));
      } else {
        emit(TeacherCoursesFailure(result['message'] ?? 'Failed to load courses'));
      }
    } catch (e) {
      emit(TeacherCoursesFailure(e.toString()));
    }
  }

  void filterByStatus(String status) {
    final current = state;
    if (current is! TeacherCoursesLoaded) return;

    final filtered = status == 'all'
        ? current.allCourses
        : current.allCourses.where((c) => c.status == status).toList();

    emit(current.copyWith(
      filteredCourses: filtered,
      currentFilter: status,
    ));
  }

  void searchCourses(String query) {
    final current = state;
    if (current is! TeacherCoursesLoaded) return;

    final filtered = query.isEmpty
        ? (current.currentFilter == 'all' 
            ? current.allCourses 
            : current.allCourses.where((c) => c.status == current.currentFilter).toList())
        : current.allCourses.where((c) {
            final matchesStatus = current.currentFilter == 'all' || c.status == current.currentFilter;
            final matchesSearch = c.name.toLowerCase().contains(query.toLowerCase());
            return matchesStatus && matchesSearch;
          }).toList();

    emit(current.copyWith(
      filteredCourses: filtered,
      searchQuery: query,
    ));
  }

  Future<void> refresh() async {
    await loadCourses();
  }
}