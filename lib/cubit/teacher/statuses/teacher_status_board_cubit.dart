import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/models/content_status.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'teacher_status_board_state.dart';

class TeacherStatusBoardCubit extends Cubit<TeacherStatusBoardState> {
  final LessonRepository lessonRepository;
  final TestRepository testRepository; // ✅ تم إضافته

  TeacherStatusBoardCubit(this.lessonRepository, this.testRepository)
      : super(TeacherStatusBoardInitial());

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
      // 1. Fetch Courses (نفس كودك)
      final coursesResult = await lessonRepository.getTeacherCourses();
      if (coursesResult['success'] != true) {
        emit(TeacherStatusBoardFailure(coursesResult['message']?.toString() ?? 'Failed to load your courses'));
        return;
      }
      final courses = (coursesResult['data'] as List<CourseModel>? ?? []);
      final coursesByStatus = _emptyBuckets<CourseModel>();
      
      for (final course in courses) {
        if (_allowedCourseStatuses.contains(course.status)) {
          (coursesByStatus[course.status] ??= []).add(course);
        }
      }
      for (final list in coursesByStatus.values) {
        list.sort((a, b) => a.order.compareTo(b.order));
      }

      // 2. Fetch Lessons (نفس كودك)
      final lessonsByStatus = _emptyBuckets<LessonModel>();
      int totalLessons = 0;
      
      if (courses.isNotEmpty) {
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
      }

      for (final list in lessonsByStatus.values) {
        list.sort((a, b) {
          final courseCompare = (a.courseName ?? '').compareTo(b.courseName ?? '');
          if (courseCompare != 0) return courseCompare;
          return a.order.compareTo(b.order);
        });
      }

      // 3. ✅ Fetch Tests (جلب الاختبارات من الـ API الجديد)
      final testsResult = await testRepository.getTeacherTests();
      final tests = testsResult['success'] == true ? (testsResult['data'] as List<TestModel>) : <TestModel>[];
      final testsByStatus = _emptyBuckets<TestModel>();
      
      for (final test in tests) {
        (testsByStatus[test.status] ??= []).add(test);
      }

      emit(TeacherStatusBoardLoaded(
        coursesByStatus: coursesByStatus,
        lessonsByStatus: lessonsByStatus,
        testsByStatus: testsByStatus,
        totalCourses: courses.length,
        totalLessons: totalLessons,
        totalTests: tests.length,
      ));
    } catch (e) {
      emit(TeacherStatusBoardFailure(e.toString()));
    }
  }

  Map<String, List<T>> _emptyBuckets<T>() {
    return {for (final s in ContentStatus.values) s.value: <T>[]};
  }
}