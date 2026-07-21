import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/content_status.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'teacher_status_board_state.dart';

class TeacherStatusBoardCubit extends Cubit<TeacherStatusBoardState> {
  final LessonRepository lessonRepository;
  TeacherStatusBoardCubit(this.lessonRepository) : super(TeacherStatusBoardInitial());

  // ✅ Allowed statuses for Courses only
  final Set<String> _allowedCourseStatuses = {
    ContentStatus.pending.value,
    ContentStatus.published.value,
    ContentStatus.archived.value,
    ContentStatus.closed.value,
  };

  Future<void> loadAll() async {
    emit(TeacherStatusBoardLoading());
    await _fetchAll();
  }

  Future<void> refresh() async {
    final current = state;
    if (current is TeacherStatusBoardLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(TeacherStatusBoardLoading());
    }
    await _fetchAll();
  }

  Future<void> _fetchAll() async {
    try {
      final coursesResult = await lessonRepository.getTeacherCourses();
      if (coursesResult['success'] != true) {
        emit(TeacherStatusBoardFailure(coursesResult['message']?.toString() ?? 'Failed to load your courses'));
        return;
      }

      final courses = (coursesResult['data'] as List<CourseModel>? ?? []);
      final coursesByStatus = _emptyBuckets<CourseModel>();
      
      // ✅ Filter courses to only show allowed statuses
      for (final course in courses) {
        if (_allowedCourseStatuses.contains(course.status)) {
          (coursesByStatus[course.status] ??= []).add(course);
        }
      }
      
      for (final list in coursesByStatus.values) {
        list.sort((a, b) => a.order.compareTo(b.order));
      }

      if (courses.isEmpty) {
        emit(TeacherStatusBoardLoaded(
          coursesByStatus: coursesByStatus,
          lessonsByStatus: _emptyBuckets<LessonModel>(),
          totalCourses: 0,
          totalLessons: 0,
        ));
        return;
      }

      final lessonsByStatus = _emptyBuckets<LessonModel>();
      int totalLessons = 0;

      for (final course in courses) {
        int page = 1;
        const maxPages = 50;
        while (page <= maxPages) {
          final result = await lessonRepository.getLessonsByCourse(course.id, page: page);
          if (result['success'] != true) break;
          
          final paginated = result['data'] as PaginatedLessons;
          for (final lesson in paginated.lessons) {
            final withCourse = lesson.copyWith(courseName: course.name);
            (lessonsByStatus[withCourse.status] ??= []).add(withCourse);
            totalLessons++;
          }
          if (!paginated.hasMore) break;
          page++;
        }
      }

      for (final list in lessonsByStatus.values) {
        list.sort((a, b) {
          final courseCompare = (a.courseName ?? '').compareTo(b.courseName ?? '');
          if (courseCompare != 0) return courseCompare;
          return a.order.compareTo(b.order);
        });
      }

      emit(TeacherStatusBoardLoaded(
        coursesByStatus: coursesByStatus,
        lessonsByStatus: lessonsByStatus,
        totalCourses: courses.length,
        totalLessons: totalLessons,
      ));
    } catch (e) {
      emit(TeacherStatusBoardFailure(e.toString()));
    }
  }

  Map<String, List<T>> _emptyBuckets<T>() {
    return {for (final s in ContentStatus.values) s.value: <T>[]};
  }
}