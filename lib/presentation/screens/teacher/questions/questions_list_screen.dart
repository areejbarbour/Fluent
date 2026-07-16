import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/teacher/questions/list/question_list_cubit.dart';
import 'package:fluent/cubit/teacher/questions/list/question_list_state.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'question_detail_screen.dart';
import 'question_form_screen.dart';

class QuestionsListScreen extends StatefulWidget {
  const QuestionsListScreen({super.key});

  @override
  State<QuestionsListScreen> createState() => _QuestionsListScreenState();
}

class _QuestionsListScreenState extends State<QuestionsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestionListCubit>().loadInitial();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final deprecated = _tabController.index == 1;
    context.read<QuestionListCubit>().switchTab(deprecated: deprecated);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<QuestionListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // gradient bg
          Container(decoration: QuestionUI.backgroundGradient()),
          // glowing circles
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
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 12.h),
                _buildTopBar(),
                SizedBox(height: 16.h),
                _buildTitle(),
                SizedBox(height: 18.h),
                _buildTabs(),
                SizedBox(height: 12.h),
                Expanded(
                  child: BlocBuilder<QuestionListCubit, QuestionListState>(
                    builder: (context, state) {
                      if (state is QuestionListLoading ||
                          state is QuestionListInitial) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.yellow,
                          ),
                        );
                      }
                      if (state is QuestionListFailure) {
                        return _buildError(state.error);
                      }
                      if (state is QuestionListLoaded) {
                        if (state.questions.isEmpty) {
                          return _buildEmpty(state.isDeprecatedTab);
                        }
                        return RefreshIndicator(
                          color: AppColors.yellow,
                          onRefresh: () =>
                              context.read<QuestionListCubit>().refresh(),
                          child: ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 18.w,
                              vertical: 8.h,
                            ),
                            itemCount:
                                state.questions.length +
                                (state.hasMore ? 1 : 0),
                            separatorBuilder: (_, __) => SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              if (index >= state.questions.length) {
                                return _buildLoadMoreIndicator(
                                  state.isLoadingMore,
                                );
                              }
                              final q = state.questions[index];
                              return _buildQuestionCard(
                                    q,
                                    state.isDeprecatedTab,
                                  )
                                  .animate()
                                  .fadeIn(
                                    duration: 350.ms,
                                    delay: (40 * index).ms,
                                  )
                                  .moveY(begin: 16, end: 0, duration: 350.ms);
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ─── Top bar ─────────────────────────────────────
  // ─── Top bar ─────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.end, // 👈 بدل ما كان في back button وSpacer
        children: [
          BlocBuilder<QuestionListCubit, QuestionListState>(
            builder: (context, state) {
              if (state is QuestionListLoaded) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(
                    "${state.questions.length} / ${state.lastPage * state.questions.length ~/ (state.currentPage == 0 ? 1 : state.currentPage)} questions",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // ─── Title ───────────────────────────────────────
  Widget _buildTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // 👈 توسيط
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // 👈 توسيط الأيقونة مع العنوان
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  color: AppColors.yellow,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "Questions Bank",
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: AppColors.sky.withOpacity(0.7),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            "Manage your question bank",
            textAlign: TextAlign.center, // 👈 توسيط الجملة تحت
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tabs ────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14.r),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.all(4.r),
              labelColor: AppColors.dark,
              unselectedLabelColor: Colors.white.withOpacity(0.85),
              labelStyle: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
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
  }

  // ─── Question card ───────────────────────────────
  Widget _buildQuestionCard(Question q, bool isDeprecated) {
    final color = QuestionUI.typeColor(q.type.value);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(questionId: q.id),
          ),
        );
      },
      child: QuestionUI.glass(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: color.withOpacity(0.6), width: 1.2),
              ),
              child: Icon(
                QuestionUI.typeIcon(q.type.value),
                color: color,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (q.titleQuestionAr.isNotEmpty &&
                      q.titleQuestionAr != q.titleQuestionEn) ...[
                    SizedBox(height: 2.h),
                    Text(
                      q.titleQuestionAr,
                      style: GoogleFonts.cairo(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
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
                      if (isDeprecated)
                        _miniChip(
                          icon: Icons.history,
                          label: 'Has Version',
                          color: Colors.white70,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16.sp,
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
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12.sp),
            SizedBox(width: 3.w),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── States ─────────────────────────────────────
  Widget _buildEmpty(bool deprecated) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Colors.white.withOpacity(0.5),
            size: 64.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            deprecated ? "No deprecated questions" : "No questions yet",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16.sp,
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
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
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
              onPressed: () => context.read<QuestionListCubit>().refresh(),
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
  }

  Widget _buildLoadMoreIndicator(bool isLoading) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.yellow,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                "Scroll for more",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12.sp,
                ),
              ),
      ),
    );
  }

  // ─── FAB ────────────────────────────────────────
  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuestionFormScreen()),
        );
      },
      backgroundColor: AppColors.yellow,
      foregroundColor: AppColors.dark,
      icon: Icon(Icons.add, size: 22.sp),
      label: Text(
        'New',
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
