
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

import 'package:fluent/cubit/student/levels/levels_cubit.dart';
import 'package:fluent/cubit/student/levels/levels_state.dart';
import 'package:fluent/data/models/level_model.dart';

enum LevelStatus { completed, current, locked, boss, available }

class LevelPathData {
  final int? id;
  final String title;
  final String subtitle;
  final LevelStatus status;
  final IconData icon;
  final double? price;
  final int? order;
  final List<Color>? colors; 

  const LevelPathData({
    this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    this.price,
    this.order,
    this.colors,
  });
}

class StudentHomeScreen extends StatefulWidget {
  final String userName;
  final int xp;
  final int streakDays;
  final int level;
  final double levelProgress; 

  const StudentHomeScreen({
    super.key,
    this.userName = "Rasha",
    this.xp = 12540,
    this.streakDays = 15,
    this.level = 8,
    this.levelProgress = 0.78,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with TickerProviderStateMixin {
  int _selectedNavIndex = 0;
  late final AnimationController _pathFlowController;
  late final AnimationController _borderFlowController;

  late final ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  List<LevelPathData> _levels = [];

  static const List<IconData> _decorativeIcons = [
    Icons.auto_awesome_rounded,
    Icons.diamond_rounded,
    Icons.flight_takeoff_rounded,
    Icons.restaurant_rounded,
    Icons.public_rounded,
    Icons.school_rounded,
  ];

  IconData _iconForOrder(int order) =>
      _decorativeIcons[order % _decorativeIcons.length];

  static const List<List<Color>> _availableGradients = [
    [Color(0xff4FACFE), Color(0xff2E6BE6)], // أزرق
    [Color(0xffB388FF), Color(0xff7C4DFF)], // موف
    [Color(0xff36D1C4), Color(0xff1FA2A6)], // فيروزي
    [Color(0xffFF8FD9), Color(0xffD6409F)], // وردي
  ];

  List<Color> _availableColorsFor(int availableIndex) =>
      _availableGradients[availableIndex % _availableGradients.length];

  LevelPathData _toPathData(
    LevelModel level,
    LevelStatus status, {
    List<Color>? colors,
  }) {
    return LevelPathData(
      id: level.id,
      title: level.name,
      subtitle: "${level.minimumScore}-${level.maximumScore} pts",
      status: status,
      icon: _iconForOrder(level.order),
      price: level.priceValue,
      order: level.order,
      colors: colors,
    );
  }

  List<LevelPathData> _mapLevels(StudentLevelsModel data) {
    final list = <LevelPathData>[];

    final completed = [...data.completedLevels]
      ..sort((a, b) => a.order.compareTo(b.order));
    list.addAll(completed.map((l) => _toPathData(l, LevelStatus.completed)));

    if (data.currentLevel != null) {
      list.add(_toPathData(data.currentLevel!, LevelStatus.current));
    }

    final available = [...data.availableLevels]
      ..sort((a, b) => a.order.compareTo(b.order));
    for (int i = 0; i < available.length; i++) {
      list.add(_toPathData(
        available[i],
        LevelStatus.available,
        colors: _availableColorsFor(i),
      ));
    }

    final locked = [...data.lockedLevels]
      ..sort((a, b) => a.order.compareTo(b.order));
    list.addAll(locked.map((l) => _toPathData(l, LevelStatus.locked)));

    return list;
  }

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
      final cubit = context.read<StudentLevelsCubit>();
      if (cubit.state is StudentLevelsInitial) {
        cubit.fetchStudentLevels();
      }
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
                        _buildHeroGreetingCard(),
                        SizedBox(height: 20.h),
                        _buildDailyChallengeAndLeaders(),
                        SizedBox(height: 16.h),
                        _buildJourneyOverview(),
                        SizedBox(height: 14.h),
                        _PathTransition(),
                        SizedBox(height: 6.h),
                        BlocBuilder<StudentLevelsCubit, StudentLevelsState>(
                          builder: (context, state) {
                            if (state is StudentLevelsLoading ||
                                state is StudentLevelsInitial) {
                              return _levelsLoadingCard();
                            }

                            if (state is StudentLevelsFailure) {
                              return _levelsErrorCard(state.message);
                            }

                            if (state is StudentLevelsSuccess) {
                              _levels = _mapLevels(state.data);
                              return _LevelsPath(
                                levels: _levels,
                                flowController: _pathFlowController,
                                userName: widget.userName,
                                xp: widget.xp,
                                streakDays: widget.streakDays,
                                level: widget.level,
                                levelProgress: widget.levelProgress,
                              );
                            }

                            return const SizedBox.shrink();
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

  Widget _levelsLoadingCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 50.h),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.yellow),
    );
  }

  Widget _levelsErrorCard(String message) {
    return _glassContainer(
      padding: EdgeInsets.all(16.w),
      radius: 20.r,
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
            onTap: () =>
                context.read<StudentLevelsCubit>().fetchStudentLevels(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
          top: 700.h,
          right: -60.w,
          child: _parallax(
            0.09,
            _glowCircle(AppColors.orange, 220.w, 130, 25)
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

    Widget _buildHeroGreetingCard() {
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
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(
                            colors: [
                              AppColors.yellow,
                              AppColors.orange,
                              AppColors.sky,
                              AppColors.yellow,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellow.withOpacity(.45),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ).animate(onPlay: (c) => c.repeat()).rotate(
                            duration: 8.seconds,
                            curve: Curves.linear,
                          ),
                      Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sky.withOpacity(.25),
                          border: Border.all(color: AppColors.dark, width: 2.5),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 26.sp,
                        ),
                      ),
                      Positioned(
                        top: -10.h,
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.yellow,
                          size: 18.sp,
                          shadows: [
                            Shadow(color: AppColors.orange, blurRadius: 10),
                            Shadow(
                                color: AppColors.yellow.withOpacity(.6),
                                blurRadius: 18),
                          ],
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.12, 1.12),
                              duration: 1600.ms,
                              curve: Curves.easeInOut,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("👋", style: TextStyle(fontSize: 15.sp)),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                "Good evening,",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(.75),
                                  fontSize: 13.sp,
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
                              fontSize: 21.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .3,
                            ),
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
                  SizedBox(width: 8.w),
                  _circleIconButton(icon: Icons.settings_rounded, onTap: () {}),
                ],
              ),
              SizedBox(height: 16.h),
              Container(height: 1, color: Colors.white.withOpacity(.10)),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: _statPill(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.yellow,
                      label: "XP",
                      value: widget.xp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _statPill(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.orange,
                      label: "Streak",
                      value: widget.streakDays,
                      suffix: "d",
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(child: _levelPill()),
                ],
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

  Widget _statPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int value,
    String suffix = "",
  }) {
    return _glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.h),
      radius: 18.r,
      gradientColors: [
        Colors.white.withOpacity(.12),
        Colors.white.withOpacity(.04),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  iconColor.withOpacity(.35),
                  iconColor.withOpacity(.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 15.sp),
          ),
          SizedBox(width: 7.w),
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
                        fontSize: 14.sp,
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
                    fontSize: 9.sp,
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

  Widget _levelPill() {
    return _glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.h),
      radius: 18.r,
      gradientColors: [
        Colors.white.withOpacity(.12),
        Colors.white.withOpacity(.04),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xffB388FF), Color(0xff7C4DFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffB388FF).withOpacity(.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(Icons.military_tech_rounded,
                color: Colors.white, size: 15.sp),
          ),
          SizedBox(width: 7.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Lvl ${widget.level}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    height: 5.h,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: Colors.white.withOpacity(.15)),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.levelProgress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.sky, AppColors.yellow],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment(
                                widget.levelProgress.clamp(0.0, 1.0) - 0.5, 0),
                            child: Container(
                              width: 8.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .moveX(
                                  begin: -30,
                                  end: 30,
                                  duration: 1800.ms,
                                  curve: Curves.easeInOut,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallengeAndLeaders() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _dailyChallengeCard()),
        SizedBox(width: 10.w),
        Expanded(flex: 5, child: _topLearnersCard()),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 500.ms).moveY(begin: 10, end: 0);
  }

  Widget _dailyChallengeRingIcon() {
    return SizedBox(
      width: 30.w,
      height: 30.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 2.6.w,
              valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(.12)),
            ),
          ),
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 0.7),
              duration: 1200.ms,
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 2.6.w,
                strokeCap: StrokeCap.round,
                valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Icon(Icons.local_fire_department_rounded,
              color: AppColors.orange, size: 14.sp),
        ],
      ),
    );
  }

  Widget _dailyChallengeCard() {
    return _glassContainer(
      padding: EdgeInsets.all(14.w),
      radius: 22.r,
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
              _dailyChallengeRingIcon(),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  "Daily Challenge",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            "Complete 10 new words",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.85),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Stack(
            children: [
              Container(
                height: 9.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: Container(
                  height: 9.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.yellow],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withOpacity(.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0.2, 0),
                  child: Container(
                    width: 12.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .moveX(
                        begin: -20,
                        end: 30,
                        duration: 1500.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "7/10",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "70%",
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded,
                      color: AppColors.yellow, size: 15.sp)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.18, 1.18),
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
              SizedBox(width: 6.w),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      "Reward: ",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.7),
                        fontSize: 10.sp,
                      ),
                    ),
                    Icon(Icons.star_rounded,
                        color: AppColors.yellow, size: 11.sp),
                    SizedBox(width: 2.w),
                    Flexible(
                      child: Text(
                        "250 XP",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppColors.yellow,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topLearnersCard() {
    final leaders = [
      ("Omar", "18,200", AppColors.yellow, "1"),
      ("Lina", "16,400", AppColors.sky, "2"),
      ("Ziad", "15,100", AppColors.orange, "3"),
    ];

    return _glassContainer(
      padding: EdgeInsets.fromLTRB(12.w, 14.w, 12.w, 10.w),
      radius: 22.r,
      gradientColors: [
        AppColors.sky.withOpacity(.15),
        AppColors.primary.withOpacity(.35),
      ],
      borderColor: Colors.white.withOpacity(.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  color: AppColors.yellow, size: 15.sp),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  "Top Learners",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5.sp,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  "View all",
                  style: GoogleFonts.poppins(
                    color: AppColors.yellow,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _podiumSlot(leaders[1], pedestalHeight: 46.h, avatarSize: 30.w),
              SizedBox(width: 4.w),
              _podiumSlot(leaders[0],
                  pedestalHeight: 62.h, avatarSize: 38.w, crown: true),
              SizedBox(width: 4.w),
              _podiumSlot(leaders[2], pedestalHeight: 36.h, avatarSize: 26.w),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumSlot(
    (String, String, Color, String) leader, {
    required double pedestalHeight,
    required double avatarSize,
    bool crown = false,
  }) {
    final (name, xp, color, rank) = leader;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (crown)
            Icon(Icons.emoji_events_rounded, color: AppColors.yellow, size: 15.sp)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                )
          else
            SizedBox(height: 15.sp),
          SizedBox(height: 4.h),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [color, color.withOpacity(.6)]),
              border: Border.all(color: Colors.white.withOpacity(.5), width: 1.2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(.55), blurRadius: 10),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0] : "?",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: avatarSize * 0.42,
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            "$xp XP",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.6),
              fontSize: 8.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            width: double.infinity,
            height: pedestalHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(.55), color.withOpacity(.12)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
              border: Border.all(color: color.withOpacity(.45)),
            ),
            alignment: Alignment.center,
            child: Text(
              rank,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyOverview() {
    final completed =
        _levels.where((l) => l.status == LevelStatus.completed).length;
    final total = _levels.isNotEmpty ? _levels.length : 1;

    Color dotColor(LevelStatus status) {
      switch (status) {
        case LevelStatus.completed:
          return const Color(0xFF4ADE80);
        case LevelStatus.current:
          return AppColors.yellow;
        case LevelStatus.boss:
          return const Color(0xffFF6FB5);
        case LevelStatus.available:
          return AppColors.sky;
        case LevelStatus.locked:
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
            "Your Journey",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(_levels.length, (i) {
              final color = dotColor(_levels[i].status);
              final isLocked = _levels[i].status == LevelStatus.locked;
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
                        : [BoxShadow(color: color.withOpacity(.7), blurRadius: 5)],
                  ),
                ),
              );
            }),
          ),
          SizedBox(width: 8.w),
          Text(
            "$completed/$total",
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms).moveY(begin: 8, end: 0);
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
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(items.length, (i) {
                          final selected = i == _selectedNavIndex;
                          final (icon, label, badge) = items[i];

                          return Expanded(
                            child: GestureDetector(
                              onTap: () async {
                               HapticFeedback.selectionClick();
                               setState(() => _selectedNavIndex = i);

                                if (i == 0) return;

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
                                                  : Colors.white
                                                      .withOpacity(.75),
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
                      Positioned(
                        right: 10,
                        top: 8,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.sky.withOpacity(.55),
                          size: 9.sp,
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.6, 1.6),
                              duration: 1500.ms,
                              curve: Curves.easeInOut,
                            )
                            .fade(
                              begin: .3,
                              end: .8,
                              duration: 1500.ms,
                            ),
                      ),
                    ],
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
                .fade(
                  begin: maxOpacity,
                  end: 0,
                  duration: duration.ms,
                ),
          );
        }),
      ),
    );
  }
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

