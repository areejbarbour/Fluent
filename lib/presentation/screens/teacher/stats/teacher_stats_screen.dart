import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/teacher/stats/teacher_stats_cubit.dart';
import 'package:fluent/cubit/teacher/stats/teacher_stats_state.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/teacher_stats_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Teacher stats — visual language matched to NotificationsScreen.
class TeacherStatsScreen extends StatefulWidget {
  const TeacherStatsScreen({super.key});

  @override
  State<TeacherStatsScreen> createState() => _TeacherStatsScreenState();
}

class _TeacherStatsScreenState extends State<TeacherStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TeacherStatsCubit>().loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff020B18),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const _StatsBackdrop(),
          SafeArea(
            child: BlocBuilder<TeacherStatsCubit, TeacherStatsState>(
              builder: (context, state) {
                return Column(
                  children: [
                    _buildAppBar(state),
                    Expanded(child: _buildBody(state)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(TeacherStatsState state) {
    final showingCourse = state.selectedCourseId != null;
    final showingTest = state.selectedTestId != null;

    String title = 'My teaching results';
    String? subtitle = 'See how your students are doing';
    if (showingTest && state.selectedTest != null) {
      title = 'Test results';
      final t = state.selectedTest!;
      subtitle = t.titleEn.isNotEmpty ? t.titleEn : t.titleAr;
    } else if (showingCourse && state.selectedCourse != null) {
      title = 'Course results';
      subtitle = state.selectedCourse!.name;
    }

    final loading =
        state.status == TeacherStatsStatus.loading ||
        state.courseStatsLoading ||
        state.testStatsLoading;

    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 6.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              final cubit = context.read<TeacherStatsCubit>();
              if (showingTest) {
                cubit.clearTestSelection();
              } else if (showingCourse) {
                cubit.clearCourseSelection();
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white.withOpacity(0.92),
              size: 18.sp,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (loading)
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.yellow.withOpacity(0.9),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(TeacherStatsState state) {
    if (state.status == TeacherStatsStatus.loading && state.courses.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      );
    }
    if (state.status == TeacherStatsStatus.error && state.courses.isEmpty) {
      return _ErrorView(
        message: state.message ?? 'Something went wrong. Please try again.',
        onRetry: () => context.read<TeacherStatsCubit>().loadCourses(),
      );
    }
    if (state.selectedTestId != null) return _TestStatsView(state: state);
    if (state.selectedCourseId != null) return _CourseStatsView(state: state);
    return _CoursesListView(state: state);
  }
}

// ═══════════════════════════════════════════════════════════
// Backdrop (same language as NotificationsScreen)
// ═══════════════════════════════════════════════════════════

class _StatsBackdrop extends StatelessWidget {
  const _StatsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xff020B18),
                Color(0xff072238),
                AppColors.primary,
                Color(0xff01344F),
                Color(0xff020B18),
              ],
              stops: [0.0, 0.22, 0.55, 0.8, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -100.h,
          right: -60.w,
          child: _GlowBlob(color: AppColors.yellow, size: 280.w, opacity: 0.14),
        ),
        Positioned(
          top: 320.h,
          left: -80.w,
          child: _GlowBlob(color: AppColors.sky, size: 240.w, opacity: 0.10),
        ),
        Positioned(
          bottom: 80.h,
          right: -40.w,
          child: _GlowBlob(
            color: const Color(0xffB861F5),
            size: 200.w,
            opacity: 0.08,
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _GlowBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Glass card helper
// ═══════════════════════════════════════════════════════════

BoxDecoration _glassCard({bool highlight = false, Color? accent}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(18.r),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: highlight
          ? [Colors.white.withOpacity(0.10), Colors.white.withOpacity(0.045)]
          : [Colors.white.withOpacity(0.07), Colors.white.withOpacity(0.03)],
    ),
    border: Border.all(
      color: accent != null
          ? accent.withOpacity(0.35)
          : Colors.white.withOpacity(0.08),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.18),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════
// Courses list
// ═══════════════════════════════════════════════════════════

class _CoursesListView extends StatelessWidget {
  final TeacherStatsState state;
  const _CoursesListView({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.courses.isEmpty) {
      return _EmptyView(
        icon: Icons.insights_outlined,
        title: 'No courses yet',
        body:
            'When you add a course, you will see how students are doing here.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
      physics: const BouncingScrollPhysics(),
      itemCount: state.courses.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: _InfoBanner(
              text:
                  'Choose a course to see how many students pass, who drops out, and which lessons need attention.',
            ),
          ).animate().fadeIn(duration: 280.ms);
        }
        final course = state.courses[index - 1];
        return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _CourseCard(
                course: course,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<TeacherStatsCubit>().selectCourse(course.id);
                },
              ),
            )
            .animate()
            .fadeIn(delay: (30 * index).ms, duration: 280.ms)
            .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  const _CourseCard({required this.course, required this.onTap});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'published':
        return const Color(0xFF4ADE80);
      case 'pending':
        return AppColors.lightOrange;
      case 'archived':
        return Colors.white38;
      case 'closed':
        return const Color(0xFFF87171);
      default:
        return AppColors.sky;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'published':
        return 'Live';
      case 'pending':
        return 'In preparation';
      case 'archived':
        return 'Archived';
      case 'closed':
        return 'Closed';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(course.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        splashColor: AppColors.sky.withOpacity(0.08),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: _glassCard(highlight: true),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.sky.withOpacity(0.28),
                      AppColors.primary.withOpacity(0.45),
                    ],
                  ),
                  border: Border.all(color: AppColors.sky.withOpacity(0.25)),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.sky,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name.isNotEmpty ? course.name : 'Untitled course',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        _Pill(
                          label: _statusLabel(course.status),
                          color: statusColor,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Order ${course.order}',
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Course detail + expandable sections
// ═══════════════════════════════════════════════════════════

class _CourseStatsView extends StatefulWidget {
  final TeacherStatsState state;
  const _CourseStatsView({required this.state});

  @override
  State<_CourseStatsView> createState() => _CourseStatsViewState();
}

class _CourseStatsViewState extends State<_CourseStatsView> {
  bool _lessonsExpanded = false;
  bool _testsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.courseStatsLoading && state.courseStats == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      );
    }

    final stats = state.courseStats;
    final course = state.selectedCourse;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
      physics: const BouncingScrollPhysics(),
      children: [
        if (state.message != null && stats == null)
          _ErrorBanner(message: state.message!)
        else if (stats != null) ...[
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Passed on first try',
                  value: '${stats.avgFirstAttemptPassRate.toStringAsFixed(1)}%',
                  accent: const Color(0xFF4ADE80),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MetricCard(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Left without finishing',
                  value: '${stats.avgAbandonmentRate.toStringAsFixed(1)}%',
                  accent: const Color(0xFFF87171),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 260.ms),
          SizedBox(height: 18.h),
          _ExpandableSectionHeader(
            title: 'How students move through lessons',
            subtitle:
                'How many opened each lesson, and how many started its test',
            icon: Icons.filter_alt_outlined,
            expanded: _lessonsExpanded,
            onToggle: () {
              HapticFeedback.selectionClick();
              setState(() => _lessonsExpanded = !_lessonsExpanded);
            },
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Column(
                children: [
                  if (stats.lessonsFunnel.isEmpty)
                    _EmptyHint(
                      text:
                          'No activity yet. Numbers appear after lessons are published and students start learning.',
                    )
                  else
                    ...stats.lessonsFunnel.map((item) {
                      final en = state.lessonTitlesEn[item.lessonId];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: _FunnelTile(
                          item: item,
                          titleOverride: (en != null && en.isNotEmpty)
                              ? en
                              : null,
                        ),
                      );
                    }),
                ],
              ),
            ),
            crossFadeState: _lessonsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
        ],
        SizedBox(height: 18.h),
        _ExpandableSectionHeader(
          title: 'Tests in this course',
          subtitle: 'Tap a test to see scores and which questions are hard',
          icon: Icons.quiz_outlined,
          expanded: _testsExpanded,
          onToggle: () {
            HapticFeedback.selectionClick();
            setState(() => _testsExpanded = !_testsExpanded);
          },
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Column(
              children: [
                if (state.courseTests.isEmpty)
                  _EmptyHint(
                    text: course?.status.toLowerCase() == 'published'
                        ? 'No tests in this course yet.'
                        : 'Publish the course and its tests to see student results here.',
                  )
                else
                  ...state.courseTests.map((t) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _TestListTile(
                        test: t,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.read<TeacherStatsCubit>().selectTest(t.id);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
          crossFadeState: _testsExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}

class _ExpandableSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpandableSectionHeader({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: _glassCard(),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.sky.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.sky.withOpacity(0.22)),
                ),
                child: Icon(icon, color: AppColors.sky, size: 16.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 11.sp,
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.0 : 0.5,
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                  size: 24.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FunnelTile extends StatelessWidget {
  final LessonFunnelItem item;
  final String? titleOverride;
  const _FunnelTile({required this.item, this.titleOverride});

  @override
  Widget build(BuildContext context) {
    final rate = item.conversionRate;
    final displayTitle =
        (titleOverride != null && titleOverride!.trim().isNotEmpty)
        ? titleOverride!.trim()
        : (item.title.isNotEmpty ? item.title : 'Lesson #${item.lessonId}');

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: _glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sky.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.sky.withOpacity(0.25)),
                ),
                child: Text(
                  '${item.order}',
                  style: GoogleFonts.poppins(
                    color: AppColors.sky,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  displayTitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${rate.toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: (rate / 100).clamp(0.0, 1.0),
              minHeight: 6.h,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.sky),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _MiniStat(label: 'Opened lesson', value: '${item.reached}'),
              SizedBox(width: 16.w),
              _MiniStat(
                label: 'Started the test',
                value: '${item.attemptedTest}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Test detail
// ═══════════════════════════════════════════════════════════

class _TestStatsView extends StatelessWidget {
  final TeacherStatsState state;
  const _TestStatsView({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.testStatsLoading && state.testStats == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      );
    }

    final stats = state.testStats;
    if (stats == null) {
      return _ErrorView(
        message:
            state.message ?? 'Could not load test results. Please try again.',
        onRetry: () {
          final id = state.selectedTestId;
          if (id != null) context.read<TeacherStatsCubit>().selectTest(id);
        },
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.emoji_events_outlined,
                label: 'Passed on first try',
                value: '${stats.firstAttemptPassRate.toStringAsFixed(1)}%',
                accent: const Color(0xFF4ADE80),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetricCard(
                icon: Icons.replay_rounded,
                label: 'Tries needed to pass',
                value: stats.avgAttemptsToPass.toStringAsFixed(1),
                accent: AppColors.sky,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.exit_to_app_rounded,
                label: 'Left without finishing',
                value: '${stats.abandonmentRate.toStringAsFixed(1)}%',
                accent: const Color(0xFFF87171),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetricCard(
                icon: Icons.psychology_alt_outlined,
                label: 'Still have not passed',
                value: '${stats.currentlyStrugglingRate.toStringAsFixed(1)}%',
                accent: AppColors.orange,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 260.ms),
        SizedBox(height: 20.h),
        _SectionLabel(
          title: 'How students scored',
          subtitle: 'Best score each student got on this test',
          icon: Icons.bar_chart_rounded,
        ),
        SizedBox(height: 10.h),
        _ScoreDistributionChart(buckets: stats.scoreDistribution),
        SizedBox(height: 20.h),
        _SectionLabel(
          title: 'Questions that need attention',
          subtitle:
              'Harder questions appear first. Orange flags mean something unusual.',
          icon: Icons.help_outline_rounded,
        ),
        SizedBox(height: 10.h),
        if (stats.questions.isEmpty)
          _EmptyHint(text: 'No student answers yet for these questions.')
        else
          ...stats.questions.map((q) {
            final en = state.questionTitlesEn[q.questionId];
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _QuestionStatTile(
                item: q,
                titleOverride: (en != null && en.isNotEmpty) ? en : null,
              ),
            );
          }),
      ],
    );
  }
}

class _ScoreDistributionChart extends StatelessWidget {
  final List<ScoreBucket> buckets;
  const _ScoreDistributionChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return _EmptyHint(text: 'No scores yet.');

    final maxCount = buckets
        .map((b) => b.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final total = buckets.fold<int>(0, (s, b) => s + b.count);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _glassCard(),
      child: Column(
        children: buckets.map((b) {
          final ratio = maxCount > 0 ? b.count / maxCount : 0.0;
          final pct = total > 0 ? (b.count / total) * 100 : 0.0;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                SizedBox(
                  width: 52.w,
                  child: Text(
                    b.range,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 10.h,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(_colorFor(b.range)),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                SizedBox(
                  width: 64.w,
                  child: Text(
                    '${b.count} (${pct.toStringAsFixed(0)}%)',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _colorFor(String range) {
    switch (range) {
      case '0-49':
        return const Color(0xFFF87171);
      case '50-69':
        return AppColors.orange;
      case '70-89':
        return AppColors.yellow;
      case '90-100':
        return const Color(0xFF4ADE80);
      default:
        return AppColors.sky;
    }
  }
}

class _QuestionStatTile extends StatelessWidget {
  final QuestionStatItem item;
  final String? titleOverride;
  const _QuestionStatTile({required this.item, this.titleOverride});

  Color _diffColor(String d) {
    switch (d) {
      case 'EASY':
        return const Color(0xFF4ADE80);
      case 'HARD':
        return const Color(0xFFF87171);
      default:
        return AppColors.yellow;
    }
  }

  String _diffLabel(String d) {
    switch (d) {
      case 'EASY':
        return 'Easy';
      case 'HARD':
        return 'Hard';
      case 'MEDIUM':
        return 'Medium';
      default:
        return d;
    }
  }

  String _friendlyFlag(String? flag) {
    switch (flag) {
      case 'unexpected_high_error':
        return 'Students struggle more than expected';
      case 'unexpectedly_easy':
        return 'Students find this easier than expected';
      default:
        return flag ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = item.errorRate;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: _glassCard(accent: item.hasFlag ? AppColors.orange : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  (titleOverride != null && titleOverride!.trim().isNotEmpty)
                      ? titleOverride!.trim()
                      : (item.title.isNotEmpty
                            ? item.title
                            : 'Question #${item.questionId}'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              _Pill(
                label: _diffLabel(item.difficulty),
                color: _diffColor(item.difficulty),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _MiniStat(
                label: 'Wrong answers',
                value: error != null ? '${error.toStringAsFixed(1)}%' : '—',
              ),
              SizedBox(width: 14.w),
              _MiniStat(
                label: 'Average score',
                value: item.avgScoreRatio != null
                    ? '${item.avgScoreRatio!.toStringAsFixed(1)}%'
                    : '—',
              ),
              SizedBox(width: 14.w),
              _MiniStat(
                label: 'Times answered',
                value: '${item.attemptsCount}',
              ),
            ],
          ),
          if (item.hasFlag) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.orange.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_rounded,
                    size: 14.sp,
                    color: AppColors.orange,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _friendlyFlag(item.flag),
                      style: GoogleFonts.poppins(
                        color: AppColors.orange,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TestListTile extends StatelessWidget {
  final TestModel test;
  final VoidCallback onTap;
  const _TestListTile({required this.test, required this.onTap});

  String _typeLabel(String t) {
    switch (t.toLowerCase()) {
      case 'course':
        return 'Course test';
      case 'lesson':
        return 'Lesson test';
      default:
        return t;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'published':
        return 'Live';
      case 'pending':
        return 'Submitted';
      case 'draft':
        return 'Draft';
      case 'in_review':
        return 'Under review';
      case 'changes_requested':
        return 'Needs changes';
      case 'approved':
        return 'Approved';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = test.titleEn.isNotEmpty ? test.titleEn : test.titleAr;
    final isPub = test.normalizedStatus == 'published';
    final accent = isPub ? const Color(0xFF4ADE80) : AppColors.sky;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        splashColor: accent.withOpacity(0.08),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: _glassCard(),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: accent.withOpacity(0.14),
                  border: Border.all(color: accent.withOpacity(0.28)),
                ),
                child: Icon(Icons.quiz_rounded, size: 18.sp, color: accent),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '${_typeLabel(test.normalizedTestableType)} · ${_statusLabel(test.normalizedStatus)} · pass mark ${test.passingScore}',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Shared atoms
// ═══════════════════════════════════════════════════════════

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: _glassCard(highlight: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Icon(icon, color: accent, size: 16.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 10.sp,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  const _SectionLabel({required this.title, this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.sky.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.sky.withOpacity(0.22)),
          ),
          child: Icon(icon, color: AppColors.sky, size: 16.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11.sp,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10.sp),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [
                AppColors.sky.withOpacity(0.14),
                AppColors.primary.withOpacity(0.18),
              ],
            ),
            border: Border.all(color: AppColors.sky.withOpacity(0.28)),
          ),
          child: Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.sky, size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
      decoration: _glassCard(),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12.sp),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(36.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Icon(icon, size: 28.sp, color: Colors.white38),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: const Color(0xFFF87171).withOpacity(0.12),
        border: Border.all(color: const Color(0xFFF87171).withOpacity(0.35)),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          color: const Color(0xFFF87171),
          fontSize: 12.sp,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42.sp,
              color: Colors.white38,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.dark),
              label: Text(
                'Try again',
                style: GoogleFonts.poppins(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.yellow,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
