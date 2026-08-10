import 'dart:math' as math;
import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/home/home_teacher_cubit.dart';
import 'package:fluent/cubit/teacher/home/home_teacher_state.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/models/profile_model.dart';
import 'package:fluent/data/repository/profile_repository.dart';
import 'package:fluent/data/repository/auth_repository.dart';
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

  String _displayName = '';
  String? _imageUrl;

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
      _loadTeacherIdentity();
    });
  }

  Future<void> _loadTeacherIdentity() async {
    String name = widget.userName;
    String? imageUrl;

    try {
      final auth = context.read<AuthRepository>();
      final userRes = await auth.getCurrentUser();
      if (userRes['success'] == true && userRes['data'] is Map) {
        final u = Map<String, dynamic>.from(userRes['data'] as Map);
        final first = (u['first_name'] ?? '').toString().trim();
        final last = (u['last_name'] ?? '').toString().trim();
        final full = ('$first $last').trim();
        if (full.isNotEmpty) name = full;
      }
    } catch (_) {}

    try {
      final profileRepo = context.read<ProfileRepository>();
      final profileRes = await profileRepo.getTeacherProfile();
      if (profileRes['success'] == true &&
          profileRes['data'] is TeacherProfileModel) {
        final p = profileRes['data'] as TeacherProfileModel;
        if (p.imageUrl != null && p.imageUrl!.isNotEmpty) {
          imageUrl = p.imageUrl;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _displayName = name;
      _imageUrl = imageUrl;
    });
  }

  String get _formalGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Future<void> _openProfile() async {
    HapticFeedback.selectionClick();
    await Navigator.pushNamed(context, profileRoute);
    if (mounted) _loadTeacherIdentity();
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
                        _buildTestsOverview(),
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
                  // Professional avatar (tappable → profile)
                  GestureDetector(
                    onTap: _openProfile,
                    child: SizedBox(
                      width: 72.w,
                      height: 72.w,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                                width: 72.w,
                                height: 72.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const SweepGradient(
                                    colors: [
                                      AppColors.sky,
                                      AppColors.yellow,
                                      AppColors.orange,
                                      AppColors.sky,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.sky.withOpacity(.40),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .rotate(
                                duration: 10.seconds,
                                curve: Curves.linear,
                              ),
                          Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(.30),
                              border: Border.all(
                                color: AppColors.dark,
                                width: 3,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _imageUrl != null
                                ? Image.network(
                                    _imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.school_rounded,
                                      color: Colors.white,
                                      size: 28.sp,
                                    ),
                                  )
                                : Icon(
                                    Icons.school_rounded,
                                    color: Colors.white,
                                    size: 28.sp,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formalGreeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.72),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, AppColors.sky],
                          ).createShader(bounds),
                          child: Text(
                            _displayName.isNotEmpty
                                ? _displayName
                                : widget.userName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Instructor',
                          style: GoogleFonts.poppins(
                            color: AppColors.yellow.withOpacity(.85),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
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
                  _circleIconButton(
                    icon: Icons.settings_rounded,
                    onTap: _openProfile,
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Container(height: 1, color: Colors.white.withOpacity(.10)),
              SizedBox(height: 12.h),

              // ✅ هنا نستخدم BlocBuilder بأمان لجلب البيانات من الـ Cubit الجديد
              BlocBuilder<TeacherHomeCubit, TeacherHomeState>(
                builder: (context, state) {
                  int courses = 0, lessons = 0, questions = 0, tests = 0;
                  if (state is TeacherHomeLoaded) {
                    courses = state.totalCourses;
                    lessons = state.totalLessons;
                    questions = state.totalQuestions;
                    tests = state.totalTests;
                  }

                  // 2×2 grid so labels stay fully readable on narrow screens
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _statPill(
                              icon: Icons.library_books_rounded,
                              iconColor: AppColors.sky,
                              label: "Courses",
                              value: courses,
                              onTap: () => _navigateTo(teacherCoursesRoute),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _statPill(
                              icon: Icons.play_lesson_rounded,
                              iconColor: AppColors.yellow,
                              label: "Lessons",
                              value: lessons,
                              onTap: () => _navigateTo(teacherStatusBoardRoute),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: _statPill(
                              icon: Icons.quiz_outlined,
                              iconColor: const Color(0xffB388FF),
                              label: "Questions",
                              value: questions,
                              onTap: () => _navigateTo(questionsListRoute),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _statPill(
                              icon: Icons.assignment_rounded,
                              iconColor: AppColors.orange,
                              label: "Tests",
                              value: tests,
                              onTap: () => _navigateTo(teacherStatusBoardRoute),
                            ),
                          ),
                        ],
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
    VoidCallback? onTap,
  }) {
    final pill = _glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      radius: 16.r,
      gradientColors: [
        Colors.white.withOpacity(.12),
        Colors.white.withOpacity(.04),
      ],
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  iconColor.withOpacity(.35),
                  iconColor.withOpacity(.05),
                ],
              ),
            ),
            child: Icon(icon, color: iconColor, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: 1100.ms,
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    "${_formatNumber(v)}$suffix",
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.75),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: pill,
    );
  }

  Widget _buildQuickStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 360;
        final creation = _contentCreationCard();
        final performance = _performanceCard();

        if (stackVertically) {
          return Column(
                children: [
                  creation,
                  SizedBox(height: 10.h),
                  performance,
                ],
              )
              .animate()
              .fadeIn(delay: 250.ms, duration: 500.ms)
              .moveY(begin: 10, end: 0);
        }

        return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: creation),
                SizedBox(width: 10.w),
                Expanded(flex: 5, child: performance),
              ],
            )
            .animate()
            .fadeIn(delay: 250.ms, duration: 500.ms)
            .moveY(begin: 10, end: 0);
      },
    );
  }

  Widget _contentCreationCard() {
    return _glassContainer(
      padding: EdgeInsets.all(14.w),
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
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "Content Creation",
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "Create engaging lessons and questions",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.85),
              fontSize: 11.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 12.h),
          // Full-width action buttons — labels always visible
          _quickActionButton(
            Icons.play_lesson_outlined,
            "New Lesson",
            AppColors.yellow,
            () =>
                _navigateTo(teacherCoursesRoute), // pick course → create lesson
          ),
          SizedBox(height: 8.h),
          _quickActionButton(
            Icons.quiz_outlined,
            "New Question",
            const Color(0xffB388FF),
            () => _navigateTo(questionsListRoute),
          ),
          SizedBox(height: 8.h),
          _quickActionButton(
            Icons.assignment_outlined,
            "New Test",
            AppColors.orange,
            () => _navigateTo(
              teacherCoursesRoute,
            ), // pick course/lesson → create test
          ),
        ],
      ),
    );
  }

  Widget _performanceCard() {
    return BlocBuilder<TeacherHomeCubit, TeacherHomeState>(
      builder: (context, state) {
        int courses = 0, lessons = 0, questions = 0, tests = 0;
        int published = 0, draft = 0, pending = 0, inReview = 0;
        if (state is TeacherHomeLoaded) {
          courses = state.totalCourses;
          lessons = state.totalLessons;
          questions = state.totalQuestions;
          tests = state.totalTests;
          published = state.publishedTests;
          draft = state.draftTests;
          pending = state.pendingTests;
          inReview = state.inReviewTests;
        }

        final maxContent = [
          courses,
          lessons,
          questions,
          tests,
        ].fold<int>(1, (a, b) => a > b ? a : b);

        return _glassContainer(
          padding: EdgeInsets.all(14.w),
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
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Overview",
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _statBar(
                "Courses",
                courses / maxContent,
                AppColors.sky,
                count: courses,
              ),
              SizedBox(height: 8.h),
              _statBar(
                "Lessons",
                lessons / maxContent,
                AppColors.yellow,
                count: lessons,
              ),
              SizedBox(height: 8.h),
              _statBar(
                "Questions",
                questions / maxContent,
                const Color(0xffB388FF),
                count: questions,
              ),
              SizedBox(height: 8.h),
              _statBar(
                "Tests",
                tests / maxContent,
                AppColors.orange,
                count: tests,
              ),
              if (tests > 0) ...[
                SizedBox(height: 12.h),
                Container(height: 1, color: Colors.white.withOpacity(0.1)),
                SizedBox(height: 10.h),
                Text(
                  "Test status",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _statusMiniChip("Published", published, Colors.greenAccent),
                    _statusMiniChip("Draft", draft, Colors.white70),
                    _statusMiniChip("Pending", pending, AppColors.lightOrange),
                    _statusMiniChip("In Review", inReview, AppColors.sky),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statusMiniChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        "$label · $count",
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _quickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 12.sp),
            ],
          ),
        ),
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

  Widget _statBar(String label, double progress, Color color, {int? count}) {
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.85),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (count != null)
              Text(
                "$count",
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Stack(
            children: [
              Container(
                height: 6.h,
                width: double.infinity,
                color: Colors.white.withOpacity(.15),
              ),
              FractionallySizedBox(
                widthFactor: clamped,
                child: Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(.5), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildTestsOverview() {
    return BlocBuilder<TeacherHomeCubit, TeacherHomeState>(
      builder: (context, state) {
        int totalTests = 0;
        int published = 0;
        int draft = 0;
        int pending = 0;
        int inReview = 0;
        int approved = 0;
        int archived = 0;
        int closed = 0;
        int changesRequested = 0;
        List<TestModel> recent = const [];

        if (state is TeacherHomeLoaded) {
          totalTests = state.totalTests;
          published = state.publishedTests;
          draft = state.draftTests;
          pending = state.pendingTests;
          inReview = state.inReviewTests;
          approved = state.approvedTests;
          archived = state.archivedTests;
          closed = state.closedTests;
          changesRequested = state.changesRequestedTests;
          recent = state.recentTests;
        }

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
                        Icons.assignment_rounded,
                        color: AppColors.orange,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "Tests Overview",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _navigateTo(teacherStatusBoardRoute),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.orange.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            "View All",
                            style: GoogleFonts.poppins(
                              color: AppColors.orange,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // ✅ تفصيل حالات الاختبارات (يظهر فقط لو في اختبارات)
                  if (totalTests > 0) ...[
                    _testsProgressBar(
                      published: published,
                      draft: draft,
                      pending: pending,
                      inReview: inReview,
                      approved: approved,
                      archived: archived,
                      closed: closed,
                      changesRequested: changesRequested,
                      total: totalTests,
                    ),
                    SizedBox(height: 12.h),
                  ],

                  // ✅ أحدث الاختبارات
                  if (state is TeacherHomeLoading)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Center(
                        child: SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    )
                  else if (recent.isEmpty)
                    _emptyTestsState()
                  else
                    ...List.generate(recent.length, (i) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i == recent.length - 1 ? 0 : 8.h,
                        ),
                        child: _recentTestTile(recent[i], i)
                            .animate()
                            .fadeIn(delay: (120 * i).ms, duration: 400.ms)
                            .moveX(begin: 12, end: 0),
                      );
                    }),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 450.ms, duration: 500.ms)
            .moveY(begin: 10, end: 0);
      },
    );
  }

  Widget _testsProgressBar({
    required int published,
    required int draft,
    required int pending,
    required int inReview,
    required int approved,
    required int archived,
    required int closed,
    required int changesRequested,
    required int total,
  }) {
    // ✅ نسبة كل حالة من الإجمالي
    double pct(int n) => total == 0 ? 0 : n / total;

    // ✅ الشريط الملوّن (stacked)
    final segments = <_TestSegment>[
      _TestSegment(Colors.greenAccent, pct(published)),
      _TestSegment(AppColors.sky, pct(approved)),
      _TestSegment(AppColors.lightOrange, pct(pending)),
      _TestSegment(const Color(0xffB388FF), pct(inReview)),
      _TestSegment(Colors.redAccent, pct(changesRequested)),
      _TestSegment(Colors.white70, pct(draft)),
      _TestSegment(Colors.purpleAccent, pct(archived)),
      _TestSegment(Colors.blueGrey, pct(closed)),
    ].where((s) => s.ratio > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Stacked Progress Bar
        Row(
          children: [
            Text(
              "Status Breakdown",
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(.75),
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              "$total total",
              style: GoogleFonts.poppins(
                color: AppColors.orange,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            height: 8.h,
            color: Colors.white.withOpacity(.10),
            child: Row(
              children: [
                for (final s in segments)
                  Expanded(
                    flex: (s.ratio * 1000).round().clamp(1, 100000),
                    child: Container(color: s.color),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        // ✅ Legend (الأكثر أهمية)
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: [
            if (published > 0)
              _legendDot(Colors.greenAccent, "Live", published),
            if (approved > 0) _legendDot(AppColors.sky, "Approved", approved),
            if (pending > 0)
              _legendDot(AppColors.lightOrange, "Pending", pending),
            if (inReview > 0)
              _legendDot(const Color(0xffB388FF), "Review", inReview),
            if (changesRequested > 0)
              _legendDot(Colors.redAccent, "Changes", changesRequested),
            if (draft > 0) _legendDot(Colors.white70, "Draft", draft),
            if (archived > 0)
              _legendDot(Colors.purpleAccent, "Archived", archived),
            if (closed > 0) _legendDot(Colors.blueGrey, "Closed", closed),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(.5), blurRadius: 4),
              ],
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            "$label ",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.65),
              fontSize: 8.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "$count",
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentTestTile(TestModel test, int index) {
    final color = _testStatusColor(test.normalizedStatus);
    final title = test.titleEn.isNotEmpty
        ? test.titleEn
        : (test.titleAr.isNotEmpty ? test.titleAr : 'Untitled Test');

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        testDetailViewRoute,
        arguments: {'testId': test.id},
      ),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.45)),
              ),
              child: Icon(
                test.isCourseTest
                    ? Icons.library_books_rounded
                    : Icons.play_lesson_rounded,
                color: color,
                size: 16.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      _testStatusBadge(test.normalizedStatus, color),
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.help_outline,
                        color: Colors.white.withOpacity(.55),
                        size: 10.sp,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        "${test.questions.length} Q",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        width: 2.w,
                        height: 2.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          "Pass ${test.passingScore}%",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.55),
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(.7),
              size: 12.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _testStatusBadge(String status, Color color) {
    final label = _testStatusLabel(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 7.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _testStatusLabel(String status) {
    switch (status) {
      case 'published':
        return 'LIVE';
      case 'in_review':
        return 'REVIEW';
      case 'changes_requested':
        return 'CHANGES';
      case 'approved':
        return 'APPROVED';
      case 'archived':
        return 'ARCHIVED';
      case 'closed':
        return 'CLOSED';
      case 'pending':
        return 'PENDING';
      case 'draft':
      default:
        return 'DRAFT';
    }
  }

  Color _testStatusColor(String status) {
    switch (status) {
      case 'published':
        return Colors.greenAccent;
      case 'pending':
        return AppColors.lightOrange;
      case 'in_review':
        return const Color(0xffB388FF);
      case 'changes_requested':
        return Colors.redAccent;
      case 'approved':
        return AppColors.sky;
      case 'archived':
        return Colors.purpleAccent;
      case 'closed':
        return Colors.blueGrey;
      case 'draft':
      default:
        return Colors.white70;
    }
  }

  Widget _emptyTestsState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.orange.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orange.withOpacity(0.35)),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: AppColors.orange,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "No tests yet",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Create tests from a course to assess students",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.65),
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

// ✅ بيانات كل جزء في شريط الـ Stacked Progress
class _TestSegment {
  final Color color;
  final double ratio;
  const _TestSegment(this.color, this.ratio);
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
