import 'package:fluent/data/models/question_model.dart';

abstract class QuestionListState {}

class QuestionListInitial extends QuestionListState {}

class QuestionListLoading extends QuestionListState {}

class QuestionListLoaded extends QuestionListState {
  final List<Question> questions;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;
  final bool isDeprecatedTab;

  QuestionListLoaded({
    required this.questions,
    required this.currentPage,
    required this.lastPage,
    this.isLoadingMore = false,
    this.isDeprecatedTab = false,
  });

  bool get hasMore => currentPage < lastPage;

  QuestionListLoaded copyWith({
    List<Question>? questions,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
    bool? isDeprecatedTab,
  }) {
    return QuestionListLoaded(
      questions: questions ?? this.questions,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isDeprecatedTab: isDeprecatedTab ?? this.isDeprecatedTab,
    );
  }
}

class QuestionListFailure extends QuestionListState {
  final String error;
  final Map<String, dynamic>? errors;
  QuestionListFailure(this.error, {this.errors});
}