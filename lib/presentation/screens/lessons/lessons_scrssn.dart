import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fluent/cubit/student/lessons/lesson_cubit.dart';
import 'package:fluent/cubit/student/lessons/lesson_state.dart';
import 'package:fluent/data/models/student_lesson_model.dart';
import 'package:fluent/data/repository/progress_repository.dart';
import 'package:fluent/presentation/widgets/app_snackbar.dart';

enum LessonStatus { completed, current, locked, quiz }

class LessonData {
  final int? id;
  final String title;
  final String subtitle;
  final LessonStatus status;
  final IconData icon;
  final int xpReward;
  final double progress;

  const LessonData({
    this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    this.xpReward = 20,
    this.progress = 0,
  });
}

class DailyChallengeData {
  final String title;
  final int current;
  final int target;
  final int rewardXp;

  const DailyChallengeData({
    required this.title,
    required this.current,
    required this.target,
    this.rewardXp = 150,
  });

  double get fraction => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

class LessonsScreen extends StatefulWidget {
  final int? courseId;
  final int? testId;
  final String courseTitle;
  final String courseSubtitle;
  final String teacherName;
  final String userName;
  final int xp;
  final double courseProgress;

  final void Function(LessonData lesson)? onLessonTap;
  final VoidCallback? onBack;

  const LessonsScreen({
    super.key,
    this.courseId,
    this.testId,
    this.courseTitle = "Grammar Mastery",
    this.courseSubtitle = "Level 8 · Fluent Instructor",
    this.teacherName = "Fluent Instructor",
    this.userName = "Rasha",
    this.xp = 12540,
    this.courseProgress = 0.45,
    this.onLessonTap,
    this.onBack,
  });

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen>
    with TickerProviderStateMixin {
  int _selectedNavIndex = 0;
  late final AnimationController _pathFlowController;
  late final AnimationController _borderFlowController;
  late final ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  List<LessonData> _lessons = [];

  /// Authoritative progress summary from GET /api/lessons/{course}
  /// (`progress.completed_lessons` / `progress.total_lessons` / `progress.progress_percentage`).
  LessonsProgressSummary _apiProgress = LessonsProgressSummary.empty;

  /// 0.0–1.0 from GET /api/courses/{id}/progress — kept only as a fallback
  /// for when the lessons endpoint hasn't returned progress yet.
  double _apiCourseProgress = 0.0;
  bool _courseProgressLoaded = false;

  bool get _hasApiProgress => _apiProgress.totalLessons > 0;

  double get _effectiveCourseProgress {
    if (_hasApiProgress) {
      return (_apiProgress.progressPercentage / 100.0).clamp(0.0, 1.0);
    }
    return _courseProgressLoaded
        ? _apiCourseProgress
        : widget.courseProgress.clamp(0.0, 1.0);
  }

  int get _completedCount => _hasApiProgress
      ? _apiProgress.completedLessons
      : _lessons.where((l) => l.status == LessonStatus.completed).length;

  int get _totalCount => _hasApiProgress
      ? _apiProgress.totalLessons
      : (_lessons.isNotEmpty ? _lessons.length : 1);

  @override
  void initState() {
    super.initState();
    _pathFlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _borderFlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<StudentLessonsCubit>();
      if (cubit.state is StudentLessonsInitial) {
        cubit.fetchStudentLessons(widget.courseId ?? 0);
      }
      _loadCourseProgress();
    });
  }

  @override
  void dispose() {
    _pathFlowController.dispose();
    _borderFlowController.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  IconData _iconForStatus(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return Icons.menu_book_rounded;
      case LessonStatus.current:
        return Icons.edit_note_rounded;
      case LessonStatus.locked:
        return Icons.lock_rounded;
      case LessonStatus.quiz:
        return Icons.emoji_events_rounded;
    }
  }

  LessonData _toLessonData(StudentLessonModel lesson, LessonStatus status) {
    return LessonData(
      id: lesson.id,
      title: lesson.title,
      subtitle: "Lesson ${lesson.order}",
      status: status,
      icon: _iconForStatus(status),
      xpReward: lesson.xpPoints,
      progress: 0,
    );
  }

