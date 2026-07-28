import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/questions/list/question_list_cubit.dart';
import 'package:fluent/cubit/teacher/questions/list/question_list_state.dart';
import 'package:fluent/cubit/teacher/questions/question_filter/question_filter_cubit.dart';
import 'package:fluent/cubit/teacher/questions/question_filter/question_filter_state.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:fluent/presentation/screens/teacher/questions/question_detail_screen.dart';
import 'package:fluent/presentation/screens/teacher/questions/question_filter_sheet.dart';
import 'package:fluent/presentation/screens/teacher/questions/question_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionsListScreen extends StatefulWidget {
  const QuestionsListScreen({super.key});

  @override
  State<QuestionsListScreen> createState() => _QuestionsListScreenState();
}

class _QuestionsListScreenState extends State<QuestionsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // ✅ متغيرات الفلترة
  String? _filterType;
  String? _filterDifficulty;
  int? _filterMinScore;
  int? _filterMaxScore;
  String? _filterSearch;
  String? _filterSort;

  // ✅ متغيرات وضع إنشاء الاختبار
  int? _filterCourseId;
  bool? _filterOnlyEligible;
  bool _fromTestCreation = false;
  final List<Question> _selectedQuestionsForTest = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // ✅ استقبال الـ Arguments عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _filterCourseId = args['courseId'] as int?;
          _filterOnlyEligible = args['onlyEligible'] as bool?;
          _fromTestCreation = args['fromTestCreation'] as bool? ?? false;
        });

        // ✅ تطبيق الفلاتر تلقائياً إذا كنا قادمين من إنشاء اختبار
        if (_fromTestCreation) {
          context.read<QuestionFilterCubit>().applyFilters(
            courseId: _filterCourseId,
            onlyEligible: _filterOnlyEligible,
          );
        } else {
          context.read<QuestionListCubit>().loadInitial();
        }
      } else {
        context.read<QuestionListCubit>().loadInitial();
      }
    });
  }

  void _selectQuestionAndReturn(Question question) {
    if (_fromTestCreation) {
      // إرجاع السؤال إلى شاشة إنشاء الاختبار
      Navigator.pop(context, [question]);
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (!_fromTestCreation) {
      context.read<QuestionListCubit>().switchTab(
        deprecated: _tabController.index == 1,
      );
    }
  }

  void _onScroll() {
    if (!_hasActiveFilters &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      context.read<QuestionListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _filterType != null ||
      _filterDifficulty != null ||
      _filterMinScore != null ||
      _filterMaxScore != null ||
      (_filterSearch != null && _filterSearch!.trim().isNotEmpty) ||
      _filterSort != null ||
      _filterCourseId != null ||
      _filterOnlyEligible != null;

  // ✅ فتح نافذة الفلترة
  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestionFilterSheet(
        initialType: _filterType,
        initialDifficulty: _filterDifficulty,
        initialMinScore: _filterMinScore,
        initialMaxScore: _filterMaxScore,
        initialSearch: _filterSearch,
        initialSort: _filterSort,

        // ✅ إذا جاي من إنشاء اختبار كورس
        initialCourseId: _fromTestCreation ? _filterCourseId : null,
        initialOnlyEligible: _fromTestCreation ? _filterOnlyEligible : null,
        hideEligibleToggle: !_fromTestCreation || _filterCourseId == null,
      ),
    );
    if (result != null && context.mounted) {
      setState(() {
        _filterType = result['type'];
        _filterDifficulty = result['difficulty'];
        _filterMinScore = result['min_score'];
        _filterMaxScore = result['max_score'];
        _filterSearch = result['search'];
        _filterSort = result['sort'];
        _filterCourseId = result['courseId'];
        _filterOnlyEligible = result['onlyEligible'];
      });
      context.read<QuestionFilterCubit>().applyFilters(
        type: _filterType,
        difficulty: _filterDifficulty,
        minScore: _filterMinScore,
        maxScore: _filterMaxScore,
        search: _filterSearch,
        sort: _filterSort,
        courseId: _filterCourseId,
        onlyEligible: _filterOnlyEligible,
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _filterDifficulty = null;
      _filterMinScore = null;
      _filterMaxScore = null;
      _filterSearch = null;
      _filterSort = null;
      if (!_fromTestCreation) {
        _filterCourseId = null;
        _filterOnlyEligible = null;
      }
    });
    context.read<QuestionFilterCubit>().clearFilters();
  }

  // ✅ دالة لإضافة/إزالة سؤال من القائمة المختارة
  void _toggleQuestionSelection(Question q) {
    setState(() {
      if (_selectedQuestionsForTest.any((element) => element.id == q.id)) {
        _selectedQuestionsForTest.removeWhere((element) => element.id == q.id);
      } else {
        _selectedQuestionsForTest.add(q);
      }
    });
  }

  // ✅ دالة لإنهاء الاختيار والعودة للشاشة السابقة
  void _finishSelection() {
    Navigator.pop(context, _selectedQuestionsForTest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                _buildHeader(context),
                SizedBox(height: 14.h),
                if (!_hasActiveFilters && !_fromTestCreation) ...[
                  _buildTabs(),
                  SizedBox(height: 10.h),
                ],
                if (_hasActiveFilters) ...[
                  _buildClearFiltersChip(context),
                  SizedBox(height: 10.h),
                ],
                Expanded(
                  child: _hasActiveFilters || _fromTestCreation
                      ? _buildFilterResults(context)
                      : _buildDefaultList(context),
                ),
              ],
            ),
          ),
        ],
      ),
      // ✅ تغيير الـ FAB حسب الوضع
      floatingActionButton: _fromTestCreation
          ? FloatingActionButton.extended(
              onPressed: _selectedQuestionsForTest.isEmpty
                  ? null
                  : _finishSelection,
              backgroundColor: _selectedQuestionsForTest.isEmpty
                  ? Colors.grey
                  : AppColors.yellow,
              foregroundColor: AppColors.dark,
              icon: Icon(Icons.check, size: 20.sp),
              label: Text(
                'Add (${_selectedQuestionsForTest.length})',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : _buildFab(),
    );
  }

  // ─────────────────────────────────────────────────────
  // ✅ UI Components
  // ─────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_fromTestCreation)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: EdgeInsets.all(8.r),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        ),
                      ),
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.yellow.withOpacity(0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.quiz_outlined,
                        color: AppColors.yellow,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _fromTestCreation
                              ? "Select Questions"
                              : "Questions Bank",
                          style: GoogleFonts.cinzelDecorative(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: AppColors.sky.withOpacity(0.7),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  _fromTestCreation
                      ? "Choose questions for your test"
                      : "Manage your question bank",
                  textAlign: TextAlign.start,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          _buildFilterButton(context),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFilterSheet(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: _hasActiveFilters
                  ? AppColors.orange.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _hasActiveFilters
                    ? AppColors.orange
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: _hasActiveFilters ? AppColors.orange : Colors.white,
              size: 20.sp,
            ),
          ),
          if (_hasActiveFilters)
            Positioned(
              top: -4.h,
              right: -4.w,
              child: Container(
                width: 10.w,
                height: 10.w,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClearFiltersChip(BuildContext context) {
    return GestureDetector(
      onTap: _clearFilters,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, color: Colors.redAccent, size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              "Clear Filters",
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: EdgeInsets.all(3.r),
            labelColor: AppColors.dark,
            unselectedLabelColor: Colors.white.withOpacity(0.85),
            labelStyle: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Deprecated'),
            ],
          ),
        ),
      ),
    ),
  );

  // ─────────────────────────────────────────────────────
  // ✅ List Builders
  // ─────────────────────────────────────────────────────

  Widget _buildDefaultList(BuildContext context) {
    return BlocBuilder<QuestionListCubit, QuestionListState>(
      builder: (context, state) {
        if (state is QuestionListLoading || state is QuestionListInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.yellow),
          );
        }
        if (state is QuestionListFailure) return _buildError(state.error);
        if (state is QuestionListLoaded) {
          if (state.questions.isEmpty)
            return _buildEmpty(state.isDeprecatedTab);

          return RefreshIndicator(
            color: AppColors.yellow,
            onRefresh: () => context.read<QuestionListCubit>().refresh(),
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: state.questions.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                if (index >= state.questions.length)
                  return _buildLoadMoreIndicator(state.isLoadingMore);

                final q = state.questions[index];
                return _buildQuestionCard(q, state.isDeprecatedTab)
                    .animate()
                    .fadeIn(duration: 350.ms, delay: (40 * index).ms)
                    .moveY(begin: 16, end: 0, duration: 350.ms);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFilterResults(BuildContext context) {
    return BlocBuilder<QuestionFilterCubit, QuestionFilterState>(
      builder: (context, state) {
        if (state is QuestionFilterLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.yellow),
          );
        }
        if (state is QuestionFilterEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_off_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 56.sp,
                ),
                SizedBox(height: 12.h),
                Text(
                  "No questions match your filters",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, color: AppColors.orange),
                  label: Text(
                    "Clear Filters",
                    style: GoogleFonts.poppins(color: AppColors.orange),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is QuestionFilterLoaded) {
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200) {
                context.read<QuestionFilterCubit>().loadMore();
              }
              return false;
            },
            child: RefreshIndicator(
              color: AppColors.yellow,
              onRefresh: () async {
                await context.read<QuestionFilterCubit>().applyFilters(
                  type: _filterType,
                  difficulty: _filterDifficulty,
                  minScore: _filterMinScore,
                  maxScore: _filterMaxScore,
                  search: _filterSearch,
                  sort: _filterSort,
                  courseId: _filterCourseId,
                  onlyEligible: _filterOnlyEligible,
                );
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount:
                    state.questions.length +
                    (state.currentPage < state.lastPage ? 1 : 0),
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  if (index >= state.questions.length) {
                    return _buildLoadMoreIndicator(state.isLoadingMore);
                  }
                  final q = state.questions[index];
                  return _buildQuestionCard(
                        q,
                        false,
                        isSelectable: _fromTestCreation,
                      )
                      .animate()
                      .fadeIn(duration: 350.ms, delay: (40 * index).ms)
                      .moveY(begin: 16, end: 0, duration: 350.ms);
                },
              ),
            ),
          );
        }
        if (state is QuestionFilterFailure) {
          return _buildError(state.error);
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // ✅ Shared UI Helpers (Preserved from original)
  // ─────────────────────────────────────────────────────

  Widget _buildBackground() => Stack(
    children: [
      Container(decoration: QuestionUI.backgroundGradient()),
      Positioned(
        top: -120.h,
        left: -100.w,
        child: QuestionUI.glowingCircle(AppColors.yellow, 320.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(15, 10),
              duration: 5000.ms,
            ),
      ),
      Positioned(
        bottom: -160.h,
        right: -110.w,
        child: QuestionUI.glowingCircle(AppColors.sky, 380.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(-20, -15),
              duration: 6000.ms,
            ),
      ),
    ],
  );

  Widget _buildQuestionCard(
    Question q,
    bool isDeprecated, {
    bool isSelectable = false,
  }) {
    final color = QuestionUI.typeColor(q.type.value);
    final isSelected = _selectedQuestionsForTest.any(
      (element) => element.id == q.id,
    );

    return GestureDetector(
      onTap: isSelectable
          ? () => _toggleQuestionSelection(q)
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuestionDetailScreen(questionId: q.id),
              ),
            ),
      child: QuestionUI.glass(
        radius: 16,
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelectable) ...[
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.yellow : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.yellow
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: AppColors.dark, size: 16.sp)
                    : null,
              ),
              SizedBox(width: 10.w),
            ],
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: color.withOpacity(0.6), width: 1.2),
              ),
              child: Icon(
                QuestionUI.typeIcon(q.type.value),
                color: color,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.titleQuestionEn.isNotEmpty
                        ? q.titleQuestionEn
                        : q.titleQuestionAr,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 5.w,
                    runSpacing: 4.h,
                    children: [
                      _miniChip(label: q.type.value, color: color),
                      _miniChip(
                        label: q.difficulty.value,
                        color: QuestionUI.difficultyColor(q.difficulty.value),
                      ),
                      _miniChip(
                        icon: Icons.star_rounded,
                        label: '${q.score} pts',
                        color: AppColors.yellow,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelectable)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 14.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip({
    required String label,
    required Color color,
    IconData? icon,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: color.withOpacity(0.18),
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: color.withOpacity(0.45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 11.sp),
          SizedBox(width: 3.w),
        ],
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _buildEmpty(bool deprecated) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.inbox_outlined,
          color: Colors.white.withOpacity(0.5),
          size: 56.sp,
        ),
        SizedBox(height: 12.h),
        Text(
          deprecated ? "No deprecated questions" : "No questions yet",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          deprecated
              ? "Questions with newer versions will appear here"
              : "Create your first question to get started",
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildError(String msg) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.redAccent.withOpacity(0.8),
            size: 56.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            msg,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _hasActiveFilters
                ? _clearFilters
                : () => context.read<QuestionListCubit>().refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.dark,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLoadMoreIndicator(bool isLoading) => Padding(
    padding: EdgeInsets.symmetric(vertical: 10.h),
    child: Center(
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.yellow,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              "Scroll for more",
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11.sp,
              ),
            ),
    ),
  );

  Widget _buildFab() => FloatingActionButton.extended(
    onPressed: () async {
      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(builder: (_) => const QuestionFormScreen()),
      );
      if (!mounted) return;
      // Create form now returns the Question object (or true from older flows)
      if (result == true || result is Question) {
        if (_hasActiveFilters || _fromTestCreation) {
          context.read<QuestionFilterCubit>().applyFilters(
            type: _filterType,
            difficulty: _filterDifficulty,
            minScore: _filterMinScore,
            maxScore: _filterMaxScore,
            search: _filterSearch,
            sort: _filterSort,
            courseId: _filterCourseId,
            onlyEligible: _filterOnlyEligible,
          );
        } else {
          context.read<QuestionListCubit>().loadInitial();
        }
        // If opened from test creation, auto-select the new question
        if (_fromTestCreation && result is Question) {
          setState(() {
            if (!_selectedQuestionsForTest.any((e) => e.id == result.id)) {
              _selectedQuestionsForTest.add(result);
            }
          });
        }
      }
    },
    backgroundColor: AppColors.yellow,
    foregroundColor: AppColors.dark,
    icon: Icon(Icons.add, size: 20.sp),
    label: Text(
      'New',
      style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700),
    ),
  );
}
