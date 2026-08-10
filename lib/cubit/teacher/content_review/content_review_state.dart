import 'package:fluent/data/models/content_review_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';

class ContentReviewState {
  final bool loading;
  final bool actionSuccess;
  final String? message;
  final String? error;
  final Map? errors;

  final LessonModel? lesson;
  final TestModel? test;
  final ContentReviewSession? review;

  final bool historyLoading;
  final String? historyError;
  final List<ReviewHistoryItem> history;

  const ContentReviewState({
    this.loading = false,
    this.actionSuccess = false,
    this.message,
    this.error,
    this.errors,
    this.lesson,
    this.test,
    this.review,
    this.historyLoading = false,
    this.historyError,
    this.history = const [],
  });

  ContentReviewState copyWith({
    bool? loading,
    bool? actionSuccess,
    String? message,
    String? error,
    Map? errors,
    LessonModel? lesson,
    TestModel? test,
    ContentReviewSession? review,
    bool? historyLoading,
    String? historyError,
    List<ReviewHistoryItem>? history,
  }) {
    return ContentReviewState(
      loading: loading ?? this.loading,
      actionSuccess: actionSuccess ?? this.actionSuccess,
      message: message,
      error: error,
      errors: errors,
      lesson: lesson ?? this.lesson,
      test: test ?? this.test,
      review: review ?? this.review,
      historyLoading: historyLoading ?? this.historyLoading,
      historyError: historyError,
      history: history ?? this.history,
    );
  }
}