  List<LessonData> _mapLessons(StudentLessonsModel data) {
    final combined = <MapEntry<StudentLessonModel, LessonStatus>>[];

    for (final l in data.completedLessons) {
      combined.add(MapEntry(l, LessonStatus.completed));
    }
    if (data.currentLesson != null) {
      combined.add(MapEntry(data.currentLesson!, LessonStatus.current));
    }
    for (final l in data.lockedLessons) {
      combined.add(MapEntry(l, LessonStatus.locked));
    }

    combined.sort((a, b) => a.key.order.compareTo(b.key.order));

    return combined.map((e) => _toLessonData(e.key, e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          _buildBackground(),
          _TwinklingStars(count: 45),
          _FloatingClouds(),
          SafeArea(
            child: BlocBuilder<StudentLessonsCubit, StudentLessonsState>(
              builder: (context, state) {
                if (state is StudentLessonsSuccess) {
                  _lessons = _mapLessons(state.data);
                  _apiProgress = state.data.progress;
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(),
                            SizedBox(height: 16.h),
                            _buildCourseHeroCard(),
                            SizedBox(height: 12.h),
                            _buildCourseApiProgressBar(),
                            SizedBox(height: 14.h),

                            if (state is StudentLessonsLoading ||
                                state is StudentLessonsInitial)
                              _lessonsLoadingCard()
                            else if (state is StudentLessonsFailure)
                              _lessonsErrorCard(state.message)
                            else ...[
                              _buildProgressOverview(),
                              SizedBox(height: 8.h),
                              _PathTransition(),
                              SizedBox(height: 4.h),
                              _LessonsPath(
                                lessons: _lessons,
                                flowController: _pathFlowController,
                                onLessonTap: (lesson) async {
                                  await Navigator.pushNamed(
                                    context,
                                    lessonStudentDetailRoute,
                                    arguments: {
                                      'lessonId': lesson.id ?? 0,
                                      'lessonTitle': lesson.title,
                                    },
                                  );
                                  if (!context.mounted) return;
                                  // Refresh path after test pass / progress change
                                  context
                                      .read<StudentLessonsCubit>()
                                      .fetchStudentLessons(
                                        widget.courseId ?? 0,
                                      );
                                },
                              ),
                              if (widget.testId != null) ...[
                                SizedBox(height: 18.h),
                                _CourseFinalTestCard(
                                  testId: widget.testId!,
                                  courseTitle: widget.courseTitle,
                                  lessonsComplete: _allLessonsComplete(state),
                                  onStart: () => _startCourseTest(
                                    context,
                                    testId: widget.testId!,
                                    courseTitle: widget.courseTitle,
                                  ),
                                ),
                              ],
                            ],
                            SizedBox(height: 110.h),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _allLessonsComplete(StudentLessonsState state) {
    if (state is! StudentLessonsSuccess) return false;
    final d = state.data;
    // Backend path finished when there is no current lesson and nothing locked.
    return d.currentLesson == null && d.lockedLessons.isEmpty;
  }

  Future<void> _startCourseTest(
    BuildContext context, {
    required int testId,
    required String courseTitle,
  }) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.pushNamed(
      context,
      studentTestRoute,
      arguments: {
        'testId': testId,
        'title': '$courseTitle · Final test',
        'xpPoints': 0,
        'source': 'course',
      },
    );
    if (!mounted) return;
    context.read<StudentLessonsCubit>().fetchStudentLessons(
      widget.courseId ?? 0,
    );

    if (result is Map) {
      final passed = result['passed'] == true;
      final goToCourses = result['goToCourses'] == true;
      if (passed && goToCourses) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Widget _lessonsLoadingCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.yellow),
    );
  }

  Widget _lessonsErrorCard(String message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(.10),
                Colors.white.withOpacity(.04),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.15)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: Colors.white.withOpacity(.7),
                size: 28.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.85),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: () => context
                    .read<StudentLessonsCubit>()
                    .fetchStudentLessons(widget.courseId ?? 0),

                // progress refreshed with lessons
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.yellow],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "Retry",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _parallax(double factor, Widget child) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      child: child,
      builder: (context, offset, child) {
        final double shift = (offset * factor).clamp(-40.0, 40.0);
        return Transform.translate(offset: Offset(0, -shift), child: child);
      },
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xff011826),
                AppColors.dark,
                AppColors.primary,
                Color(0xff01466A),
                AppColors.dark,
              ],
              stops: [0.0, 0.2, 0.55, 0.8, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -120.h,
          right: -80.w,
          child: _parallax(
            0.18,
            _glowCircle(AppColors.yellow, 300.w, 160, 40)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(
                  begin: Offset.zero,
                  end: const Offset(-15, 10),
                  duration: 5500.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ),
        Positioned(
          top: 420.h,
          left: -100.w,
          child: _parallax(
            0.12,
            _glowCircle(AppColors.sky, 260.w, 150, 30)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(
                  begin: Offset.zero,
                  end: const Offset(20, 15),
                  duration: 6500.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ),
        Positioned(
          top: 780.h,
          right: -60.w,
          child: _parallax(
            0.09,
            _glowCircle(const Color(0xffB388FF), 220.w, 130, 25)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(
                  begin: Offset.zero,
                  end: const Offset(-10, -8),
                  duration: 7000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _parallax(
            0.05,
            CustomPaint(
              size: Size(double.infinity, 220.h),
              painter: _MountainsPainter(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glowCircle(Color color, double size, double blur, double spread) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.30),
            blurRadius: blur,
            spreadRadius: spread,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: widget.onBack ?? () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.courseTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // _circleIconButton(
        //   icon: Icons.notifications_rounded,
        //   badgeCount: 3,
        //   onTap: () {},
        // ),
      ],
    ).animate().fadeIn(duration: 500.ms).moveY(begin: -10, end: 0);
  }

  Widget _circleIconButton({
    required IconData icon,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(.14),
                  Colors.white.withOpacity(.06),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20.sp),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2.h,
              right: -2.w,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.redAccent, Color(0xFFFF6B6B)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dark, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
                child: Center(
                  child: Text(
                    "$badgeCount",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // حبة صغيرة بنفس ستايل حبات كارد المستويات
  Widget _heroPill(IconData icon, Color color, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: Colors.white.withOpacity(.08),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13.sp),
          SizedBox(width: 6.w),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCourseProgress() async {
    final courseId = widget.courseId;
    if (courseId == null || courseId <= 0) {
      setState(() {
        _apiCourseProgress = widget.courseProgress.clamp(0.0, 1.0);
        _courseProgressLoaded = true;
      });
      return;
    }
    try {
      final repo = context.read<ProgressRepository>();
      final res = await repo.getCourseProgress(courseId);
      if (!mounted) return;
      if (res['success'] == true && res['data'] is num) {
        final pct = (res['data'] as num).toDouble();
        setState(() {
          _apiCourseProgress = (pct / 100.0).clamp(0.0, 1.0);
          _courseProgressLoaded = true;
        });
      } else {
        setState(() {
          _apiCourseProgress = widget.courseProgress.clamp(0.0, 1.0);
          _courseProgressLoaded = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiCourseProgress = widget.courseProgress.clamp(0.0, 1.0);
        _courseProgressLoaded = true;
      });
    }
  }

  Widget _buildCourseApiProgressBar() {
    final progress = _effectiveCourseProgress;
    final pct = (progress * 100).round();
    final value = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.08),
                Colors.white.withOpacity(.03),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    color: AppColors.sky,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Course completion',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: GoogleFonts.poppins(
                      color: AppColors.yellow,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _CourseShinyProgressStrip(value: value),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).moveY(begin: 8, end: 0);
  }

  Widget _buildCourseHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.yellow.withOpacity(.16),
                AppColors.orange.withOpacity(.08),
                AppColors.sky.withOpacity(.10),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.16)),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withOpacity(.16),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CourseOrbitRing(
                    lessons: _lessons,
                    progress: _effectiveCourseProgress,
                    completedOverride: _completedCount,
                    totalOverride: _totalCount,
                    size: 92.w,
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.yellow.withOpacity(.18),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "IN PROGRESS",
                            style: GoogleFonts.poppins(
                              color: AppColors.yellow,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          widget.courseSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.78),
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              color: Colors.white.withOpacity(.5),
                              size: 13.sp,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                widget.teacherName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(.65),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Container(height: 1, color: Colors.white.withOpacity(.10)),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.sky,
                    size: 15.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      "$_completedCount of $_totalCount lessons completed",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).moveY(begin: -8, end: 0);
  }

  Widget _buildProgressOverview() {
    Color dotColor(LessonStatus status) {
      switch (status) {
        case LessonStatus.completed:
          return const Color(0xFF4ADE80);
        case LessonStatus.current:
          return AppColors.yellow;
        case LessonStatus.quiz:
          return const Color(0xffFF6FB5);
        case LessonStatus.locked:
          return Colors.white.withOpacity(.25);
      }
    }

    return _glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      radius: 18.r,
      gradientColors: [
        Colors.white.withOpacity(.08),
        Colors.white.withOpacity(.03),
      ],
      child: Row(
        children: [
          Icon(Icons.route_rounded, color: AppColors.sky, size: 16.sp),
          SizedBox(width: 8.w),
          Text(
            "Lessons Progress",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(_lessons.length, (i) {
              final color = dotColor(_lessons[i].status);
              final isLocked = _lessons[i].status == LessonStatus.locked;
              return Padding(
                padding: EdgeInsets.only(left: 5.w),
                child: Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: isLocked
                        ? []
                        : [
                            BoxShadow(
                              color: color.withOpacity(.7),
                              blurRadius: 5,
                            ),
                          ],
                  ),
                ),
              );
            }),
          ),
          SizedBox(width: 8.w),
          Text(
            "$_completedCount/$_totalCount",
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 280.ms, duration: 500.ms).moveY(begin: 8, end: 0);
  }

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double radius = 20,
    List<Color>? gradientColors,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  gradientColors ??
                  [
                    Colors.white.withOpacity(.10),
                    Colors.white.withOpacity(.04),
                  ],
            ),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// class _CourseOrbitRing extends StatelessWidget {
//   final List<LessonData> lessons;
//   final double progress;
//   final double size;

//   const _CourseOrbitRing({
//     required this.lessons,
//     required this.progress,
//     required this.size,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final double boxSize = size + 34.w;

//     if (lessons.isEmpty) {
//       return SizedBox(width: boxSize, height: boxSize);
//     }

//     Color dotColor(LessonData l) {
//       switch (l.status) {
//         case LessonStatus.completed:
//           return const Color(0xFF4ADE80);
//         case LessonStatus.current:
//           return AppColors.yellow;
//         case LessonStatus.quiz:
//           return const Color(0xffFF6FB5);
//         case LessonStatus.locked:
//           return Colors.white.withOpacity(.25);
//       }
//     }

//     return SizedBox(
//       width: boxSize,
//       height: boxSize,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           ...List.generate(lessons.length, (i) {
//             final angle = -math.pi / 2 + i * (2 * math.pi / lessons.length);
//             final radius = size / 2 + 15.w;
//             final dx = math.cos(angle) * radius;
//             final dy = math.sin(angle) * radius;
//             final lesson = lessons[i];
//             final color = dotColor(lesson);
//             final dotSize = lesson.status == LessonStatus.completed
//                 ? 12.w
//                 : (lesson.status == LessonStatus.quiz ? 12.w : 8.w);

//             Widget dot = Container(
//               width: dotSize,
//               height: dotSize,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: color,
//                 border: lesson.status == LessonStatus.completed
//                     ? Border.all(color: Colors.white, width: 1.1)
//                     : null,
//                 boxShadow: lesson.status == LessonStatus.locked
//                     ? []
//                     : [BoxShadow(color: color.withOpacity(.7), blurRadius: 6)],
//               ),
//               child: lesson.status == LessonStatus.completed
//                   ? Icon(
//                       Icons.check_rounded,
//                       size: dotSize * 0.6,
//                       color: Colors.black,
//                     )
//                   : null,
//             );

//             if (lesson.status == LessonStatus.current) {
//               dot = dot
//                   .animate(onPlay: (c) => c.repeat(reverse: true))
//                   .scale(
//                     begin: const Offset(1, 1),
//                     end: const Offset(1.35, 1.35),
//                     duration: 1100.ms,
//                     curve: Curves.easeInOut,
//                   );
//             }

//             return Transform.translate(offset: Offset(dx, dy), child: dot);
//           }),
//           SizedBox(
//             width: size,
//             height: size,
//             child: CircularProgressIndicator(
//               value: 1,
//               strokeWidth: 8.w,
//               valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(.08)),
//             ),
//           ),
//           SizedBox(
//             width: size,
//             height: size,
//             child: TweenAnimationBuilder<double>(
//               tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
//               duration: 1200.ms,
//               curve: Curves.easeOutCubic,
//               builder: (context, value, _) => CircularProgressIndicator(
//                 value: value,
//                 strokeWidth: 8.w,
//                 strokeCap: StrokeCap.round,
//                 valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
//                 backgroundColor: Colors.transparent,
//               ),
//             ),
//           ),
//           Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                     Icons.auto_awesome_rounded,
//                     color: AppColors.yellow,
//                     size: 16.sp,
//                   )
//                   .animate(onPlay: (c) => c.repeat(reverse: true))
//                   .scale(
//                     begin: const Offset(1, 1),
//                     end: const Offset(1.15, 1.15),
//                     duration: 1600.ms,
//                     curve: Curves.easeInOut,
//                   ),
//               SizedBox(height: 2.h),
//               Text(
//                 "${(progress.clamp(0.0, 1.0) * 100).toInt()}%",
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w800,
//                   fontSize: 13.sp,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

class _CourseOrbitRing extends StatefulWidget {
  final List<LessonData> lessons;
  final double progress;
  final double size;

  /// When provided (from the backend's `progress` summary), these win over
  /// counting `lessons` locally — `lessons` only reflects completed/current/
  /// locked-after-allowed-order, not the real total lesson count.
  final int? completedOverride;
  final int? totalOverride;

  const _CourseOrbitRing({
    required this.lessons,
    required this.progress,
    required this.size,
    this.completedOverride,
    this.totalOverride,
  });

  @override
  State<_CourseOrbitRing> createState() => _CourseOrbitRingState();
}

class _CourseOrbitRingState extends State<_CourseOrbitRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final boxSize = size + 44.w;

    // Prefer the backend's real completed/total counts; only fall back to
    // counting the locally-built `lessons` list (which excludes lessons that
    // are neither completed, current, nor locked-after-allowed-order) when
    // no override was supplied.
    final completed =
        widget.completedOverride ??
        widget.lessons.where((l) => l.status == LessonStatus.completed).length;
    final total =
        widget.totalOverride ??
        (widget.lessons.isEmpty ? 1 : widget.lessons.length);
    final effectiveProgress = widget.progress > 0.01
        ? widget.progress.clamp(0.0, 1.0)
        : (total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0));
    final pct = (effectiveProgress * 100).toInt();

    Color dotColor(LessonData l) {
      switch (l.status) {
        case LessonStatus.completed:
          return const Color(0xFF4ADE80);
        case LessonStatus.current:
          return AppColors.yellow;
        case LessonStatus.quiz:
          return const Color(0xffFF6FB5);
        case LessonStatus.locked:
          return Colors.white.withOpacity(.28);
      }
    }

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Dots around the ring ──────────────────────────────
          if (widget.lessons.isNotEmpty)
            ...List.generate(widget.lessons.length, (i) {
              final angle =
                  -math.pi / 2 + i * (2 * math.pi / widget.lessons.length);
              final radius = size / 2 + 18.w;
              final dx = math.cos(angle) * radius;
              final dy = math.sin(angle) * radius;
              final lesson = widget.lessons[i];
              final color = dotColor(lesson);
              final isCompleted = lesson.status == LessonStatus.completed;
              final isCurrent = lesson.status == LessonStatus.current;
              final isLocked = lesson.status == LessonStatus.locked;
              final dotSize = (isCompleted || isCurrent) ? 12.w : 8.w;

              Widget dot = Container(
                width: dotSize,
                height: dotSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: isCompleted
                      ? Border.all(color: Colors.white, width: 1.4)
                      : (isCurrent
                            ? Border.all(
                                color: AppColors.yellow.withOpacity(.9),
                                width: 1.5,
                              )
                            : null),
                  boxShadow: isLocked
                      ? []
                      : [
                          BoxShadow(
                            color: color.withOpacity(.8),
                            blurRadius: 8,
                            spreadRadius: 0.5,
                          ),
                        ],
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check_rounded,
                        size: dotSize * 0.55,
                        color: Colors.black,
                      )
                    : null,
              );

              if (isCurrent) {
                dot = dot
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.45, 1.45),
                      duration: 900.ms,
                      curve: Curves.easeInOut,
                    );
              }

              return Transform.translate(offset: Offset(dx, dy), child: dot);
            }),

          // ── Soft track (full circle) ──────────────────────────
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 9.5.w,
              valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(.08)),
            ),
          ),

          // ── Progress arc (yellow) ─────────────────────────────
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: effectiveProgress),
              duration: 1400.ms,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value <= 0 ? 0.02 : value, // حتى لو صفر يبين طرف
                  strokeWidth: 9.5.w,
                  strokeCap: StrokeCap.round,
                  valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),

          // ── Moving yellow sweep (زي الكورسات) ─────────────────
          AnimatedBuilder(
            animation: _spinController,
            builder: (context, _) {
              return Transform.rotate(
                angle: _spinController.value * 2 * math.pi,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _SweepArcPainter(
                      color: AppColors.yellow,
                      strokeWidth: 9.5.w,
                    ),
                  ),
                ),
              );
            },
          ),

          Container(
                width: size + 8.w,
                height: size + 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(.16),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.4, end: 0.9, duration: 1800.ms),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.yellow,
                    size: 18.sp,
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.22, 1.22),
                    duration: 1400.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(.55),
                  ),
              SizedBox(height: 2.h),
              Text(
                "$pct%",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                "$completed/$total",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.55),
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 1.w,
            child:
                Container(
                      width: 11.w,
                      height: 11.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.yellow,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.yellow.withOpacity(.75),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.3, 1.3),
                      duration: 1100.ms,
                    ),
          ),
        ],
      ),
    );
  }
}

