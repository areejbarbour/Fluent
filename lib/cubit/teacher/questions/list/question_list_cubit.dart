import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'question_list_state.dart';

class QuestionListCubit extends Cubit<QuestionListState> {
  final QuestionRepository questionRepository;

  QuestionListCubit(this.questionRepository) : super(QuestionListInitial());

  bool _showingDeprecated = false;
  bool get isShowingDeprecated => _showingDeprecated;

  /// Loads the first page (active or deprecated based on flag)
  Future<void> loadInitial({bool deprecated = false}) async {
    _showingDeprecated = deprecated;
    emit(QuestionListLoading());
    await _fetch(page: 1, deprecated: deprecated);
  }

  /// Switches between Active ↔ Deprecated tabs
  Future<void> switchTab({required bool deprecated}) async {
    if (_showingDeprecated == deprecated && state is QuestionListLoaded) {
      return;
    }
    await loadInitial(deprecated: deprecated);
  }

  /// Loads next page (if available)
  Future<void> loadMore() async {
    final s = state;
    if (s is! QuestionListLoaded) return;
    if (!s.hasMore || s.isLoadingMore) return;

    emit(s.copyWith(isLoadingMore: true));
    await _fetch(
      page: s.currentPage + 1,
      deprecated: s.isDeprecatedTab,
      append: true,
    );
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    await _fetch(page: 1, deprecated: _showingDeprecated);
  }

  Future<void> _fetch({
    required int page,
    required bool deprecated,
    bool append = false,
  }) async {
    print("🟡 [QuestionListCubit] fetch page=$page deprecated=$deprecated");

    try {
      final result = deprecated
          ? await questionRepository.getDeprecatedQuestions(page: page)
          : await questionRepository.getQuestions(page: page);

      final success = result['success'] as bool? ?? false;
      if (success) {
        final data = result['data'];
        if (data is PaginatedQuestions) {
          final current = state is QuestionListLoaded
              ? (state as QuestionListLoaded)
              : null;
          final merged = append && current != null
              ? [...current.questions, ...data.questions]
              : data.questions;
          emit(QuestionListLoaded(
            questions: merged,
            currentPage: data.currentPage,
            lastPage: data.lastPage,
            isLoadingMore: false,
            isDeprecatedTab: deprecated,
          ));
        } else {
          emit(QuestionListFailure('Unexpected response format'));
        }
      } else {
        final msg = result['message']?.toString() ?? 'Failed to load questions';
        emit(QuestionListFailure(
          msg,
          errors: result['errors'] as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      emit(QuestionListFailure(e.toString()));
    }
  }

  /// Removes a deleted question from the list (used after delete)
  void removeQuestion(int id) {
    final s = state;
    if (s is QuestionListLoaded) {
      final updated = s.questions.where((q) => q.id != id).toList();
      emit(s.copyWith(questions: updated));
    }
  }
}