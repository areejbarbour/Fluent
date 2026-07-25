import 'package:fluent/data/models/question_model.dart';

abstract class QuestionFilterState {}

class QuestionFilterInitial extends QuestionFilterState {}

class QuestionFilterLoading extends QuestionFilterState {}

class QuestionFilterLoaded extends QuestionFilterState {
  final List<Question> questions;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoadingMore;
  final bool hasActiveFilters;

  QuestionFilterLoaded({
    required this.questions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.isLoadingMore = false,
    this.hasActiveFilters = false,
  });

  QuestionFilterLoaded copyWith({
    List<Question>? questions,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoadingMore,
    bool? hasActiveFilters,
  }) {
    return QuestionFilterLoaded(
      questions: questions ?? this.questions,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
    );
   }
}

class QuestionFilterEmpty extends QuestionFilterState {
  final String message;
  QuestionFilterEmpty(this.message);
}

class QuestionFilterFailure extends QuestionFilterState {
  final String error;
  final Map<String, dynamic>? errors;
  QuestionFilterFailure(this.error, {this.errors});
}