import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final String courseTitle;
  final String courseSubtitle;
  final String teacherName;
  final String userName;
  final int xp;
  final int streakDays;
  final double courseProgress; 
  final List<LessonData> lessons;
  final DailyChallengeData dailyChallenge;
  final List<bool> weeklyStreak; 
  final void Function(LessonData lesson)? onLessonTap;
  final VoidCallback? onBack;

  const LessonsScreen({
    super.key,
    this.courseId,
    this.courseTitle = "Grammar Mastery",
    this.courseSubtitle = "Level 8 · Fluent Instructor",
    this.teacherName = "Fluent Instructor",
    this.userName = "Rasha",
    this.xp = 12540,
    this.streakDays = 15,
    this.courseProgress = 0.45,
    this.lessons = const [
      LessonData(
        id: 1,
        title: "Present Simple Basics",
        subtitle: "Video · 8 mins",
        status: LessonStatus.completed,
        icon: Icons.play_circle_fill_rounded,
        xpReward: 20,
      ),
      LessonData(
        id: 2,
        title: "Sentence Structure",
        subtitle: "Reading · 6 mins",
        status: LessonStatus.completed,
        icon: Icons.menu_book_rounded,
        xpReward: 25,
      ),
      LessonData(
        id: 3,
        title: "Common Mistakes",
        subtitle: "Exercise · 10 mins",
        status: LessonStatus.current,
        icon: Icons.edit_note_rounded,
        xpReward: 30,
        progress: .4,
      ),
      LessonData(
        id: 4,
        title: "Listening Practice",
        subtitle: "Audio · 12 mins",
        status: LessonStatus.locked,
        icon: Icons.headphones_rounded,
        xpReward: 30,
      ),
      LessonData(
        id: 5,
        title: "Speaking Drill",
        subtitle: "Speaking · 15 mins",
        status: LessonStatus.locked,
        icon: Icons.mic_rounded,
        xpReward: 35,
      ),
      LessonData(
        id: 6,
        title: "Final Quiz",
        subtitle: "Test · 20 mins",
        status: LessonStatus.quiz,
        icon: Icons.emoji_events_rounded,
        xpReward: 100,
      ),
    ],
    this.dailyChallenge = const DailyChallengeData(
      title: "Complete 2 lessons today",
      current: 1,
      target: 2,
      rewardXp: 150,
    ),
    this.weeklyStreak = const [true, true, true, true, false, false, false],
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

  int get _completedCount =>
      widget.lessons.where((l) => l.status == LessonStatus.completed).length;
  int get _totalCount => widget.lessons.isNotEmpty ? widget.lessons.length : 1;

  @override
  void initState() {
    super.initState();
    _pathFlowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _borderFlowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        SizedBox(height: 16.h),
                        _buildCourseHeroCard(),
                        SizedBox(height: 14.h),
                        _buildStudentStatusBar(),
                        SizedBox(height: 14.h),
                        _buildDailyChallengeCard(),
                        SizedBox(height: 14.h),
                        _buildProgressOverview(),
                        SizedBox(height: 8.h),
                        _PathTransition(),
                        SizedBox(height: 4.h),
                        _LessonsPath(
                          lessons: widget.lessons,
                          flowController: _pathFlowController,
                          onLessonTap: (lesson) {
                            widget.onLessonTap?.call(lesson);
                          },
                        ),
                        SizedBox(height: 110.h),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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
                "COURSE",
                style: GoogleFonts.poppins(
                  color: AppColors.sky.withOpacity(.85),
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                widget.courseTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _circleIconButton(
          icon: Icons.notifications_rounded,
          badgeCount: 3,
          onTap: () {},
        ),
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
                    lessons: widget.lessons,
                    progress: widget.courseProgress,
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
                              horizontal: 8.w, vertical: 3.h),
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
                            Icon(Icons.person_rounded,
                                color: Colors.white.withOpacity(.5),
                                size: 13.sp),
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
                  Icon(Icons.menu_book_rounded, color: AppColors.sky, size: 15.sp),
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

  Widget _buildStudentStatusBar() {
    const dayLabels = ["S", "M", "T", "W", "T", "F", "S"];

    return _glassContainer(
      padding: EdgeInsets.all(14.w),
      radius: 20.r,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColors.orange, size: 16.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  "Your Streak",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star_rounded, color: AppColors.yellow, size: 13.sp),
                  SizedBox(width: 3.w),
                  Text(
                    "${widget.xp} XP",
                    style: GoogleFonts.poppins(
                      color: AppColors.yellow,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: List.generate(7, (i) {
              final done = i < widget.weeklyStreak.length
                  ? widget.weeklyStreak[i]
                  : false;
              final isToday = i == widget.weeklyStreak.length - 1;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: done
                            ? const LinearGradient(
                                colors: [AppColors.orange, AppColors.yellow])
                            : null,
                        color: done ? null : Colors.white.withOpacity(.08),
                        border: isToday
                            ? Border.all(
                                color: AppColors.yellow.withOpacity(.9),
                                width: 1.6)
                            : Border.all(
                                color: Colors.white.withOpacity(.14)),
                        boxShadow: done
                            ? [
                                BoxShadow(
                                  color: AppColors.orange.withOpacity(.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        done
                            ? Icons.local_fire_department_rounded
                            : Icons.circle,
                        size: done ? 14.sp : 5.sp,
                        color: done ? Colors.white : Colors.white24,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      dayLabels[i],
                      style: GoogleFonts.poppins(
                        color: isToday
                            ? AppColors.yellow
                            : Colors.white.withOpacity(.45),
                        fontSize: 9.sp,
                        fontWeight:
                            isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms).moveY(begin: 8, end: 0);
  }

  Widget _buildDailyChallengeCard() {
    final challenge = widget.dailyChallenge;
    final fraction = challenge.fraction;

    return _glassContainer(
      padding: EdgeInsets.all(14.w),
      radius: 22.r,
      gradientColors: [
        AppColors.primary.withOpacity(.6),
        const Color(0xff01466A).withOpacity(.5),
      ],
      borderColor: Colors.white.withOpacity(.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44.w,
            height: 44.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 4.w,
                    valueColor:
                        AlwaysStoppedAnimation(Colors.white.withOpacity(.12)),
                  ),
                ),
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: 1100.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 4.w,
                      strokeCap: StrokeCap.round,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.orange),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
                Icon(Icons.bolt_rounded, color: AppColors.yellow, size: 18.sp),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Daily Challenge",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.8),
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Stack(
                    children: [
                      Container(
                        height: 8.h,
                        color: Colors.white.withOpacity(.14),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 8.h,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.orange, AppColors.yellow],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${challenge.current}/${challenge.target}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_rounded,
                          color: AppColors.yellow, size: 12.sp)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.18, 1.18),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      ),
                  SizedBox(width: 3.w),
                  Text(
                    "+${challenge.rewardXp}",
                    style: GoogleFonts.poppins(
                      color: AppColors.yellow,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 220.ms, duration: 500.ms).moveY(begin: 8, end: 0);
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
            children: List.generate(widget.lessons.length, (i) {
              final color = dotColor(widget.lessons[i].status);
              final isLocked = widget.lessons[i].status == LessonStatus.locked;
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
                                color: color.withOpacity(.7), blurRadius: 5)
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

  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded, "HOME", Icons.refresh_rounded),
      (Icons.menu_book_rounded, "WORD BANK", null),
      (Icons.mic_rounded, "PODCASTS", null),
      (Icons.headset_rounded, "AI CONVERSATION", null),
      (Icons.person_rounded, "PROFILE", null),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
      child: AnimatedBuilder(
        animation: _borderFlowController,
        builder: (context, _) {
          return CustomPaint(
            foregroundPainter: _AnimatedBorderPainter(
              animationValue: _borderFlowController.value,
              radius: 28.r,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  height: 76.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.dark.withOpacity(.55),
                        AppColors.primary.withOpacity(.35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sky.withOpacity(.25),
                        blurRadius: 25,
                        spreadRadius: -3,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (i) {
                      final selected = i == _selectedNavIndex;
                      final (icon, label, badge) = items[i];

                      return Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.selectionClick();

                            if (i == 0) {
                              Navigator.popUntil(
                                  context, (route) => route.isFirst);
                              return;
                            }

                            setState(() => _selectedNavIndex = i);

                            Future<void>? navigationFuture;
                            switch (i) {
                              case 1:
                                navigationFuture = Navigator.pushNamed(
                                    context, wordBankRoute);
                                break;
                              case 2:
                                navigationFuture = Navigator.pushNamed(
                                    context, podcastsRoute);
                                break;
                              case 3:
                                navigationFuture = Navigator.pushNamed(
                                    context, aiConversationRoute);
                                break;
                              case 4:
                                navigationFuture = Navigator.pushNamed(
                                    context, profileRoute);
                                break;
                            }

                            await navigationFuture;
                            if (mounted) {
                              setState(() => _selectedNavIndex = 0);
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: 250.ms,
                            curve: Curves.easeOut,
                            padding: EdgeInsets.symmetric(
                                vertical: 10.h, horizontal: 2.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedScale(
                                      scale: selected ? 1.12 : 1.0,
                                      duration: 300.ms,
                                      curve: Curves.easeOutBack,
                                      child: Container(
                                        padding: EdgeInsets.all(6.r),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: selected
                                              ? RadialGradient(
                                                  colors: [
                                                    AppColors.yellow
                                                        .withOpacity(.35),
                                                    AppColors.orange
                                                        .withOpacity(.15),
                                                    Colors.transparent,
                                                  ],
                                                )
                                              : null,
                                          boxShadow: selected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.yellow
                                                        .withOpacity(.5),
                                                    blurRadius: 14,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          icon,
                                          color: selected
                                              ? AppColors.yellow
                                              : Colors.white.withOpacity(.75),
                                          size: 22.sp,
                                          shadows: selected
                                              ? [
                                                  Shadow(
                                                    color: AppColors.yellow
                                                        .withOpacity(.8),
                                                    blurRadius: 10,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (badge != null)
                                      Positioned(
                                        top: -2,
                                        right: -4,
                                        child: Container(
                                          padding: EdgeInsets.all(2.5.r),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.yellow,
                                                AppColors.orange
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.yellow
                                                    .withOpacity(.6),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            badge,
                                            size: 7.sp,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AnimatedDefaultTextStyle(
                                    duration: 250.ms,
                                    style: GoogleFonts.poppins(
                                      color: selected
                                          ? AppColors.yellow
                                          : Colors.white.withOpacity(.7),
                                      fontSize: selected ? 9.sp : 8.5.sp,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      letterSpacing: .3,
                                    ),
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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
              colors: gradientColors ??
                  [
                    Colors.white.withOpacity(.10),
                    Colors.white.withOpacity(.04),
                  ],
            ),
            border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(.15)),
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

class _CourseOrbitRing extends StatelessWidget {
  final List<LessonData> lessons;
  final double progress;
  final double size;

  const _CourseOrbitRing({
    required this.lessons,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final double boxSize = size + 34.w;

    if (lessons.isEmpty) {
      return SizedBox(width: boxSize, height: boxSize);
    }

    Color dotColor(LessonData l) {
      switch (l.status) {
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

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(lessons.length, (i) {
            final angle = -math.pi / 2 + i * (2 * math.pi / lessons.length);
            final radius = size / 2 + 15.w;
            final dx = math.cos(angle) * radius;
            final dy = math.sin(angle) * radius;
            final lesson = lessons[i];
            final color = dotColor(lesson);
            final dotSize = lesson.status == LessonStatus.completed
                ? 12.w
                : (lesson.status == LessonStatus.quiz ? 12.w : 8.w);

            Widget dot = Container(
              width: dotSize,
              height: dotSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: lesson.status == LessonStatus.completed
                    ? Border.all(color: Colors.white, width: 1.1)
                    : null,
                boxShadow: lesson.status == LessonStatus.locked
                    ? []
                    : [BoxShadow(color: color.withOpacity(.7), blurRadius: 6)],
              ),
              child: lesson.status == LessonStatus.completed
                  ? Icon(Icons.check_rounded,
                      size: dotSize * 0.6, color: Colors.black)
                  : null,
            );

            if (lesson.status == LessonStatus.current) {
              dot = dot
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.35, 1.35),
                    duration: 1100.ms,
                    curve: Curves.easeInOut,
                  );
            }

            return Transform.translate(offset: Offset(dx, dy), child: dot);
          }),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8.w,
              valueColor:
                  AlwaysStoppedAnimation(Colors.white.withOpacity(.08)),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: 1200.ms,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 8.w,
                strokeCap: StrokeCap.round,
                valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded,
                      color: AppColors.yellow, size: 16.sp)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 1600.ms,
                    curve: Curves.easeInOut,
                  ),
              SizedBox(height: 2.h),
              Text(
                "${(progress.clamp(0.0, 1.0) * 100).toInt()}%",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
            child: Container(
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

  _AnimatedBorderPainter({
    required this.animationValue,
    required this.radius,
  });

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
              child: Container(
                width: (2 + (i % 2) * 1.5).w,
                height: (2 + (i % 2) * 1.5).w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i.isEven ? AppColors.yellow : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: (i.isEven ? AppColors.yellow : Colors.white)
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final totalHeight = lessons.length * nodeSpacing + 80.h;

        final double edgeFraction = (60.w / width).clamp(0.10, 0.22);
        final double minFraction = edgeFraction;
        final double maxFraction = 1 - edgeFraction;

        final points = List.generate(lessons.length, (i) {
          final xFraction = 0.5 + 0.30 * math.sin(i * 2.05 + 1.0);
          final dx = width * xFraction.clamp(minFraction, maxFraction);
          final dy = 40.h + i * nodeSpacing;
          return Offset(dx, dy);
        });

        return SizedBox(
          height: totalHeight,
          width: width,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: flowController,
                  builder: (_, __) => CustomPaint(
                    painter: _LessonPathPainter(
                      points: points,
                      lessons: lessons,
                      flowValue: flowController.value,
                    ),
                  ),
                ),
              ),
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

      final isLocked = lessons[i].status == LessonStatus.locked ||
          lessons[i + 1].status == LessonStatus.locked;

      if (isLocked) {
        _drawLockedSegment(canvas, segmentPath);
      } else {
        _drawActiveSegment(canvas, segmentPath, bounds);
      }
    }
  }

  void _drawActiveSegment(Canvas canvas, Path path, Rect bounds) {
    final gradientColors = [
      AppColors.orange,
      AppColors.yellow,
      AppColors.sky,
    ];

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
    final double cardWidth = (containerWidth * 0.42).clamp(130.w, 175.w);
    final double nodeHalf = 39.w;
    final double gap = 12.w;
    final double edgePadding = 4.w;

    final spaceOnRight = containerWidth - nodeDx;
    final spaceOnLeft = nodeDx;
    final placeOnRight = spaceOnRight >= spaceOnLeft;

    double desiredLeft = placeOnRight
        ? nodeDx + nodeHalf + gap
        : nodeDx - nodeHalf - gap - cardWidth;

    final maxLeft = containerWidth - cardWidth - edgePadding;
    final clampedLeft = desiredLeft.clamp(
        edgePadding, maxLeft < edgePadding ? edgePadding : maxLeft);

    return SizedBox(
      height: 160.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (lesson.status == LessonStatus.current)
            Positioned(
              left: (nodeDx - 35.w).clamp(0.0, containerWidth - 70.w),
              top: -2.h,
              child: const _CurrentRibbon(),
            ),
          Positioned(
            left: nodeDx - 40.w,
            top: 24.h,
            child: _LessonNode(
              lesson: lesson,
              index: index,
              onTap: onTap,
            ),
          ),
          Positioned(
            left: clampedLeft,
            top: 28.h,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8.w),
              const Expanded(
                child: Text("Finish the previous lesson to unlock this one! 💪"),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          duration: const Duration(seconds: 2),
        ),
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

    final double size =
        (isQuiz ? 82.w : (isCurrent ? 80.w : 70.w)).clamp(56.0, 92.0);

    List<Color> gradientColors;
    if (isLocked) {
      gradientColors = [
        Colors.white.withOpacity(.12),
        Colors.white.withOpacity(.04),
      ];
    } else if (isQuiz) {
      gradientColors = [const Color(0xffFF6FB5), const Color(0xffB861F5)];
    } else if (isCurrent) {
      gradientColors = [AppColors.orange, AppColors.yellow];
    } else {
      gradientColors = [const Color(0xFF4ADE80), const Color(0xFF22C55E)];
    }

    Widget aura = const SizedBox.shrink();
    if (isCurrent) {
      aura = Container(
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
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.15, 1.15),
            duration: 1400.ms,
            curve: Curves.easeInOut,
          );
    }

    Widget rotatingRing = const SizedBox.shrink();
    if (isCurrent) {
      rotatingRing = Container(
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
      ).animate(onPlay: (c) => c.repeat()).rotate(
            duration: 6.seconds,
            curve: Curves.linear,
          );
    }

    Widget quizCrown = const SizedBox.shrink();
    if (isQuiz) {
      quizCrown = Positioned(
        top: -8.h,
        child: Icon(
          Icons.workspace_premium_rounded,
          color: const Color(0xFFFFD35B),
          size: 18.sp,
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
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: isLocked
            ? []
            : [
                BoxShadow(
                  color: gradientColors.first.withOpacity(.6),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.dark.withOpacity(.4),
          border: Border.all(color: Colors.white.withOpacity(.4), width: 2),
        ),
        child: Center(
          child: isLocked
              ? Icon(Icons.lock_rounded, color: Colors.white54, size: 28.sp)
              : Icon(
                  lesson.icon,
                  color: Colors.white,
                  size: isQuiz ? 34.sp : (isCurrent ? 32.sp : 26.sp),
                ),
        ),
      ),
    );

    if (isCompleted) {
      node = Stack(
        clipBehavior: Clip.none,
        children: [
          node,
          Positioned(
            bottom: -2.h,
            right: -2.w,
            child: Container(
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.dark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withOpacity(.6),
                    blurRadius: 8,
                  ),
                ],
              ),
              child:
                  Icon(Icons.check_rounded, size: 12.sp, color: Colors.white),
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
            curve: Curves.easeOutBack);
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
    final isCompleted = lesson.status == LessonStatus.completed;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isLocked) {
      statusColor = Colors.white54;
      statusText = "Locked";
      statusIcon = Icons.lock_rounded;
    } else if (isCompleted) {
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
              padding: EdgeInsets.all(12.w),
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
                  if (isQuiz)
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xffFF6FB5), Color(0xffFFD35B)],
                      ).createShader(bounds),
                      child: Text(
                        "🏆 Final Quiz",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          letterSpacing: .3,
                        ),
                      ),
                    )
                  else
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.sp,
                        letterSpacing: .2,
                      ),
                    ),
                  SizedBox(height: 2.h),
                  Text(
                    lesson.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.72),
                      fontSize: 10.5.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13.sp, color: statusColor),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!isLocked) ...[
                        Icon(Icons.star_rounded,
                            size: 11.sp, color: AppColors.yellow),
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
                                  colors: [AppColors.orange, AppColors.yellow],
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
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.orange, AppColors.yellow],
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
                          children: [
                            Text(
                              "Continue",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.black, size: 14.sp),
                          ],
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

