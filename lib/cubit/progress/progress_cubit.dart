import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/repository/progress_repository.dart';
import 'progress_state.dart';

class ProgressCubit extends SafeCubit<ProgressState> {
  final ProgressRepository repository;

  ProgressCubit(this.repository) : super(const ProgressInitial());

  /// GET /api/courses/{course}/progress
  Future<void> loadCourseProgress(int courseId) async {
    emit(ProgressLoading(scope: 'course', id: courseId));
    final result = await repository.getCourseProgress(courseId);
    if (result['success'] == true && result['data'] is num) {
      emit(
        ProgressSuccess(
          scope: 'course',
          id: courseId,
          percentage: (result['data'] as num).toDouble(),
        ),
      );
    } else {
      emit(
        ProgressFailure(
          scope: 'course',
          id: courseId,
          message: result['message']?.toString() ?? 'Failed to load progress',
        ),
      );
    }
  }

  /// GET /api/levels/{level}/progress
  Future<void> loadLevelProgress(int levelId) async {
    emit(ProgressLoading(scope: 'level', id: levelId));
    final result = await repository.getLevelProgress(levelId);
    if (result['success'] == true && result['data'] is num) {
      emit(
        ProgressSuccess(
          scope: 'level',
          id: levelId,
          percentage: (result['data'] as num).toDouble(),
        ),
      );
    } else {
      emit(
        ProgressFailure(
          scope: 'level',
          id: levelId,
          message: result['message']?.toString() ?? 'Failed to load progress',
        ),
      );
    }
  }
}
