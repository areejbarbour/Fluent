import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'teacher_course_detail_state.dart';

class TeacherCourseDetailCubit extends Cubit<TeacherCourseDetailState> {
  final LessonRepository lessonRepository;
  final CourseModel course;

  TeacherCourseDetailCubit(this.lessonRepository, this.course)
      : super(TeacherCourseDetailInitial());

  Future<void> loadLessons() async {
    emit(TeacherCourseDetailLoading());
    try {
      final allLessons = <LessonModel>[];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final result = await lessonRepository.getLessonsByCourse(course.id, page: page);
        if (result['success'] != true) break;

        final paginated = result['data'] as PaginatedLessons;
        allLessons.addAll(paginated.lessons);
        hasMore = paginated.hasMore;
        page++;
      }

      // Sort by order
      allLessons.sort((a, b) => a.order.compareTo(b.order));

      emit(TeacherCourseDetailLoaded(
        course: course,
        lessons: allLessons,
      ));
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