import 'dart:math' as math;
import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/home/home_teacher_cubit.dart';
import 'package:fluent/cubit/teacher/home/home_teacher_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherHomeScreen extends StatefulWidget {
  final String userName;
  const TeacherHomeScreen({super.key, this.userName = "Professor"});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _borderFlowController;
  late final AnimationController _pulseController;
  late final ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  static const List<List<Color>> _featureGradients = [
    [Color(0xffA8E8F9), Color(0xff00537A)],
    [Color(0xffFFD35B), Color(0xffF5A201)],
    [Color(0xffB388FF), Color(0xff7C4DFF)],
  ];

  @override
  void initState() {
    super.initState();
    _borderFlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });

    // ✅ جلب البيانات تلقائياً عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherHomeCubit>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _borderFlowController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _navigateTo(String route) async {
    HapticFeedback.selectionClick();
    await Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          _buildBackground(),
          _TwinklingStars(count: 40),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ), // ✅ تقليل الـ Padding للموبايل
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroGreetingCard(),
                        SizedBox(height: 16.h),
                        _buildQuickStats(),
                        SizedBox(height: 16.h),
                        _buildFeaturesSection(),
                        SizedBox(height: 16.h),
                        // _buildActivityOverview(),
                        // SizedBox(height: 16.h),
                        _buildRecentActivity(),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
          top: 380.h,
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
          bottom: 0,
          left: 0,
          right: 0,
          child: _parallax(
            0.05,
            CustomPaint(
              size: Size(double.infinity, 240.h),
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

  Widget _buildHeroGreetingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        22.r,
      ), // ✅ تقليل الزوايا قليلاً للموبايل
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.10),
                Colors.white.withOpacity(.03),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.16)),
            boxShadow: [
              BoxShadow(
                color: AppColors.sky.withOpacity(.14),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                            width: 54.w,
                            height: 54.w, // ✅ تصغير قليلاً
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const SweepGradient(
                                colors: [
                                  AppColors.sky,
                                  AppColors.yellow,
                                  AppColors.sky,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sky.withOpacity(.45),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .rotate(duration: 8.seconds, curve: Curves.linear),
                      Container(
                        width: 46.w,
                        height: 46.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(.25),
                          border: Border.all(color: AppColors.dark, width: 2.5),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("👋", style: TextStyle(fontSize: 14.sp)),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                "Welcome back,",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(.75),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, AppColors.sky],
                          ).createShader(bounds),
                          child: Text(
                            widget.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .3,
                            ), // ✅ تصغير الخط
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
                  SizedBox(width: 6.w),
                  _circleIconButton(icon: Icons.settings_rounded, onTap: () {}),
                ],
              ),
              SizedBox(height: 14.h),
              Container(height: 1, color: Colors.white.withOpacity(.10)),
              SizedBox(height: 12.h),

              // ✅ هنا نستخدم BlocBuilder بأمان لجلب البيانات من الـ Cubit الجديد
              BlocBuilder<TeacherHomeCubit, TeacherHomeState>(
                builder: (context, state) {
                  int courses = 0, lessons = 0, questions = 0;
                  if (state is TeacherHomeLoaded) {
                    courses = state.totalCourses;
                    lessons = state.totalLessons;
                    questions = state.totalQuestions;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _statPill(
                          icon: Icons.library_books_rounded,
                          iconColor: AppColors.sky,
                          label: "Courses",
                          value: courses,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: _statPill(
                          icon: Icons.play_lesson_rounded,
                          iconColor: AppColors.yellow,
                          label: "Lessons",
                          value: lessons,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: _statPill(
                          icon: Icons.quiz_outlined,
                          iconColor: const Color(0xffB388FF),
                          label: "Questions",
                          value: questions,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(.14),
                  Colors.white.withOpacity(.06),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(.25)),
            ),
            child: Icon(icon, color: Colors.white, size: 18.sp),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2.h,
              right: -2.w,
              child: Container(
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.redAccent, Color(0xFFFF6B6B)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dark, width: 1.5),
                ),
                constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                child: Center(
                  child: Text(
                    "$badgeCount",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
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

  Widget _statPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int value,
    String suffix = "",
  }) {
    return _glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      radius: 16.r,
      gradientColors: [
        Colors.white.withOpacity(.12),
        Colors.white.withOpacity(.04),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(5.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  iconColor.withOpacity(.35),
                  iconColor.withOpacity(.05),
                ],
              ),
            ),
            child: Icon(icon, color: iconColor, size: 14.sp),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: value),
                    duration: 1100.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text(
                      "${_formatNumber(v)}$suffix",
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.6),
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: _contentCreationCard()),
            SizedBox(width: 8.w),
            Expanded(flex: 5, child: _performanceCard()),
          ],
        )
        .animate()
        .fadeIn(delay: 250.ms, duration: 500.ms)
        .moveY(begin: 10, end: 0);
  }

  Widget _contentCreationCard() {
    return _glassContainer(
      padding: EdgeInsets.all(12.w),
      radius: 20.r,
      gradientColors: [
        AppColors.primary.withOpacity(.65),
        const Color(0xff01466A).withOpacity(.55),
      ],
      borderColor: Colors.white.withOpacity(.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ringIcon(Icons.add_circle_outline_rounded, AppColors.sky),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  "Content Creation",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "Create engaging lessons and questions",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.85),
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            // ✅ استخدام Wrap لمنع التداخل
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              _quickActionChip(
                Icons.play_lesson_outlined,
                "New Lesson",
                AppColors.yellow,
                () => _navigateTo(teacherStatusBoardRoute),
              ),
              _quickActionChip(
                Icons.quiz_outlined,
                "New Question",
                const Color(0xffB388FF),
                () => _navigateTo(questionsListRoute),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceCard() {
    return _glassContainer(
      padding: EdgeInsets.all(12.w),
      radius: 20.r,
      gradientColors: [
        AppColors.sky.withOpacity(.15),
        AppColors.primary.withOpacity(.35),
      ],
      borderColor: Colors.white.withOpacity(.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ringIcon(Icons.insights_rounded, AppColors.yellow),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  "Performance",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // ✅ تم تغيير التصميم ليصبح عمودياً (تحت بعض) بدلاً من جنب بعض لمنع التداخل
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statBar("Courses", 0.75, AppColors.sky),
              SizedBox(height: 6.h),
              _statBar("Lessons", 0.60, AppColors.yellow),
              SizedBox(height: 6.h),
              _statBar("Questions", 0.85, const Color(0xffB388FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ringIcon(IconData icon, Color color) {
    return SizedBox(
      width: 28.w,
      height: 28.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 2.5.w,
              valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(.12)),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 0.7),
            duration: 1200.ms,
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => CircularProgressIndicator(
              value: v,
              strokeWidth: 2.5.w,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(color),
              backgroundColor: Colors.transparent,
            ),
          ),
          Icon(icon, color: color, size: 13.sp),
        ],
      ),
    );
  }

  Widget _quickActionChip(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 11.sp),
            SizedBox(width: 3.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 5.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(.7),
                fontSize: 7.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      (
        "Status Board",
        "Track your content",
        Icons.view_kanban_outlined,
        teacherStatusBoardRoute,
      ),
      (
        "Question Bank",
        "Manage questions",
        Icons.quiz_outlined,
        questionsListRoute,
      ),
      (
        "My Courses",
        "View & edit courses",
        Icons.library_books_outlined,
        teacherCoursesRoute,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _glassContainer(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              radius: 16.r,
              gradientColors: [
                Colors.white.withOpacity(.08),
                Colors.white.withOpacity(.03),
              ],
              child: Row(
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.sky,
                    size: 15.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Quick Access",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      "${features.length} features",
                      style: GoogleFonts.poppins(
                        color: AppColors.yellow,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 500.ms)
            .moveY(begin: 8, end: 0),
        SizedBox(height: 10.h),
        ...List.generate(features.length, (i) {
          final (title, subtitle, icon, route) = features[i];
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _featureCard(title, subtitle, icon, route, i)
                .animate()
                .fadeIn(delay: (350 + i * 80).ms, duration: 400.ms)
                .moveX(begin: 20, end: 0),
          );
        }),
      ],
    );
  }

  Widget _featureCard(
    String title,
    String subtitle,
    IconData icon,
    String route,
    int index,
  ) {
    final gradient = _featureGradients[index % _featureGradients.length];
    return GestureDetector(
      onTap: () => _navigateTo(route),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(.10),
                  Colors.white.withOpacity(.04),
                ],
              ),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: Colors.white.withOpacity(.15)),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            gradient[0].withOpacity(.3),
                            gradient[1].withOpacity(.15),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: gradient[0], size: 22.sp),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
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
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.7),
                          fontSize: 10.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.1),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: gradient[0],
                    size: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildActivityOverview() {
  //   return _glassContainer(
  //         padding: EdgeInsets.all(14.w),
  //         radius: 18.r,
  //         gradientColors: [
  //           Colors.white.withOpacity(.08),
  //           Colors.white.withOpacity(.03),
  //         ],
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.history_rounded,
  //                   color: AppColors.yellow,
  //                   size: 16.sp,
  //                 ),
  //                 SizedBox(width: 6.w),
  //                 Text(
  //                   "Recent Activity",
  //                   style: GoogleFonts.poppins(
  //                     color: Colors.white,
  //                     fontSize: 12.sp,
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             SizedBox(height: 12.h),
  //             _activityItem(
  //               Icons.check_circle_rounded,
  //               "Published 3 new lessons",
  //               "2 hours ago",
  //               Colors.greenAccent,
  //             ),
  //             SizedBox(height: 8.h),
  //             _activityItem(
  //               Icons.quiz_outlined,
  //               "Added 10 new questions",
  //               "Yesterday",
  //               const Color(0xffB388FF),
  //             ),
  //             SizedBox(height: 8.h),
  //             _activityItem(
  //               Icons.edit_rounded,
  //               "Updated course content",
  //               "3 days ago",
  //               AppColors.sky,
  //             ),
  //           ],
  //         ),
  //       )
  //       .animate()
  //       .fadeIn(delay: 400.ms, duration: 500.ms)
  //       .moveY(begin: 10, end: 0);
  // }

  Widget _activityItem(IconData icon, String title, String time, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.18),
          ),
          child: Icon(icon, color: color, size: 15.sp),
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
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                time,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.5),
                  fontSize: 9.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return _glassContainer(
          padding: EdgeInsets.all(14.w),
          radius: 18.r,
          gradientColors: [
            Colors.white.withOpacity(.08),
            Colors.white.withOpacity(.03),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: AppColors.orange,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Quick Tips",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _tipCard(
                "📚 Rich Content",
                "Add images and audio to make lessons engaging",
                AppColors.sky,
              ),
              SizedBox(height: 8.h),
              _tipCard(
                "❓ Varied Questions",
                "Mix multiple choice with open-ended",
                AppColors.yellow,
              ),
              SizedBox(height: 8.h),
              _tipCard(
                "📊 Track Progress",
                "Use Status Board to monitor engagement",
                const Color(0xffB388FF),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 500.ms)
        .moveY(begin: 10, end: 0);
  }

  Widget _tipCard(String title, String description, Color color) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.7),
                    fontSize: 9.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
