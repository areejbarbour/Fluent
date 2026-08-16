import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/content_review_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/content_review_repository.dart';
import 'content_review_state.dart';

class ContentReviewCubit extends SafeCubit<ContentReviewState> {
  final ContentReviewRepository repository;

  ContentReviewCubit(this.repository) : super(const ContentReviewState());

  Future<void> submitLesson(int lessonId) async {
    emit(state.copyWith(loading: true, error: null, actionSuccess: false));
    final result = await repository.submitLesson(lessonId);
    if (result['success'] == true) {
      emit(
        state.copyWith(
          loading: false,
          actionSuccess: true,
          message: result['message']?.toString(),
          lesson: result['lesson'] as LessonModel?,
          test: result['test'] as TestModel?,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loading: false,
          actionSuccess: false,
          error: result['message']?.toString() ?? 'Failed to submit lesson',
          errors: result['errors'] as Map?,
        ),
      );
    }
  }

  Future<void> resubmitLesson(int lessonId) async {
    emit(state.copyWith(loading: true, error: null, actionSuccess: false));
    final result = await repository.resubmitLesson(lessonId);
    if (result['success'] == true) {
      emit(
        state.copyWith(
          loading: false,
          actionSuccess: true,
          message: result['message']?.toString(),
          lesson: result['lesson'] as LessonModel?,
          review: result['review'] as ContentReviewSession?,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loading: false,
          actionSuccess: false,
          error: result['message']?.toString() ?? 'Failed to resubmit lesson',
          errors: result['errors'] as Map?,
        ),
      );
    }
  }

  Future<void> submitTest(int testId) async {
    emit(state.copyWith(loading: true, error: null, actionSuccess: false));
    final result = await repository.submitTest(testId);
    if (result['success'] == true) {
      emit(
        state.copyWith(
          loading: false,
          actionSuccess: true,
          message: result['message']?.toString(),
          test: result['test'] as TestModel?,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loading: false,
          actionSuccess: false,
          error: result['message']?.toString() ?? 'Failed to submit test',
          errors: result['errors'] as Map?,
        ),
      );
    }
  }

  Future<void> resubmitTest(int testId) async {
    emit(state.copyWith(loading: true, error: null, actionSuccess: false));
    final result = await repository.resubmitTest(testId);
    if (result['success'] == true) {
      emit(
        state.copyWith(
          loading: false,
          actionSuccess: true,
          message: result['message']?.toString(),
          test: result['test'] as TestModel?,
          review: result['review'] as ContentReviewSession?,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loading: false,
          actionSuccess: false,
          error: result['message']?.toString() ?? 'Failed to resubmit test',
          errors: result['errors'] as Map?,
        ),
      );
    }
  }

  Future<void> loadLessonHistory(int lessonId) async {
    emit(state.copyWith(historyLoading: true, historyError: null));
    final result = await repository.lessonReviewHistory(lessonId);
    if (result['success'] == true) {
      emit(
        state.copyWith(
          historyLoading: false,
          history: result['history'] as List<ReviewHistoryItem>? ?? [],
        ),
      );
    } else {
      emit(
        state.copyWith(
          historyLoading: false,
          historyError:
              result['message']?.toString() ?? 'Failed to load history',
        ),
      );
    }
  }

  Future<void> loadTestHistory(int testId) async {
    emit(state.copyWith(historyLoading: true, historyError: null));
    final result = await repository.testReviewHistory(testId);
    if (result['success'] == true) {
      emit(
        state.copyWith(
          historyLoading: false,
          history: result['history'] as List<ReviewHistoryItem>? ?? [],
        ),
      );
    } else {
      emit(
        state.copyWith(
          historyLoading: false,
          historyError:
              result['message']?.toString() ?? 'Failed to load history',
        ),
      );
    }
  }

  void clearActionResult() {
    emit(
      state.copyWith(
        actionSuccess: false,
        error: null,
        message: null,
        errors: null,
      ),
    );
  }
}
