
import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fluent/cubit/student/courses/course_cubit.dart';
import 'package:fluent/cubit/student/courses/course_state.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/presentation/screens/lessons/lessons_scrssn.dart';
class LevelCoursesScreen extends StatefulWidget {
  final int? levelId; 
  final String userName;
  final int xp;
  final int streakDays;
  final int level;
  final double levelProgress;
  final String levelTitle;
  final String levelSubtitle;

  const LevelCoursesScreen({
    super.key,
    this.levelId,
    this.userName = "Rasha",
    this.xp = 12540,
    this.streakDays = 15,
    this.level = 8,
    this.levelProgress = 0.78,
    this.levelTitle = "Level 8",
    this.levelSubtitle = "Grammar Mastery",
  });

  @override
  State<LevelCoursesScreen> createState() => _LevelCoursesScreenState();
}

class _LevelCoursesScreenState extends State<LevelCoursesScreen>
    with TickerProviderStateMixin {
  int _selectedNavIndex = 0;
  int? _tappedIndex;

  late final AnimationController _borderFlowController;

  // ✅ صارت تتعبى من الباك بدل ما تكون Hardcoded
  List<CourseData> _courses = [];

  // ✅ ألوان دورية نلوّن فيها كل كورس (بما إنو الباك ما بيرجع لون خاص بكل كورس)
  static const List<Color> _courseAccentColors = [
    AppColors.sky,
    AppColors.orange,
    Color(0xFF4ADE80),
    AppColors.yellow,
    Color(0xFFB388FF),
    Color(0xFFFF6FB5),
  ];

  CourseData _toCourseData(
    CourseModel course, {
    required bool isCompleted,
    required bool isLocked,
    required bool isCurrent,
    required int colorIndex,
  }) {
    return CourseData(
      id: course.id,
      order: course.order,
      title: course.name,
      // ⚠️ TODO: الباك ما بيرجع اسم مدرّس لكل كورس حالياً — نص عام مؤقت
      teacher: "Fluent Instructor",
      teacherAvatar: Icons.person_rounded,
      imageUrl: course.image.isNotEmpty
          ? course.image
          : "https://picsum.photos/seed/course${course.id}/400/250",
      progress: isCompleted ? 1.0 : 0.0,
      lessonsCount: 0,
      duration: _formatDuration(course.estimatedDuration),
      isCompleted: isCompleted,
      accentColor: _courseAccentColors[colorIndex % _courseAccentColors.length],
      isLocked: isLocked,
      isCurrent: isCurrent,
    );
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return "-";
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? "${h}h ${m}m" : "${h}h";
    }
    return "${minutes}m";
  }

  List<CourseData> _mapCourses(StudentCoursesModel data) {
    final list = <CourseData>[];
    int colorIndex = 0;

    for (final c in data.completedCourses) {
      list.add(_toCourseData(
        c,
        isCompleted: true,
        isLocked: false,
        isCurrent: false,
        colorIndex: colorIndex++,
      ));
    }

    if (data.currentCourse != null) {
      list.add(_toCourseData(
        data.currentCourse!,
        isCompleted: false,
        isLocked: false,
        isCurrent: true,
        colorIndex: colorIndex++,
      ));
    }

    for (final c in data.lockedCourses) {
      list.add(_toCourseData(
        c,
        isCompleted: false,
        isLocked: true,
        isCurrent: false,
        colorIndex: colorIndex++,
      ));
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    _borderFlowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<StudentCoursesCubit>();
      if (cubit.state is StudentCoursesInitial) {
        cubit.fetchStudentCourses(widget.levelId ?? 0);
      }
    });
  }

  @override
  void dispose() {
    _borderFlowController.dispose();
    super.dispose();
  }

  int get _activeCourseIndex => _courses.indexWhere((c) => c.isCurrent);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          _buildBackground(),
          _TwinklingStars(count: 30),
          SafeArea(
            child: Column(
              children: [
                // TOP BAR
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: _buildTopBar(),
                ),

                // COURSES LIST + HERO HEADER
                Expanded(
                  child: BlocBuilder<StudentCoursesCubit, StudentCoursesState>(
                    builder: (context, state) {
                      if (state is StudentCoursesLoading ||
                          state is StudentCoursesInitial) {
                        return _coursesLoadingCard();
                      }

                      if (state is StudentCoursesFailure) {
                        return _coursesErrorCard(state.message);
                      }

                      if (state is StudentCoursesSuccess) {
                        _courses = _mapCourses(state.data);
                        return _buildCoursesList();
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),

                SizedBox(height: 18.h),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _coursesLoadingCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.yellow),
      ),
    );
  }

  Widget _coursesErrorCard(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
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
                Icon(Icons.wifi_off_rounded,
                    color: Colors.white.withOpacity(.7), size: 28.sp),
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
                      .read<StudentCoursesCubit>()
                      .fetchStudentCourses(widget.levelId ?? 0),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
      ),
    );
  }

  Widget _buildCoursesList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: _courses.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLevelHeroCard(),
                SizedBox(height: 22.h),
                _buildSectionTitleRow(),
                SizedBox(height: 12.h),
              ],
            ),
          );
        }

        final courseIndex = index - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: AnimatedCourseCard(
            course: _courses[courseIndex],
            index: courseIndex,
            isTapped: _tappedIndex == courseIndex,
            isHighlighted: courseIndex == _activeCourseIndex,
            onTap: () {
              if (_courses[courseIndex].isLocked) {
                HapticFeedback.mediumImpact();

                setState(() => _tappedIndex = courseIndex);

                Future.delayed(
                  const Duration(milliseconds: 300),
                  () {
                    if (mounted) {
                      setState(() => _tappedIndex = null);
                    }
                  },
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            "Complete previous courses to unlock!",
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                   HapticFeedback.lightImpact();
                  setState(() => _tappedIndex = courseIndex);

                      Future.delayed(const Duration(milliseconds: 200), () {
                     if (mounted) setState(() => _tappedIndex = null);
                       });

                         final course = _courses[courseIndex];

                          Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LessonsScreen(
        courseId: course.id,
        courseTitle: course.title,
        courseSubtitle: "${widget.levelTitle} · ${course.teacher}",
        teacherName: course.teacher,
        userName: widget.userName,
        xp: widget.xp,
        streakDays: widget.streakDays,
        courseProgress: course.progress,
        onLessonTap: (lesson) {
        },
      ),
    ),
  );
}
            },
            borderAnimation: _borderFlowController,
          ),
        );
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
              colors: [AppColors.dark, AppColors.primary, AppColors.sky],
            ),
          ),
        ),
        Positioned(
          top: -140.h,
          left: -90.w,
          child: _glowingCircle(AppColors.yellow, 320.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                  begin: Offset.zero,
                  end: const Offset(15, 10),
                  duration: 5000.ms,
                  curve: Curves.easeInOut),
        ),
        Positioned(
          bottom: -160.h,
          right: -110.w,
          child: _glowingCircle(AppColors.sky, 380.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                  begin: Offset.zero,
                  end: const Offset(-20, -15),
                  duration: 6000.ms,
                  curve: Curves.easeInOut),
        ),
      ],
    );
  }

  Widget _glowingCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.35), blurRadius: 160, spreadRadius: 40)
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    const double iconSize = 44;

    return Row(
      children: [
        _circleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
            iconSize: iconSize.w),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("👋 Good evening,",
                  style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.75), fontSize: 12.sp)),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, AppColors.sky])
                    .createShader(bounds),
                child: Text(
                  widget.userName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        _circleIconButton(
            icon: Icons.notifications_rounded,
            badgeCount: 3,
            onTap: () {},
            iconSize: iconSize.w),
      ],
    ).animate().fadeIn(duration: 500.ms).moveY(begin: -10, end: 0);
  }

  Widget _circleIconButton(
      {required IconData icon,
      int badgeCount = 0,
      required VoidCallback onTap,
      required double iconSize}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(.25)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(icon, color: Colors.white, size: iconSize * 0.45),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2.h,
              right: -2.w,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.redAccent, Color(0xFFFF6B6B)]),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dark, width: 1.5),
                ),
                constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
                child: Center(
                    child: Text("$badgeCount",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelHeroCard() {
    final completedCount = _courses.where((c) => c.isCompleted).length;
    final totalCount = _courses.isNotEmpty ? _courses.length : 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.all(18.w),
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
                color: AppColors.yellow.withOpacity(.18),
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
                  _LevelOrbitRing(
                    courses: _courses,
                    progress: widget.levelProgress,
                    size: 100.w,
                  ),
                  SizedBox(width: 16.w),
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
                            "CURRENT LEVEL",
                            style: GoogleFonts.poppins(
                              color: AppColors.yellow,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AppColors.yellow, AppColors.orange])
                              .createShader(bounds),
                          child: Text(
                            widget.levelTitle,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.levelSubtitle,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(.75),
                              fontSize: 12.5.sp),
                        ),
                        SizedBox(height: 10.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: [
                            _heroStatChip(
                              icon: Icons.star_rounded,
                              color: AppColors.yellow,
                              value: _formatNumber(widget.xp),
                            ),
                            _heroStatChip(
                              icon: Icons.local_fire_department_rounded,
                              color: AppColors.orange,
                              value: "${widget.streakDays}d",
                            ),
                            _heroStatChip(
                              icon: Icons.military_tech_rounded,
                              color: const Color(0xffB388FF),
                              value: "Lvl ${widget.level}",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(height: 1, color: Colors.white.withOpacity(.10)),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      color: AppColors.sky, size: 15.sp),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      "$completedCount of $totalCount courses completed",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.85),
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms).moveY(begin: 12, end: 0);
  }

  Widget _heroStatChip(
      {required IconData icon, required Color color, required String value}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitleRow() {
    final completedCount = _courses.where((c) => c.isCompleted).length;
    return Row(
      children: [
        Text(
          "Courses in This Level",
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 15.5.sp, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(.14)),
          ),
          child: Text(
            "$completedCount/${_courses.length}",
            style: GoogleFonts.poppins(
                color: AppColors.yellow, fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 500.ms);
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
              animationValue: _borderFlowController.value, radius: 28.r),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                height: 76.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.dark.withOpacity(.55),
                    AppColors.primary.withOpacity(.35)
                  ]),
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.sky.withOpacity(.25), blurRadius: 25),
                    BoxShadow(
                        color: Colors.black.withOpacity(.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (i) {
                    final selected = i == _selectedNavIndex;
                    final (icon, label, badge) = items[i];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();

                          // إذا ضغط على HOME → نرجع للصفحة الرئيسية
                          if (i == 0) {
                            Navigator.popUntil(context, (route) => route.isFirst);
                            return;
                          }

                          setState(() => _selectedNavIndex = i);

                          Future<void>? navigationFuture;

                          switch (i) {
                            case 1: // WORD BANK
                              navigationFuture = Navigator.pushNamed(context, wordBankRoute);
                              break;
                            case 2: // PODCASTS
                              navigationFuture = Navigator.pushNamed(context, podcastsRoute);
                              break;
                            case 3: // AI CONVERSATION
                              navigationFuture = Navigator.pushNamed(context, aiConversationRoute);
                              break;
                            case 4: // PROFILE
                              navigationFuture = Navigator.pushNamed(context, profileRoute);
                              break;
                          }

                          if (navigationFuture != null) {
                            navigationFuture.then((_) {
                              if (mounted) {
                                setState(() => _selectedNavIndex = 0); // نرجع للـ Home icon
                              }
                            });
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: 250.ms,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
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
                                    child: Container(
                                      padding: EdgeInsets.all(7.r),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: selected
                                            ? RadialGradient(colors: [
                                                AppColors.yellow.withOpacity(.35),
                                                AppColors.orange.withOpacity(.15)
                                              ])
                                            : null,
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                    color: AppColors.yellow.withOpacity(.5),
                                                    blurRadius: 14,
                                                    spreadRadius: 1)
                                              ]
                                            : null,
                                      ),
                                      child: Icon(icon,
                                          color: selected
                                              ? AppColors.yellow
                                              : Colors.white.withOpacity(.75),
                                          size: 22.sp),
                                    ),
                                  ),
                                  if (badge != null)
                                    Positioned(
                                      top: -2,
                                      right: -4,
                                      child: Container(
                                        padding: EdgeInsets.all(2.r),
                                        decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                                colors: [AppColors.yellow, AppColors.orange]),
                                            shape: BoxShape.circle),
                                        child: Icon(badge,
                                            size: 8.sp, color: Colors.black),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              AnimatedDefaultTextStyle(
                                duration: 250.ms,
                                style: GoogleFonts.poppins(
                                  color: selected
                                      ? AppColors.yellow
                                      : Colors.white.withOpacity(.7),
                                  fontSize: 9.sp,
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                ),
                                child: Text(label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center),
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

  // Widget _buildBottomNav() {
  //   final items = [
  //     (Icons.home_rounded, "HOME", Icons.refresh_rounded),
  //     (Icons.menu_book_rounded, "WORD BANK", null),
  //     (Icons.mic_rounded, "PODCASTS", null),
  //     (Icons.headset_rounded, "AI CONVERSATION", null),
  //     (Icons.person_rounded, "PROFILE", null),
  //   ];

  //   return Container(
  //     margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
  //     child: AnimatedBuilder(
  //       animation: _borderFlowController,
  //       builder: (context, _) {
  //         return CustomPaint(
  //           foregroundPainter: _AnimatedBorderPainter(
  //               animationValue: _borderFlowController.value, radius: 28.r),
  //           child: ClipRRect(
  //             borderRadius: BorderRadius.circular(28.r),
  //             child: BackdropFilter(
  //               filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
  //               child: Container(
  //                 height: 76.h,
  //                 decoration: BoxDecoration(
  //                   gradient: LinearGradient(colors: [
  //                     AppColors.dark.withOpacity(.55),
  //                     AppColors.primary.withOpacity(.35)
  //                   ]),
  //                   borderRadius: BorderRadius.circular(28.r),
  //                   boxShadow: [
  //                     BoxShadow(
  //                         color: AppColors.sky.withOpacity(.25), blurRadius: 25),
  //                     BoxShadow(
  //                         color: Colors.black.withOpacity(.4),
  //                         blurRadius: 30,
  //                         offset: const Offset(0, 10))
  //                   ],
  //                 ),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceAround,
  //                   children: List.generate(items.length, (i) {
  //                     final selected = i == _selectedNavIndex;
  //                     final (icon, label, badge) = items[i];
  //                     return Expanded(
  //                       child: GestureDetector(
  //                         onTap: () {
  //                           HapticFeedback.selectionClick();
  //                           setState(() => _selectedNavIndex = i);
  //                         },
  //                         behavior: HitTestBehavior.opaque,
  //                         child: AnimatedContainer(
  //                           duration: 250.ms,
  //                           padding: EdgeInsets.symmetric(vertical: 10.h),
  //                           child: Column(
  //                             mainAxisSize: MainAxisSize.min,
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: [
  //                               Stack(
  //                                 clipBehavior: Clip.none,
  //                                 children: [
  //                                   AnimatedScale(
  //                                     scale: selected ? 1.12 : 1.0,
  //                                     duration: 300.ms,
  //                                     child: Container(
  //                                       padding: EdgeInsets.all(7.r),
  //                                       decoration: BoxDecoration(
  //                                         shape: BoxShape.circle,
  //                                         gradient: selected
  //                                             ? RadialGradient(colors: [
  //                                                 AppColors.yellow
  //                                                     .withOpacity(.35),
  //                                                 AppColors.orange
  //                                                     .withOpacity(.15)
  //                                               ])
  //                                             : null,
  //                                         boxShadow: selected
  //                                             ? [
  //                                                 BoxShadow(
  //                                                     color: AppColors.yellow
  //                                                         .withOpacity(.5),
  //                                                     blurRadius: 14,
  //                                                     spreadRadius: 1)
  //                                               ]
  //                                             : null,
  //                                       ),
  //                                       child: Icon(icon,
  //                                           color: selected
  //                                               ? AppColors.yellow
  //                                               : Colors.white.withOpacity(.75),
  //                                           size: 22.sp),
  //                                     ),
  //                                   ),
  //                                   if (badge != null)
  //                                     Positioned(
  //                                       top: -2,
  //                                       right: -4,
  //                                       child: Container(
  //                                         padding: EdgeInsets.all(2.r),
  //                                         decoration: BoxDecoration(
  //                                             gradient: const LinearGradient(
  //                                                 colors: [
  //                                                   AppColors.yellow,
  //                                                   AppColors.orange
  //                                                 ]),
  //                                             shape: BoxShape.circle),
  //                                         child: Icon(badge,
  //                                             size: 8.sp, color: Colors.black),
  //                                       ),
  //                                     ),
  //                                 ],
  //                               ),
  //                               SizedBox(height: 4.h),
  //                               AnimatedDefaultTextStyle(
  //                                 duration: 250.ms,
  //                                 style: GoogleFonts.poppins(
  //                                   color: selected
  //                                       ? AppColors.yellow
  //                                       : Colors.white.withOpacity(.7),
  //                                   fontSize: 9.sp,
  //                                   fontWeight:
  //                                       selected ? FontWeight.w800 : FontWeight.w500,
  //                                 ),
  //                                 child: Text(label,
  //                                     maxLines: 1,
  //                                     overflow: TextOverflow.ellipsis,
  //                                     textAlign: TextAlign.center),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     );
  //                   }),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  String _formatNumber(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buffer.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class _LevelOrbitRing extends StatelessWidget {
  final List<CourseData> courses;
  final double progress;
  final double size;

  const _LevelOrbitRing({
    required this.courses,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final double boxSize = size + 34.w;

    if (courses.isEmpty) {
      return SizedBox(width: boxSize, height: boxSize);
    }

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ النقاط المدارية (كل نقطة = كورس)
          ...List.generate(courses.length, (i) {
            final angle = -math.pi / 2 + i * (2 * math.pi / courses.length);
            final radius = size / 2 + 16.w;
            final dx = math.cos(angle) * radius;
            final dy = math.sin(angle) * radius;
            final course = courses[i];

            final Color dotColor =
                course.isLocked ? Colors.white.withOpacity(.25) : course.accentColor;
            final double dotSize = course.isCompleted ? 13.w : 9.w;
            final bool isActive = course.isCurrent;

            Widget dot = Container(
              width: dotSize,
              height: dotSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                border: course.isCompleted
                    ? Border.all(color: Colors.white, width: 1.2)
                    : null,
                boxShadow: course.isLocked
                    ? []
                    : [BoxShadow(color: dotColor.withOpacity(.7), blurRadius: 6)],
              ),
              child: course.isCompleted
                  ? Icon(Icons.check_rounded,
                      size: dotSize * 0.65, color: Colors.black)
                  : null,
            );

            if (isActive) {
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
              strokeWidth: 9.w,
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
                strokeWidth: 9.w,
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
                      color: AppColors.yellow, size: 18.sp)
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
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CourseData {
  final int? id;
  final int? order;
  final String title;
  final String teacher;
  final IconData teacherAvatar;
  final String imageUrl;
  final double progress;
  final int lessonsCount;
  final String duration;
  final bool isCompleted;
  final Color accentColor;
  final bool isLocked;
  final bool isCurrent; 

  const CourseData({
    this.id,
    this.order,
    required this.title,
    required this.teacher,
    required this.teacherAvatar,
    required this.imageUrl,
    required this.progress,
    required this.lessonsCount,
    required this.duration,
    required this.accentColor,
    this.isCompleted = false,
    this.isLocked = false,
    this.isCurrent = false,
  });
}
class AnimatedCourseCard extends StatelessWidget {
  final CourseData course;
  final int index;
  final bool isTapped;
  final bool isHighlighted;
  final VoidCallback onTap;
  final AnimationController borderAnimation;

  const AnimatedCourseCard({
    super.key,
    required this.course,
    required this.index,
    required this.isTapped,
    required this.onTap,
    required this.borderAnimation,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final double avatarSize = 60.w;

    return AnimatedBuilder(
      animation: borderAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: isTapped ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: course.isLocked
                    ? []
                    : [
                        BoxShadow(
                          color: course.accentColor
                              .withOpacity(isHighlighted ? 0.30 : 0.14),
                          blurRadius: isHighlighted ? 26 : 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  // ✅ توهج متحرك، فقط للكورس المميز/الحالي
                  if (isHighlighted)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CardBorderPainter(
                          animationValue: borderAnimation.value,
                          color: course.accentColor,
                        ),
                      ),
                    ),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        margin: EdgeInsets.all(isHighlighted ? 2.w : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: course.isLocked
                                ? [
                                    Colors.white.withOpacity(.05),
                                    Colors.white.withOpacity(.02),
                                  ]
                                : isHighlighted
                                    ? [
                                        course.accentColor.withOpacity(.20),
                                        Colors.white.withOpacity(.06),
                                      ]
                                    : [
                                        Colors.white.withOpacity(.10),
                                        Colors.white.withOpacity(.04),
                                      ],
                          ),
                          border: Border.all(
                            color: course.isLocked
                                ? Colors.white.withOpacity(.08)
                                : isHighlighted
                                    ? course.accentColor.withOpacity(.45)
                                    : Colors.white.withOpacity(.14),
                            width: isHighlighted ? 1.3 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildAvatar(avatarSize),
                            SizedBox(width: 12.w),
                            Expanded(child: _buildInfo()),
                            SizedBox(width: 6.w),
                            _buildTrailing(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate()
        .fadeIn(delay: Duration(milliseconds: 150 + index * 80), duration: 400.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildAvatar(double avatarSize) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 3.w,
                  valueColor:
                      AlwaysStoppedAnimation(Colors.white.withOpacity(.10)),
                ),
              ),
              if (!course.isLocked)
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: course.progress.clamp(0.0, 1.0),
                    strokeWidth: 3.w,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation(course.accentColor),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              Container(
                width: avatarSize - 15.w,
                height: avatarSize - 15.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: course.isLocked
                        ? [Colors.white.withOpacity(.10), Colors.white.withOpacity(.04)]
                        : [
                            course.accentColor.withOpacity(.85),
                            course.accentColor.withOpacity(.45),
                          ],
                  ),
                ),
                child: Icon(
                  course.isLocked
                      ? Icons.lock_rounded
                      : (course.isCompleted
                          ? Icons.check_rounded
                          : _getCourseIcon(index)),
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: -4.h,
          left: -4.w,
          child: Container(
            padding: EdgeInsets.all(4.r),
            constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.dark,
              border: Border.all(
                color: course.isLocked
                    ? Colors.white24
                    : course.accentColor.withOpacity(.8),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              "${index + 1}",
              style: GoogleFonts.poppins(
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w800,
                color: course.isLocked ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isHighlighted)
          Padding(
            padding: EdgeInsets.only(bottom: 3.h),
            child: Text(
              "CONTINUE LEARNING",
              style: GoogleFonts.poppins(
                color: course.accentColor,
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
          ),
        Text(
          course.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: course.isLocked ? Colors.white.withOpacity(.5) : Colors.white,
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5.h),
        Row(
          children: [
            Icon(Icons.person_rounded,
                color: Colors.white.withOpacity(.45), size: 12.sp),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                course.teacher,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.6),
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),
        Row(
          children: [
            _metaChip(icon: Icons.play_lesson_rounded, label: "${course.lessonsCount}"),
            SizedBox(width: 10.w),
            Flexible(child: _metaChip(icon: Icons.access_time_rounded, label: course.duration)),
          ],
        ),
      ],
    );
  }

  Widget _buildTrailing() {
    if (course.isLocked) {
      return Icon(Icons.lock_rounded, color: Colors.white.withOpacity(.3), size: 18.sp);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: course.isCompleted
                ? const Color(0xFF4ADE80).withOpacity(.18)
                : course.accentColor.withOpacity(.18),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: course.isCompleted
                  ? const Color(0xFF4ADE80).withOpacity(.4)
                  : course.accentColor.withOpacity(.35),
            ),
          ),
          child: Text(
            course.isCompleted ? "Done" : "${(course.progress * 100).toInt()}%",
            style: GoogleFonts.poppins(
              color: course.isCompleted ? const Color(0xFF4ADE80) : course.accentColor,
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [course.accentColor, course.accentColor.withOpacity(.7)],
            ),
            boxShadow: [
              BoxShadow(color: course.accentColor.withOpacity(.5), blurRadius: 10),
            ],
          ),
          child: Icon(
            course.progress > 0 ? Icons.play_arrow_rounded : Icons.play_circle_filled_rounded,
            color: Colors.white,
            size: 18.sp,
          ),
        ),
      ],
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(.5), size: 12.sp),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: Colors.white.withOpacity(.55), fontSize: 10.sp),
          ),
        ),
      ],
    );
  }

  IconData _getCourseIcon(int index) {
    final icons = [
      Icons.edit_note_rounded,
      Icons.auto_stories_rounded,
      Icons.menu_book_rounded,
      Icons.school_rounded,
      Icons.cast_for_education_rounded,
      Icons.library_books_rounded,
    ];
    return icons[index % icons.length];
  }
}

class _CardBorderPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _CardBorderPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(20));
    final startAngle = animationValue * math.pi * 2;

    // Outer glow
    final glowPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        colors: [
          color.withOpacity(0),
          color.withOpacity(0.5),
          color.withOpacity(0),
          color.withOpacity(0.35),
          color.withOpacity(0),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawRRect(rect, glowPaint);

    // Inner border
    final borderPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle + 0.3,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.8),
          color.withOpacity(0.5),
          color.withOpacity(0.9),
          color.withOpacity(0.3),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(rect.deflate(1.5), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CardBorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 35});

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
                    ? [BoxShadow(color: Colors.white.withOpacity(0.7), blurRadius: 4, spreadRadius: 0.5)]
                    : null,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0, end: maxOpacity, duration: duration.ms, delay: delay.ms)
                .then().fade(begin: maxOpacity, end: 0, duration: duration.ms),
          );
        }),
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
    final rect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final startAngle = animationValue * math.pi * 2;

    final glowPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        colors: const [Color(0x00FFD35B), Color(0x88FFD35B), Color(0x00F5A201), Color(0x88A8E8F9), Color(0x00B388FF), Color(0x88FF6FB5), Color(0x00FFD35B)],
        stops: [0.0, 0.14, 0.32, 0.5, 0.68, 0.86, 1.0],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawRRect(rect.deflate(3.5), glowPaint);

    final borderPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        colors: const [Color(0xffA8E8F9), Color(0xffFFD35B), Color(0xffF5A201), Color(0xffB388FF), Color(0xffA8E8F9)],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(rect.deflate(0.5), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}
