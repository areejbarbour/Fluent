import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'teacher_course_detail_state.dart';

class TeacherCourseDetailCubit extends SafeCubit<TeacherCourseDetailState> {
  final LessonRepository lessonRepository;
  final TestRepository testRepository;
  final CourseModel course;

  TeacherCourseDetailCubit(
    this.lessonRepository,
    this.testRepository,
    this.course,
  ) : super(TeacherCourseDetailInitial());

  Future<void> loadLessons() async {
    emit(TeacherCourseDetailLoading());
    try {
      // 1) الدروس
      final allLessons = <LessonModel>[];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final result = await lessonRepository.getLessonsByCourse(
          course.id,
          page: page,
        );
        if (result['success'] != true) {
          final msg = result['message']?.toString() ?? 'Failed to load lessons';
          emit(TeacherCourseDetailFailure(msg));
          return;
        }

        final paginated = result['data'] as PaginatedLessons;
        allLessons.addAll(paginated.lessons);
        hasMore = paginated.hasMore;
        page++;
      }

      allLessons.sort((a, b) => a.order.compareTo(b.order));

      // 2) كل الاختبارات
      List<TestModel> tests = [];
      final testsResult = await testRepository.getAllTests();
      if (testsResult['success'] == true) {
        tests = testsResult['data'] as List<TestModel>;
      }

      emit(
        TeacherCourseDetailLoaded(
          course: course,
          lessons: allLessons,
          tests: tests,
        ),
      );
    } catch (e) {
      emit(TeacherCourseDetailFailure(e.toString()));
    }
  }

  Future<void> refresh() async {
    final current = state;
    if (current is TeacherCourseDetailLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    await loadLessons();
  }
}
