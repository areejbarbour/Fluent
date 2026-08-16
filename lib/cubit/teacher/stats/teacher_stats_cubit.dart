import 'package:fluent/data/models/teacher_stats_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/cubit/teacher/stats/teacher_stats_state.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/lesson_repository.dart'; // PaginatedLessons
import 'package:fluent/data/repository/teacher_stats_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';

class TeacherStatsCubit extends SafeCubit<TeacherStatsState> {
  final TeacherStatsRepository statsRepository;
  final LessonRepository lessonRepository;
  final TestRepository testRepository;

  TeacherStatsCubit({
    required this.statsRepository,
    required this.lessonRepository,
    required this.testRepository,
  }) : super(const TeacherStatsState());

  /// Load teacher's courses (entry point).
  Future<void> loadCourses() async {
    emit(
      state.copyWith(
        status: TeacherStatsStatus.loading,
        message: null,
        clearSelectedCourse: true,
        clearCourseStats: true,
        clearSelectedTest: true,
        clearTestStats: true,
        courseTests: const [],
      ),
    );

    final result = await lessonRepository.getTeacherCourses();
    if (result['success'] == true && result['data'] is List) {
      final courses = (result['data'] as List)
          .whereType<CourseModel>()
          .toList();
      // Prefer published / live courses first, then by order.
      courses.sort((a, b) {
        final aPub = a.status.toLowerCase() == 'published' ? 0 : 1;
        final bPub = b.status.toLowerCase() == 'published' ? 0 : 1;
        if (aPub != bPub) return aPub.compareTo(bPub);
        return a.order.compareTo(b.order);
      });
      emit(state.copyWith(status: TeacherStatsStatus.loaded, courses: courses));
    } else {
      emit(
        state.copyWith(
          status: TeacherStatsStatus.error,
          message: result['message']?.toString() ?? 'Failed to load courses',
        ),
      );
    }
  }

  /// Select a course → load course stats + related tests.
  Future<void> selectCourse(int courseId) async {
    if (state.selectedCourseId == courseId && state.courseStats != null) {
      return;
    }

    emit(
      state.copyWith(
        selectedCourseId: courseId,
        courseStatsLoading: true,
        clearCourseStats: true,
        clearSelectedTest: true,
        clearTestStats: true,
        courseTests: const [],
        message: null,
      ),
    );

    // Parallel: course stats + lessons (for lesson ids) + all teacher tests
    final results = await Future.wait([
      statsRepository.getCourseStats(courseId),
      _loadLessonsMeta(courseId),
      testRepository.getTeacherTests(),
    ]);

    final statsRes = results[0] as Map<String, dynamic>;
    final lessonsMeta =
        results[1] as ({Set<int> ids, Map<int, String> titlesEn});
    final lessonIds = lessonsMeta.ids;
    final lessonTitlesEn = lessonsMeta.titlesEn;
    final testsRes = results[2] as Map<String, dynamic>;

    CourseStats? courseStats;
    String? errorMsg;

    if (statsRes['success'] == true && statsRes['data'] is CourseStats) {
      courseStats = statsRes['data'] as CourseStats;
    } else {
      errorMsg =
          statsRes['message']?.toString() ?? 'Failed to load course statistics';
    }

    List<TestModel> relatedTests = [];
    if (testsRes['success'] == true && testsRes['data'] is List) {
      final all = (testsRes['data'] as List).whereType<TestModel>().toList();
      relatedTests = all.where((t) {
        if (t.isCourseTest && t.testableId == courseId) return true;
        if (t.isLessonTest && lessonIds.contains(t.testableId)) return true;
        return false;
      }).toList();
      // Prefer published first
      relatedTests.sort((a, b) {
        final aPub = a.normalizedStatus == 'published' ? 0 : 1;
        final bPub = b.normalizedStatus == 'published' ? 0 : 1;
        return aPub.compareTo(bPub);
      });
    }

    emit(
      state.copyWith(
        courseStats: courseStats,
        courseStatsLoading: false,
        courseTests: relatedTests,
        lessonTitlesEn: lessonTitlesEn,
        message: errorMsg,
        status: TeacherStatsStatus.loaded,
      ),
    );
  }

  /// Load detailed stats for a specific test.
  Future<void> selectTest(int testId) async {
    if (state.selectedTestId == testId && state.testStats != null) {
      return;
    }

    emit(
      state.copyWith(
        selectedTestId: testId,
        testStatsLoading: true,
        clearTestStats: true,
        questionTitlesEn: const {},
        message: null,
      ),
    );

    // Parallel: stats + test detail (for English question titles)
    final results = await Future.wait([
      statsRepository.getTestStats(testId),
      testRepository.getTestById(testId),
    ]);

    final result = results[0] as Map<String, dynamic>;
    final testDetail = results[1] as Map<String, dynamic>;

    final titlesEn = <int, String>{};
    if (testDetail['success'] == true && testDetail['data'] is TestModel) {
      final test = testDetail['data'] as TestModel;
      for (final q in test.questions) {
        final en = q.titleQuestionEn.trim();
        if (en.isNotEmpty) titlesEn[q.id] = en;
      }
    }

    if (result['success'] == true && result['data'] is TestStats) {
      emit(
        state.copyWith(
          testStats: result['data'] as TestStats,
          testStatsLoading: false,
          questionTitlesEn: titlesEn,
        ),
      );
    } else {
      emit(
        state.copyWith(
          testStatsLoading: false,
          questionTitlesEn: titlesEn,
          message:
              result['message']?.toString() ?? 'Failed to load test statistics',
        ),
      );
    }
  }

  void clearTestSelection() {
    emit(
      state.copyWith(
        clearSelectedTest: true,
        clearTestStats: true,
        questionTitlesEn: const {},
      ),
    );
  }

  void clearCourseSelection() {
    emit(
      state.copyWith(
        clearSelectedCourse: true,
        clearCourseStats: true,
        clearSelectedTest: true,
        clearTestStats: true,
        courseTests: const [],
        lessonTitlesEn: const {},
      ),
    );
  }

  /// Fetch lesson ids + English titles for a course (handles pagination).
  Future<({Set<int> ids, Map<int, String> titlesEn})> _loadLessonsMeta(
    int courseId,
  ) async {
    final ids = <int>{};
    final titlesEn = <int, String>{};
    var page = 1;
    var lastPage = 1;

    do {
      final res = await lessonRepository.getLessonsByCourse(
        courseId,
        page: page,
      );
      if (res['success'] != true) break;

      final data = res['data'];
      if (data is PaginatedLessons) {
        for (final l in data.lessons) {
          ids.add(l.id);
          if (l.titleEn.trim().isNotEmpty) {
            titlesEn[l.id] = l.titleEn.trim();
          }
        }
        lastPage = data.lastPage;
      } else if (data is List) {
        for (final l in data) {
          if (l is LessonModel) {
            ids.add(l.id);
            if (l.titleEn.trim().isNotEmpty) {
              titlesEn[l.id] = l.titleEn.trim();
            }
          }
        }
        break;
      } else {
        break;
      }
      page++;
    } while (page <= lastPage && page <= 20); // safety cap

    return (ids: ids, titlesEn: titlesEn);
  }
}