class _FloatingClouds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // سحابة 1
          Positioned(
            top: 140.h,
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
          // سحابة 2
          Positioned(
            top: 600.h,
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
          // سحابة 3
          Positioned(
            top: 900.h,
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
  final double animationValue; // 0..1 — بيدور 360° كل دورة
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
          Color(0xffA8E8F9), // sky
          Color(0xffFFD35B), // yellow
          Color(0xffF5A201), // orange
          Color(0xffB388FF), // purple
          Color(0xffA8E8F9), // sky
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

/// المسار (Levels Path) — أرقام ScreenUtil (.w / .h / .r / .sp) مع
/// Clamp حماية عشان الواجهة تتكيف مع أي حجم شاشة موبايل من غير ما
/// تنكسر أو تتراكب العناصر فوق بعضها.
class _LevelsPath extends StatelessWidget {
  final List<LevelPathData> levels;
  final AnimationController flowController;
  final String userName;
  final int xp;
  final int streakDays;
  final int level;
  final double levelProgress;

  const _LevelsPath({
    required this.levels,
    required this.flowController,
    required this.userName,
    required this.xp,
    required this.streakDays,
    required this.level,
    required this.levelProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return const SizedBox.shrink();
    }

    final double nodeSpacing = 165.h;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final totalHeight = levels.length * nodeSpacing + 80.h;

        final double edgeFraction = (60.w / width).clamp(0.10, 0.22);
        final double minFraction = edgeFraction;
        final double maxFraction = 1 - edgeFraction;

        final points = List.generate(levels.length, (i) {
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
                    painter: _PathPainter(
                      points: points,
                      levels: levels,
                      flowValue: flowController.value,
                    ),
                  ),
                ),
              ),
              ...List.generate(levels.length, (i) {
                final level = levels[i];
                final point = points[i];

                return Positioned(
                  left: 0,
                  right: 0,
                  top: point.dy - 60.h,
                  child: _LevelRow(
                    level: level,
                    nodeDx: point.dx,
                    containerWidth: width,
                    index: i,
                    userName: userName,
                    xp: xp,
                    streakDays: streakDays,
                    levelNum: level,
                    levelProgress: levelProgress,
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

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  final List<LevelPathData> levels;
  final double flowValue;

  _PathPainter({
    required this.points,
    required this.levels,
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
      segmentPath.cubicTo(
        cp1.dx, cp1.dy,
        cp2.dx, cp2.dy,
        p1.dx, p1.dy,
      );

      final bounds = Rect.fromPoints(p0, p1).inflate(40);

      final isLocked = levels[i].status == LevelStatus.locked ||
          levels[i + 1].status == LevelStatus.locked;

      if (isLocked) {
        _drawLockedSegment(canvas, segmentPath);
      } else {
        _drawActiveSegment(canvas, segmentPath, bounds, segmentIndex: i);
      }
    }
  }

  void _drawActiveSegment(
    Canvas canvas,
    Path path,
    Rect bounds, {
    required int segmentIndex,
  }) {
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
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.flowValue != flowValue || oldDelegate.points != points;
}

class _LevelRow extends StatelessWidget {
  final LevelPathData level;
  final double nodeDx;
  final double containerWidth;
  final int index;
  final String userName;
  final int xp;
  final int streakDays;
  final LevelPathData levelNum;
  final double levelProgress;

  const _LevelRow({
    required this.level,
    required this.nodeDx,
    required this.containerWidth,
    required this.index,
    required this.userName,
    required this.xp,
    required this.streakDays,
    required this.levelNum,
    required this.levelProgress,
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
      height: 165.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (level.status == LevelStatus.current)
            Positioned(
              left: (nodeDx - 35.w).clamp(0.0, containerWidth - 70.w),
              top: -2.h,
              child: const _CurrentRibbon(),
            ),
          Positioned(
            left: nodeDx - 40.w,
            top: 24.h,
            child: _LevelNode(
              level: level,
              index: index,
              userName: userName,
              xp: xp,
              streakDays: streakDays,
              levelNum: levelNum,
              levelProgress: levelProgress,
            ),
          ),
          Positioned(
            left: clampedLeft,
            top: 28.h,
            child: _LevelInfoCard(
              level: level,
              width: cardWidth,
              userName: userName,
              xp: xp,
              streakDays: streakDays,
              levelNum: levelNum,
              levelProgress: levelProgress,
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
        .shimmer(
          duration: 1800.ms,
          color: Colors.white.withOpacity(.6),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1400.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _LevelNode extends StatelessWidget {
  final LevelPathData level;
  final int index;
  final String userName;
  final int xp;
  final int streakDays;
  final LevelPathData levelNum;
  final double levelProgress;

  const _LevelNode({
    required this.level,
    required this.index,
    required this.userName,
    required this.xp,
    required this.streakDays,
    required this.levelNum,
    required this.levelProgress,
  });

  void _handleTap(BuildContext context) {
  final isLocked = level.status == LevelStatus.locked;
  final isAvailable = level.status == LevelStatus.available;

  if (isLocked) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8.w),
            const Expanded(
              child: Text("Finish the previous level to unlock this one! 💪"),
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

  if (isAvailable) {
    HapticFeedback.lightImpact();
    _showPurchaseSheet(context);   
    return;
  }

  if (level.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("خطأ: معرف المستوى غير موجود")),
    );
    return;
  }

  HapticFeedback.lightImpact();
  Navigator.pushNamed(
    context,
    levelCoursesRoute,
    arguments: {
      'levelId': level.id,                    
      'userName': userName,
      'xp': xp,
      'streakDays': streakDays,
      'level': level.order ?? level.id ?? 1,  
      'levelProgress': levelProgress,
      'levelTitle': level.title,
      'levelSubtitle': level.subtitle,
    },
  );
}


  void _showPurchaseSheet(BuildContext context) {
    final sheetColors = level.colors ?? [AppColors.sky, AppColors.primary];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.dark.withOpacity(.9),
              border: Border.all(color: Colors.white.withOpacity(.15)),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.3),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.lock_open_rounded,
                        color: sheetColors.first, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        level.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  level.subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.7),
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 18.h),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: sheetColors),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: sheetColors.first.withOpacity(.5),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Unlock for \$${level.price?.toStringAsFixed(0) ?? '-'}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = level.status == LevelStatus.current;
    final isLocked = level.status == LevelStatus.locked;
    final isBoss = level.status == LevelStatus.boss;
    final isCompleted = level.status == LevelStatus.completed;
    final isAvailable = level.status == LevelStatus.available;

    final double size =
        (isBoss ? 82.w : (isCurrent ? 80.w : 72.w)).clamp(58.0, 92.0);

    List<Color> gradientColors;
    if (isLocked) {
      gradientColors = [
        Colors.white.withOpacity(.12),
        Colors.white.withOpacity(.04)
      ];
    } else if (isBoss) {
      gradientColors = [const Color(0xffFF6FB5), const Color(0xffB861F5)];
    } else if (isCurrent) {
      gradientColors = [AppColors.orange, AppColors.yellow];
    } else if (isAvailable) {
      // ✅ كل مستوى متاح للشراء ياخد لونه الخاص (أزرق/موف/فيروزي/وردي..)
      gradientColors = level.colors ?? [AppColors.sky, AppColors.primary];
    } else {
      // completed
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

    Widget bossCrown = const SizedBox.shrink();
    if (isBoss) {
      bossCrown = Positioned(
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
              : Icon(level.icon,
                  color: Colors.white,
                  size: isBoss ? 34.sp : (isCurrent ? 32.sp : 28.sp)),
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
              child: Icon(Icons.check_rounded, size: 12.sp, color: Colors.white),
            ),
          ),
        ],
      );
    }

    if (isAvailable && level.price != null) {
      final badgeColors = level.colors ?? [AppColors.sky, AppColors.primary];
      node = Stack(
        clipBehavior: Clip.none,
        children: [
          node,
          Positioned(
            bottom: -2.h,
            right: -2.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: badgeColors),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.dark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: badgeColors.first.withOpacity(.6),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_open_rounded,
                      size: 9.sp, color: Colors.white),
                  SizedBox(width: 2.w),
                  Text(
                    "\$${level.price!.toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (isCurrent || isBoss) {
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
            if (isBoss) bossCrown else const SizedBox.shrink(),
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

class _LevelInfoCard extends StatelessWidget {
  final LevelPathData level;
  final double width;
  final String userName;
  final int xp;
  final int streakDays;
  final LevelPathData levelNum;
  final double levelProgress;

  const _LevelInfoCard({
    required this.level,
    required this.width,
    required this.userName,
    required this.xp,
    required this.streakDays,
    required this.levelNum,
    required this.levelProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = level.status == LevelStatus.current;
    final isLocked = level.status == LevelStatus.locked;
    final isBoss = level.status == LevelStatus.boss;
    final isCompleted = level.status == LevelStatus.completed;
    final isAvailable = level.status == LevelStatus.available;

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
    } else if (isBoss) {
      statusColor = const Color(0xFFFF6FB5);
      statusText = "Conquered";
      statusIcon = Icons.emoji_events_rounded;
    } else if (isAvailable) {
      statusColor = level.colors?.first ?? AppColors.sky;
      statusText = level.price != null
          ? "Available – \$${level.price!.toStringAsFixed(0)}"
          : "Available";
      statusIcon = Icons.lock_open_rounded;
    } else {
      statusColor = AppColors.yellow;
      statusText = "Current";
      statusIcon = Icons.play_circle_fill_rounded;
    }

    return SizedBox(
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
                    : isBoss
                        ? [
                            const Color(0xffB861F5).withOpacity(.22),
                            const Color(0xffFF6FB5).withOpacity(.12),
                          ]
                        : isAvailable
                            ? [
                                (level.colors?[0] ?? AppColors.sky)
                                    .withOpacity(.18),
                                (level.colors?[1] ?? AppColors.primary)
                                    .withOpacity(.12),
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
                    : isBoss
                        ? const Color(0xffFF6FB5).withOpacity(.5)
                        : isAvailable
                            ? (level.colors?.first ?? AppColors.sky)
                                .withOpacity(.5)
                            : Colors.white.withOpacity(.15),
                width: isCurrent || isBoss || isAvailable ? 1.5 : 1,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.yellow.withOpacity(.4),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : isBoss
                      ? [
                          BoxShadow(
                            color: const Color(0xffB861F5).withOpacity(.4),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ]
                      : isAvailable
                          ? [
                              BoxShadow(
                                color: (level.colors?.first ?? AppColors.sky)
                                    .withOpacity(.35),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBoss)
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xffFF6FB5), Color(0xffFFD35B)],
                    ).createShader(bounds),
                    child: Text(
                      "🔥 Boss Level",
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
                    level.title,
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
                  level.subtitle,
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
                  ],
                ),
                if (isCurrent) ...[
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pushNamed(
                        context,
                        levelCoursesRoute,
                        arguments: {
                          'userName': userName,
                          'xp': xp,
                          'streakDays': streakDays,
                          'level': level.order ?? 8,
                          'levelProgress': levelProgress,
                          'levelTitle': level.title,
                          'levelSubtitle': level.subtitle,
                          'levelId': level.id,
                        },
                      );
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
    )
        .animate()
        .fadeIn(delay: 250.ms, duration: 500.ms)
        .moveX(begin: 15, end: 0, curve: Curves.easeOutCubic);
  }
}