class _SweepArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _SweepArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.15),
          color.withOpacity(0.85),
          color.withOpacity(0.15),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect.deflate(strokeWidth / 2), 0, math.pi * 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SweepArcPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 40});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(42);
    return IgnorePointer(
      child: Stack(
        children: List.generate(count, (i) {
          final left = rng.nextDouble();
          final top = rng.nextDouble();
          final size = rng.nextDouble() * 2 + 1;
          final delay = rng.nextInt(3000);
          final duration = 1500 + rng.nextInt(2500);
          final maxOpacity = rng.nextDouble() * 0.6 + 0.3;
          final hasGlow = rng.nextBool();

          return Positioned(
            left: left * 1.sw,
            top: top * 1.sh,
            child:
                Container(
                      width: size.w,
                      height: size.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: hasGlow
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.7),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : null,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(
                      begin: 0,
                      end: maxOpacity,
                      duration: duration.ms,
                      delay: delay.ms,
                    )
                    .then()
                    .fade(begin: maxOpacity, end: 0, duration: duration.ms),
          );
        }),
      ),
    );
  }
}

class _FloatingClouds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 160.h,
            left: -40.w,
            child: _cloudBlob(width: 130.w, opacity: .08)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(
                  begin: -10,
                  end: 10,
                  duration: 8000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          Positioned(
            top: 640.h,
            right: -30.w,
            child: _cloudBlob(width: 110.w, opacity: .06)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(
                  begin: 10,
                  end: -10,
                  duration: 10000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          Positioned(
            top: 980.h,
            left: 60.w,
            child: _cloudBlob(width: 90.w, opacity: .05)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: -5,
                  end: 5,
                  duration: 7000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ],
      ),
    );
  }

  Widget _cloudBlob({required double width, required double opacity}) {
    return Container(
      width: width,
      height: width * 0.35,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width),
        gradient: LinearGradient(
          colors: [
            AppColors.sky.withOpacity(opacity),
            AppColors.sky.withOpacity(opacity * 0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withOpacity(opacity),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }
}

class _AnimatedBorderPainter extends CustomPainter {
  final double animationValue;
  final double radius;

  _AnimatedBorderPainter({required this.animationValue, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final startAngle = animationValue * math.pi * 2;

    final glowPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        colors: const [
          Color(0x00FFD35B),
          Color(0x88FFD35B),
          Color(0x00F5A201),
          Color(0x88A8E8F9),
          Color(0x00B388FF),
          Color(0x88FF6FB5),
          Color(0x00FFD35B),
        ],
        stops: const [0.0, 0.14, 0.32, 0.5, 0.68, 0.86, 1.0],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRRect(rect.deflate(4), glowPaint);

    final borderPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        colors: const [
          Color(0xffA8E8F9),
          Color(0xffFFD35B),
          Color(0xffF5A201),
          Color(0xffB388FF),
          Color(0xffA8E8F9),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rect.deflate(0.75), borderPaint);

    final innerGlowPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle + 0.3,
        colors: const [
          Color(0x00FFFFFF),
          Color(0x44FFFFFF),
          Color(0x00FFFFFF),
          Color(0x33FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(rect.deflate(2), innerGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _MountainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final farPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(.0),
          AppColors.primary.withOpacity(.4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final farPath = Path();
    farPath.moveTo(0, size.height * 0.65);
    farPath.lineTo(size.width * 0.18, size.height * 0.4);
    farPath.lineTo(size.width * 0.35, size.height * 0.55);
    farPath.lineTo(size.width * 0.55, size.height * 0.32);
    farPath.lineTo(size.width * 0.75, size.height * 0.5);
    farPath.lineTo(size.width, size.height * 0.42);
    farPath.lineTo(size.width, size.height);
    farPath.lineTo(0, size.height);
    farPath.close();
    canvas.drawPath(farPath, farPaint);

    final nearPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.dark.withOpacity(.0),
          AppColors.dark.withOpacity(.9),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final nearPath = Path();
    nearPath.moveTo(0, size.height * 0.78);
    nearPath.lineTo(size.width * 0.22, size.height * 0.58);
    nearPath.lineTo(size.width * 0.42, size.height * 0.72);
    nearPath.lineTo(size.width * 0.6, size.height * 0.5);
    nearPath.lineTo(size.width * 0.78, size.height * 0.68);
    nearPath.lineTo(size.width, size.height * 0.6);
    nearPath.lineTo(size.width, size.height);
    nearPath.lineTo(0, size.height);
    nearPath.close();
    canvas.drawPath(nearPath, nearPaint);
  }

  @override
  bool shouldRepaint(covariant _MountainsPainter old) => false;
}

class _PathTransition extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 2.w,
              height: 22.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.yellow.withOpacity(.6),
                    AppColors.orange.withOpacity(.4),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          ...List.generate(6, (i) {
            final positions = [
              const Alignment(-0.6, -0.8),
              const Alignment(0.4, -0.4),
              const Alignment(-0.2, 0),
              const Alignment(0.5, 0.3),
              const Alignment(-0.4, 0.7),
              const Alignment(0.3, 0.9),
            ];
            return Align(
              alignment: positions[i],
              child:
                  Container(
                        width: (2 + (i % 2) * 1.5).w,
                        height: (2 + (i % 2) * 1.5).w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i.isEven ? AppColors.yellow : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (i.isEven ? AppColors.yellow : Colors.white)
                                      .withOpacity(.7),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(
                        begin: 0,
                        end: 1,
                        duration: (1200 + i * 200).ms,
                        delay: (i * 180).ms,
                      )
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1.3, 1.3),
                      ),
            );
          }),
        ],
      ),
    );
  }
}

// class _LessonsPath extends StatelessWidget {
//   final List<LessonData> lessons;
//   final AnimationController flowController;
//   final void Function(LessonData lesson) onLessonTap;

//   const _LessonsPath({
//     required this.lessons,
//     required this.flowController,
//     required this.onLessonTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (lessons.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     final double nodeSpacing = 160.h;

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final width = constraints.maxWidth;
//         final totalHeight = lessons.length * nodeSpacing + 80.h;

//         final double edgeFraction = (60.w / width).clamp(0.10, 0.22);
//         final double minFraction = edgeFraction;
//         final double maxFraction = 1 - edgeFraction;

//         final points = List.generate(lessons.length, (i) {
//           final xFraction = 0.5 + 0.30 * math.sin(i * 2.05 + 1.0);
//           final dx = width * xFraction.clamp(minFraction, maxFraction);
//           final dy = 40.h + i * nodeSpacing;
//           return Offset(dx, dy);
//         });

//         return SizedBox(
//           height: totalHeight,
//           width: width,
//           child: Stack(
//             children: [
//               Positioned.fill(
//                 child: AnimatedBuilder(
//                   animation: flowController,
//                   builder: (_, __) => CustomPaint(
//                     painter: _LessonPathPainter(
//                       points: points,
//                       lessons: lessons,
//                       flowValue: flowController.value,
//                     ),
//                   ),
//                 ),
//               ),
//               ...List.generate(lessons.length, (i) {
//                 final lesson = lessons[i];
//                 final point = points[i];

//                 return Positioned(
//                   left: 0,
//                   right: 0,
//                   top: point.dy - 60.h,
//                   child: _LessonRow(
//                     lesson: lesson,
//                     nodeDx: point.dx,
//                     containerWidth: width,
//                     index: i,
//                     onTap: () => onLessonTap(lesson),
//                   ),
//                 );
//               }),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

class _LessonsPath extends StatelessWidget {
  final List<LessonData> lessons;
  final AnimationController flowController;
  final void Function(LessonData lesson) onLessonTap;

  const _LessonsPath({
    required this.lessons,
    required this.flowController,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const SizedBox.shrink();
    }

    final double nodeSpacing = 160.h;
    // مساحة إضافية بعد آخر درس للنقاط الختامية
    final double trailingHeight = 90.h;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final totalHeight =
            lessons.length * nodeSpacing + trailingHeight + 40.h;

        final double edgeFraction = (60.w / width).clamp(0.10, 0.22);
        final double minFraction = edgeFraction;
        final double maxFraction = 1 - edgeFraction;

        final points = List.generate(lessons.length, (i) {
          final xFraction = 0.5 + 0.30 * math.sin(i * 2.05 + 1.0);
          final dx = width * xFraction.clamp(minFraction, maxFraction);
          final dy = 40.h + i * nodeSpacing;
          return Offset(dx, dy);
        });

        // نقطة نهاية المسار (بعد آخر درس)
        final last = points.last;
        final endPoint = Offset(last.dx, last.dy + 70.h);

        return SizedBox(
          height: totalHeight,
          width: width,
          child: Stack(
            children: [
              // ── Path painter ──────────────────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: flowController,
                  builder: (_, __) => CustomPaint(
                    painter: _LessonPathPainter(
                      points: [...points, endPoint],
                      lessons: lessons,
                      flowValue: flowController.value,
                    ),
                  ),
                ),
              ),

              // ── Lesson nodes ──────────────────────────────────
              ...List.generate(lessons.length, (i) {
                final lesson = lessons[i];
                final point = points[i];

                return Positioned(
                  left: 0,
                  right: 0,
                  top: point.dy - 60.h,
                  child: _LessonRow(
                    lesson: lesson,
                    nodeDx: point.dx,
                    containerWidth: width,
                    index: i,
                    onTap: () => onLessonTap(lesson),
                  ),
                );
              }),

              // ── Trailing decorative dots (after last lesson) ──
              ...List.generate(3, (i) {
                final t = (i + 1) / 4.0;
                final dy = endPoint.dy + (i * 14.h);
                final opacity = 0.55 - (i * 0.15);

                return Positioned(
                  left: endPoint.dx - 4.w,
                  top: dy,
                  child:
                      Container(
                            width: 8.w - (i * 1.2.w),
                            height: 8.w - (i * 1.2.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.yellow.withOpacity(
                                opacity.clamp(0.15, 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.yellow.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fade(
                            begin: opacity * 0.6,
                            end: opacity,
                            duration: (900 + i * 200).ms,
                          )
                          .scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1.1, 1.1),
                            duration: (1100 + i * 150).ms,
                          ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _LessonPathPainter extends CustomPainter {
  final List<Offset> points;
  final List<LessonData> lessons;
  final double flowValue;

  _LessonPathPainter({
    required this.points,
    required this.lessons,
    required this.flowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final segmentPath = Path()..moveTo(p0.dx, p0.dy);
      final cp1 = Offset(p0.dx, (p0.dy + p1.dy) / 2);
      final cp2 = Offset(p1.dx, (p0.dy + p1.dy) / 2);
      segmentPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);

      final bounds = Rect.fromPoints(p0, p1).inflate(40);

      // `points` has one more entry than `lessons` — a trailing decorative
      // endPoint after the last lesson. Only read lessons[i + 1] when it
      // actually refers to a real lesson, otherwise fall back to lessons[i].
      final bool hasNextLesson = i + 1 < lessons.length;
      final isLocked =
          lessons[i].status == LessonStatus.locked ||
          (hasNextLesson && lessons[i + 1].status == LessonStatus.locked);

      if (isLocked) {
        _drawLockedSegment(canvas, segmentPath);
      } else {
        _drawActiveSegment(canvas, segmentPath, bounds);
      }
    }
  }

  void _drawActiveSegment(Canvas canvas, Path path, Rect bounds) {
    final gradientColors = [AppColors.orange, AppColors.yellow, AppColors.sky];

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: gradientColors).createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28.w
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: gradientColors).createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.w
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.w
        ..strokeCap = StrokeCap.round,
    );

    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      final double spacing = 28.w;
      final baseOffset = (flowValue * spacing) % spacing;
      double distance = baseOffset;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(
            tangent.position,
            5.w,
            Paint()
              ..color = Colors.white.withOpacity(.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
          canvas.drawCircle(
            tangent.position,
            2.5.w,
            Paint()..color = Colors.white,
          );
        }
        distance += spacing;
      }
    }
  }

  void _drawLockedSegment(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      const dashLength = 8.0;
      const gapLength = 10.0;
      double distance = 0;
      while (distance < metric.length) {
        final extract = metric.extractPath(
          distance,
          math.min(distance + dashLength, metric.length),
        );
        canvas.drawPath(
          extract,
          Paint()
            ..color = Colors.white.withOpacity(.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LessonPathPainter oldDelegate) =>
      oldDelegate.flowValue != flowValue || oldDelegate.points != points;
}

double _nodeSizeFor(LessonStatus status) {
  switch (status) {
    case LessonStatus.quiz:
      return 106.w.clamp(80.0, 120.0);
    case LessonStatus.current:
      return 100.w.clamp(78.0, 118.0);
    default:
      return 96.w.clamp(76.0, 115.0);
  }
}

class _LessonRow extends StatelessWidget {
  final LessonData lesson;
  final double nodeDx;
  final double containerWidth;
  final int index;
  final VoidCallback onTap;

  const _LessonRow({
    required this.lesson,
    required this.nodeDx,
    required this.containerWidth,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double size = _nodeSizeFor(lesson.status);
    final double nodeHalf = size / 2;
    final double gap = 10.w;
    final double edgePadding = 4.w;

    final double rightSpace = containerWidth - (nodeDx + nodeHalf) - gap;
    final double leftSpace = (nodeDx - nodeHalf) - gap;
    final bool placeOnRight = rightSpace >= leftSpace;
    final double available = placeOnRight ? rightSpace : leftSpace;

    final double cardWidth = available.clamp(95.w, 190.w);

    final double left = placeOnRight
        ? nodeDx + nodeHalf + gap
        : nodeDx - nodeHalf + gap - cardWidth - gap * 2;

    final double clampedLeft = placeOnRight
        ? (nodeDx + nodeHalf + gap).clamp(
            edgePadding,
            containerWidth - cardWidth - edgePadding,
          )
        : left.clamp(edgePadding, containerWidth - cardWidth - edgePadding);

    final double nodeBox = size + 30.w;

    return SizedBox(
      height: 190.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (lesson.status == LessonStatus.current)
            Positioned(
              left: (nodeDx - 35.w).clamp(0.0, containerWidth - 70.w),
              top: -6.h,
              child: const _CurrentRibbon(),
            ),
          Positioned(
            left: nodeDx - nodeBox / 2,
            top: 24.h,
            child: _LessonNode(lesson: lesson, index: index, onTap: onTap),
          ),
          Positioned(
            left: clampedLeft,
            top: 30.h,
            child: _LessonInfoCard(
              lesson: lesson,
              width: cardWidth,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentRibbon extends StatelessWidget {
  const _CurrentRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.orange, AppColors.yellow],
            ),
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withOpacity(.7),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, color: Colors.black, size: 11.sp),
              SizedBox(width: 3.w),
              Text(
                "Current",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5.sp,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1800.ms, color: Colors.white.withOpacity(.6))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1400.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _CourseShinyProgressStrip extends StatefulWidget {
  final double value;
  const _CourseShinyProgressStrip({required this.value});

  @override
  State<_CourseShinyProgressStrip> createState() =>
      _CourseShinyProgressStripState();
}

class _CourseShinyProgressStripState extends State<_CourseShinyProgressStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        height: 9.h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.10),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value,
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + 2.0 * _shimmer.value, 0),
                        end: Alignment(1.0 + 2.0 * _shimmer.value, 0),
                        colors: [
                          AppColors.yellow.withOpacity(.75),
                          const Color(0xFFFFF1A8),
                          AppColors.orange.withOpacity(.90),
                          const Color(0xFFFFF1A8),
                          AppColors.yellow.withOpacity(.75),
                        ],
                        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(.55),
                          blurRadius: 10,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  final LessonData lesson;
  final int index;
  final VoidCallback onTap;

  const _LessonNode({
    required this.lesson,
    required this.index,
    required this.onTap,
  });

  void _handleTap(BuildContext context) {
    if (lesson.status == LessonStatus.locked) {
      HapticFeedback.mediumImpact();
      showAppSnackBar(
        context,
        "Finish the previous lesson to unlock this one! 💪",
        type: AppSnackType.info,
      );
      return;
    }
    HapticFeedback.lightImpact();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = lesson.status == LessonStatus.current;
    final isLocked = lesson.status == LessonStatus.locked;
    final isQuiz = lesson.status == LessonStatus.quiz;
    final isCompleted = lesson.status == LessonStatus.completed;

    final double size = _nodeSizeFor(lesson.status);

    List<Color> gradientColors;
    Color ringColor;
    if (isLocked) {
      gradientColors = [
        Colors.white.withOpacity(.12),
        Colors.white.withOpacity(.05),
      ];
      ringColor = Colors.white.withOpacity(.18);
    } else if (isQuiz) {
      gradientColors = [const Color(0xffFF6FB5), const Color(0xffB861F5)];
      ringColor = const Color(0xFFFF9CCB);
    } else if (isCurrent) {
      gradientColors = [AppColors.yellow, AppColors.orange];
      ringColor = const Color(0xFFFFD35B);
    } else {
      gradientColors = [const Color(0xFF3BCF7E), const Color(0xFF1C9E58)];
      ringColor = const Color(0xFF79E59B);
    }

    Widget aura = const SizedBox.shrink();
    if (isCurrent) {
      aura =
          Container(
                width: size + 30.w,
                height: size + 30.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.yellow.withOpacity(.5),
                      AppColors.yellow.withOpacity(0),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 1400.ms,
                curve: Curves.easeInOut,
              );
    }

    Widget rotatingRing = const SizedBox.shrink();
    if (isCurrent) {
      rotatingRing =
          Container(
                width: size + 18.w,
                height: size + 18.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.yellow.withOpacity(.4),
                    width: 1.5,
                  ),
                  gradient: const SweepGradient(
                    colors: [
                      AppColors.yellow,
                      Colors.transparent,
                      AppColors.orange,
                      Colors.transparent,
                      AppColors.yellow,
                    ],
                    stops: [0.0, 0.3, 0.5, 0.8, 1.0],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 6.seconds, curve: Curves.linear);
    }

    Widget quizCrown = const SizedBox.shrink();
    if (isQuiz) {
      quizCrown = Positioned(
        top: -8.h,
        child:
            Icon(
                  Icons.workspace_premium_rounded,
                  color: const Color(0xFFFFD35B),
                  size: 20.sp,
                  shadows: const [
                    Shadow(color: Color(0xffB861F5), blurRadius: 12),
                    Shadow(color: Color(0xffFF6FB5), blurRadius: 20),
                  ],
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  duration: 1400.ms,
                ),
      );
    }

    Widget node = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: ringColor,
          width: 3.w,
        ), // الحلقة الخارجية الفاتحة
        boxShadow: isLocked
            ? []
            : [
                BoxShadow(
                  color: gradientColors.first.withOpacity(.55),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: Container(
        margin: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            // الحلقة الداخلية الرفيعة
            color: Colors.white.withOpacity(.35),
            width: 1.2,
          ),
        ),
        child: Center(
          child: isLocked
              ? Icon(Icons.lock_rounded, color: Colors.white54, size: 32.sp)
              : Icon(
                  lesson.icon,
                  color: Colors.white,
                  size: isQuiz ? 40.sp : (isCurrent ? 38.sp : 36.sp),
                ),
        ),
      ),
    );

    // ── شارة "صح" بحدود غامقة متل المستويات ────────────────────
    if (isCompleted) {
      node = Stack(
        clipBehavior: Clip.none,
        children: [
          node,
          Positioned(
            bottom: -2.h,
            right: -2.w,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                ),
                border: Border.all(color: AppColors.dark, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withOpacity(.6),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_rounded,
                size: 16.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (isCurrent || isQuiz) {
      node = node
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: 1400.ms,
            curve: Curves.easeInOut,
          );
    }

    return GestureDetector(
          onTap: () => _handleTap(context),
          child: SizedBox(
            width: size + 30.w,
            height: size + 30.w,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                aura,
                rotatingRing,
                if (isQuiz) quizCrown else const SizedBox.shrink(),
                node,
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (200 + index * 100).ms, duration: 500.ms)
        .scale(
          begin: const Offset(.7, .7),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}

class _LessonInfoCard extends StatelessWidget {
  final LessonData lesson;
  final double width;
  final VoidCallback onTap;

  const _LessonInfoCard({
    required this.lesson,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = lesson.status == LessonStatus.current;
    final isLocked = lesson.status == LessonStatus.locked;
    final isQuiz = lesson.status == LessonStatus.quiz;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isLocked) {
      statusColor = Colors.white54;
      statusText = "Locked";
      statusIcon = Icons.lock_rounded;
    } else if (lesson.status == LessonStatus.completed) {
      statusColor = const Color(0xFF4ADE80);
      statusText = "Completed";
      statusIcon = Icons.check_circle_rounded;
    } else if (isQuiz) {
      statusColor = const Color(0xFFFF6FB5);
      statusText = "Final Test";
      statusIcon = Icons.emoji_events_rounded;
    } else {
      statusColor = AppColors.yellow;
      statusText = "In Progress";
      statusIcon = Icons.play_circle_fill_rounded;
    }

    return GestureDetector(
          onTap: isLocked
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap();
                },
          child: SizedBox(
            width: width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isCurrent
                          ? [
                              AppColors.yellow.withOpacity(.22),
                              AppColors.orange.withOpacity(.12),
                            ]
                          : isQuiz
                          ? [
                              const Color(0xffB861F5).withOpacity(.22),
                              const Color(0xffFF6FB5).withOpacity(.12),
                            ]
                          : [
                              Colors.white.withOpacity(.10),
                              Colors.white.withOpacity(.04),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.yellow.withOpacity(.6)
                          : isQuiz
                          ? const Color(0xffFF6FB5).withOpacity(.5)
                          : Colors.white.withOpacity(.15),
                      width: isCurrent || isQuiz ? 1.5 : 1,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.yellow.withOpacity(.4),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ]
                        : isQuiz
                        ? [
                            BoxShadow(
                              color: const Color(0xffB861F5).withOpacity(.4),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lesson.title,
                        maxLines: null,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5.sp,
                          letterSpacing: .2,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lesson.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(.72),
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          if (!isLocked) ...[
                            Icon(
                              Icons.star_rounded,
                              size: 11.sp,
                              color: AppColors.yellow,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              "${lesson.xpReward}",
                              style: GoogleFonts.poppins(
                                color: AppColors.yellow,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(statusIcon, size: 13.sp, color: statusColor),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: statusColor,
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isCurrent && lesson.progress > 0) ...[
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Stack(
                            children: [
                              Container(
                                height: 6.h,
                                color: Colors.white.withOpacity(.15),
                              ),
                              FractionallySizedBox(
                                widthFactor: lesson.progress.clamp(0.0, 1.0),
                                child: Container(
                                  height: 6.h,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.orange,
                                        AppColors.yellow,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isCurrent) ...[
                        SizedBox(height: 10.h),
                        GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                onTap();
                              },
                              child: SizedBox(
                                width: double.infinity,
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 7.h,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.orange,
                                        AppColors.yellow,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.yellow.withOpacity(.6),
                                        blurRadius: 14,
                                        spreadRadius: .5,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit
                                              .scaleDown, // يصغّر النص ليقد المساحة بدل ما ينقطه
                                          child: Text(
                                            "Continue",
                                            maxLines: 1,
                                            style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 14.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(
                              duration: 1800.ms,
                              color: Colors.white.withOpacity(.7),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 250.ms, duration: 500.ms)
        .moveX(begin: 15, end: 0, curve: Curves.easeOutCubic);
  }
}

class _CourseFinalTestCard extends StatelessWidget {
  final int testId;
  final String courseTitle;
  final bool lessonsComplete;
  final VoidCallback onStart;

  const _CourseFinalTestCard({
    required this.testId,
    required this.courseTitle,
    required this.lessonsComplete,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !lessonsComplete;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: locked ? null : onStart,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: locked
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.yellow.withOpacity(0.35),
            ),
            boxShadow: locked
                ? null
                : [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Slim badge
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  gradient: locked
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.yellow.withOpacity(0.95),
                            AppColors.orange.withOpacity(0.85),
                          ],
                        ),
                  color: locked ? Colors.white.withOpacity(0.08) : null,
                  border: locked
                      ? Border.all(color: Colors.white.withOpacity(0.12))
                      : null,
                ),
                child: Icon(
                  locked ? Icons.lock_rounded : Icons.workspace_premium_rounded,
                  color: locked ? Colors.white38 : AppColors.dark,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locked ? 'Final test locked' : 'Course final test',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      locked
                          ? 'Complete all lessons to unlock'
                          : 'Pass to finish the course',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Compact action chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: locked
                      ? Colors.white.withOpacity(0.06)
                      : AppColors.yellow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!locked) ...[
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 16.sp,
                        color: AppColors.dark,
                      ),
                      SizedBox(width: 2.w),
                    ],
                    Text(
                      locked ? 'Locked' : 'Start',
                      style: GoogleFonts.poppins(
                        color: locked ? Colors.white38 : AppColors.dark,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
