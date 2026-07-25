import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'question_filter_state.dart';

class QuestionFilterCubit extends Cubit<QuestionFilterState> {
  final QuestionRepository questionRepository;

  // متغيرات لتخزين حالة الفلتر الحالية لدعم الـ Pagination
  String? _type;
  String? _difficulty;
  int? _minScore;
  int? _maxScore;
  String? _search;
  int? _courseId;
  bool? _onlyEligible;
  String? _sort;
  int _currentPage = 1;

  QuestionFilterCubit(this.questionRepository) : super(QuestionFilterInitial());

  bool get hasActiveFilters =>
      _type != null ||
      _difficulty != null ||
      _minScore != null ||
      _maxScore != null ||
      (_search != null && _search!.trim().isNotEmpty) ||
      _courseId != null ||
      _sort != null;

  // تطبيق الفلاتر (يعيد الصفحة إلى 1)
  Future<void> applyFilters({
    String? type,
    String? difficulty,
    int? minScore,
    int? maxScore,
    String? search,
    int? courseId,
    bool? onlyEligible,
    String? sort,
  }) async {
    _type = type;
    _difficulty = difficulty;
    _minScore = minScore;
    _maxScore = maxScore;
    _search = search;
    _courseId = courseId;
    _onlyEligible = onlyEligible;
    _sort = sort;
    _currentPage = 1;

    emit(QuestionFilterLoading());
    await _fetch();
  }

  // تحميل الصفحة التالية (Infinite Scroll)
  Future<void> loadMore() async {
    final current = state;
    if (current is! QuestionFilterLoaded) return;
    if (current.currentPage >= current.lastPage) return;
    if (current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    _currentPage = current.currentPage + 1;

    final result = await questionRepository.filterQuestions(
      page: _currentPage,
      type: _type,
      difficulty: _difficulty,
      minScore: _minScore,
      maxScore: _maxScore,
      search: _search,
      courseId: _courseId,
      onlyEligible: _onlyEligible,
      sort: _sort,
    );

    if (result['success'] == true) {
      final paginated = result['data'] as PaginatedQuestions;
      emit(current.copyWith(
        questions: [...current.questions, ...paginated.questions],
        currentPage: paginated.currentPage,
        lastPage: paginated.lastPage,
        total: paginated.total,
        isLoadingMore: false,
      ));
    } else {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  // مسح جميع الفلاتر والعودة للقائمة الأصلية
  Future<void> clearFilters() async {
    _type = null;
    _difficulty = null;
    _minScore = null;
    _maxScore = null;
    _search = null;
    _courseId = null;
    _onlyEligible = null;
    _sort = null;
    _currentPage = 1;

    emit(QuestionFilterInitial());
  }

  Future<void> _fetch() async {
    final result = await questionRepository.filterQuestions(
      page: _currentPage,
      type: _type,
      difficulty: _difficulty,
      minScore: _minScore,
      maxScore: _maxScore,
      search: _search,
      courseId: _courseId,
      onlyEligible: _onlyEligible,
      sort: _sort,
    );

    if (result['success'] == true) {
      final paginated = result['data'] as PaginatedQuestions;

      if (paginated.questions.isEmpty) {
        emit(QuestionFilterEmpty('No questions match your filters.'));
      } else {
        emit(QuestionFilterLoaded(
          questions: paginated.questions,
          currentPage: paginated.currentPage,
          lastPage: paginated.lastPage,
          total: paginated.total,
          hasActiveFilters: hasActiveFilters,
        ));
      }
    } else {
      emit(QuestionFilterFailure(
        result['message'] ?? 'Something went wrong',
        errors: result['errors'],
      ));
    }
  }
}