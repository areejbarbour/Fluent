import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/models/content_status.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'teacher_status_board_state.dart';

class TeacherStatusBoardCubit extends SafeCubit<TeacherStatusBoardState> {
  final LessonRepository lessonRepository;
  final TestRepository testRepository;

  TeacherStatusBoardCubit(this.lessonRepository, this.testRepository)
    : super(TeacherStatusBoardInitial());

  final Set<String> _allowedCourseStatuses = {
    ContentStatus.pending.value,
    ContentStatus.published.value,
    ContentStatus.archived.value,
    ContentStatus.closed.value,
  };

  /// Lessons & tests: exclude published/closed from the status board
  final Set<String> _hiddenLessonAndTestStatuses = {
    ContentStatus.published.value,
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
        emit(
          TeacherStatusBoardFailure(
            coursesResult['message']?.toString() ??
                'Failed to load your courses',
          ),
        );
        return;
      }

      final courses = (coursesResult['data'] as List<CourseModel>? ?? []);
      final coursesByStatus = _emptyBuckets<CourseModel>();

      for (final course in courses) {
        final status = course.status.toLowerCase().trim();
        if (_allowedCourseStatuses.contains(status)) {
          (coursesByStatus[status] ??= []).add(course);
        }
      }

      for (final list in coursesByStatus.values) {
        list.sort((a, b) => a.order.compareTo(b.order));
      }

      final lessonsByStatus = _emptyBuckets<LessonModel>();
      int totalLessons = 0;

      if (courses.isNotEmpty) {
        for (final course in courses) {
          int page = 1;
          const maxPages = 50;

          while (page <= maxPages) {
            final result = await lessonRepository.getLessonsByCourse(
              course.id,
              page: page,
            );

            if (result['success'] != true) break;

            final paginated = result['data'] as PaginatedLessons;

            for (final lesson in paginated.lessons) {
              final withCourse = lesson.copyWith(courseName: course.name);
              final status = withCourse.status.toLowerCase().trim();
              if (_hiddenLessonAndTestStatuses.contains(status)) continue;
              (lessonsByStatus[status] ??= []).add(withCourse);
              totalLessons++;
            }

            if (!paginated.hasMore) break;
            page++;
          }
        }
      }

      for (final list in lessonsByStatus.values) {
        list.sort((a, b) {
          final courseCompare = (a.courseName ?? '').compareTo(
            b.courseName ?? '',
          );
          if (courseCompare != 0) return courseCompare;
          return a.order.compareTo(b.order);
        });
      }

      final testsResult = await testRepository.getTeacherTests();
      final tests = testsResult['success'] == true
          ? (testsResult['data'] as List<TestModel>)
          : <TestModel>[];

      final testsByStatus = _emptyBuckets<TestModel>();
      int visibleTests = 0;
      for (final test in tests) {
        final status = test.normalizedStatus;
        if (_hiddenLessonAndTestStatuses.contains(status)) continue;
        if (testsByStatus.containsKey(status)) {
          testsByStatus[status]!.add(test);
        } else {
          (testsByStatus[ContentStatus.draft.value] ??= []).add(test);
        }
        visibleTests++;
      }

      for (final list in testsByStatus.values) {
        list.sort((a, b) {
          final typeCompare = a.normalizedTestableType.compareTo(
            b.normalizedTestableType,
          );
          if (typeCompare != 0) return typeCompare;
          return a.titleEn.compareTo(b.titleEn);
        });
      }

      emit(
        TeacherStatusBoardLoaded(
          coursesByStatus: coursesByStatus,
          lessonsByStatus: lessonsByStatus,
          testsByStatus: testsByStatus,
          totalCourses: courses.length,
          totalLessons: totalLessons,
          totalTests: visibleTests,
        ),
      );
    } catch (e) {
      emit(TeacherStatusBoardFailure(e.toString()));
    }
  }

  Map<String, List<T>> _emptyBuckets<T>() {
    return {for (final s in ContentStatus.values) s.value: <T>[]};
  }
}
