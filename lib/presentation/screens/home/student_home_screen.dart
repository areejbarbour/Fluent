import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

enum LevelStatus { completed, current, locked, boss }

class LevelPathData {
  final String title;
  final String subtitle;
  final LevelStatus status;
  final IconData icon;

  const LevelPathData({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
  });
}
class StudentHomeScreen extends StatefulWidget {
  final String userName;
  final int xp;
  final int streakDays;
  final int level;
  final double levelProgress; // 0.0 -> 1.0

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

  final List<LevelPathData> _levels = const [
    LevelPathData(
      title: "Level 8",
      subtitle: "Grammar Mastery",
      status: LevelStatus.current,
      icon: Icons.auto_awesome_rounded,
    ),
    LevelPathData(
      title: "Level 7",
      subtitle: "Daily Life",
      status: LevelStatus.completed,
      icon: Icons.diamond_rounded,
    ),
    LevelPathData(
      title: "Boss Level",
      subtitle: "Challenge Time!",
      status: LevelStatus.boss,
      icon: Icons.workspace_premium_rounded,
    ),
    LevelPathData(
      title: "Level 6",
      subtitle: "Travel & Places",
      status: LevelStatus.completed,
      icon: Icons.flight_takeoff_rounded,
    ),
    LevelPathData(
      title: "Level 5",
      subtitle: "Food & Drinks",
      status: LevelStatus.locked,
      icon: Icons.lock_rounded,
    ),
  ];

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
  }

  @override
  void dispose() {
    _pathFlowController.dispose();
    _borderFlowController.dispose();
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  SizedBox(height: 22.h),
                  _buildStatsRow(),
                  SizedBox(height: 20.h),
                  _buildDailyChallengeAndLeaders(),
                  SizedBox(height: 14.h),
                  _PathTransition(),
                  SizedBox(height: 6.h),
                  _LevelsPath(
                    levels: _levels,
                    flowController: _pathFlowController,
                  ),
                  SizedBox(height: 110.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ============================================================
  // BACKGROUND ATMOSPHERE
  // ============================================================
  Widget _buildBackground() {
    return Stack(
      children: [
        // ✅ تدرج غني متعدد الطبقات لإحساس عمق
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
        // ✅ دوائر ضوئية متحركة بأحجام وأماكن مختلفة
        Positioned(
          top: -120.h,
          right: -80.w,
          child: _glowCircle(AppColors.yellow, 300.w, 160, 40)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-15, 10),
                duration: 5500.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          top: 380.h,
          left: -100.w,
          child: _glowCircle(AppColors.sky, 260.w, 150, 30)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(20, 15),
                duration: 6500.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          top: 700.h,
          right: -60.w,
          child: _glowCircle(AppColors.orange, 220.w, 130, 25)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-10, -8),
                duration: 7000.ms,
                curve: Curves.easeInOut,
              ),
        ),
        // ✅ silhouettes جبال بالأسفل
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(double.infinity, 240.h),
            painter: _MountainsPainter(),
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
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // الإطار الدوّار
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
            // الصورة
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
            // التاج فوق الأفاتار
            Positioned(
              top: -10.h,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.yellow,
                size: 18.sp,
                shadows: [
                  Shadow(color: AppColors.orange, blurRadius: 10),
                  Shadow(color: AppColors.yellow.withOpacity(.6), blurRadius: 18),
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
                  Text(
                    "Good evening,",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.75),
                      fontSize: 13.sp,
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
        SizedBox(width: 10.w),
        _circleIconButton(icon: Icons.settings_rounded, onTap: () {}),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statPill(
            icon: Icons.star_rounded,
            iconColor: AppColors.yellow,
            label: "XP",
            value: _formatNumber(widget.xp),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _statPill(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.orange,
            label: "Streak",
            value: "${widget.streakDays}d",
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _levelPill(),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms).moveY(begin: 10, end: 0);
  }

  Widget _statPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
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
                  child: Text(
                    value,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
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
                        // ✅ تأثير لمعان متحرك على الـ progress bar
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
              Container(
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withOpacity(.25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withOpacity(.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.local_fire_department_rounded,
                    color: AppColors.orange, size: 14.sp),
              ),
              SizedBox(width: 6.w),
              Text(
                "Daily Challenge",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            "Complete 10 new words",
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
              // ✅ لمعة متحركة على الـ progress bar
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
                    Text(
                      "250 XP",
                      style: GoogleFonts.poppins(
                        color: AppColors.yellow,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
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
      padding: EdgeInsets.all(14.w),
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
          SizedBox(height: 10.h),
          ...List.generate(leaders.length, (i) {
            final (name, xp, color, rank) = leaders[i];
            return Padding(
              padding:
                  EdgeInsets.only(bottom: i == leaders.length - 1 ? 0 : 8.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22.w,
                    height: 22.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withOpacity(.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        rank,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              xp,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(.65),
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              "XP",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(.5),
                                fontSize: 8.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: .3,
      ),
    );
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
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedNavIndex = i);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: 250.ms,
                                curve: Curves.easeOut,
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // ✅ أيقونة مع badge اختياري (refresh على HOME)
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
                                    AnimatedDefaultTextStyle(
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
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      // ✅ نجمة زخرفية على اليمين
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
                      color: (i.isEven
                              ? AppColors.yellow
                              : Colors.white)
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
    // الجبال البعيدة
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

class _LevelsPath extends StatelessWidget {
  final List<LevelPathData> levels;
  final AnimationController flowController;

  const _LevelsPath({
    required this.levels,
    required this.flowController,
  });

  @override
  Widget build(BuildContext context) {
    const double nodeSpacing = 165;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final totalHeight = levels.length * nodeSpacing + 80;

        // ✅ توليد نقاط منحنى S-Curve عضوي
        final points = List.generate(levels.length, (i) {
          final xFraction = 0.5 + 0.30 * math.sin(i * 2.05 + 1.0);
          final dx = width * xFraction.clamp(0.12, 0.88);
          final dy = 40 + i * nodeSpacing;
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
                  top: point.dy - 60,
                  child: _LevelRow(
                    level: level,
                    nodeDx: point.dx,
                    containerWidth: width,
                    index: i,
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
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: gradientColors).createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      const spacing = 28.0;
      // ✅ الـ offset بيتحرك مع flowValue عشان يعطي إحساس تدفق
      final baseOffset = (flowValue * spacing) % spacing;
      double distance = baseOffset;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          // هالة حول الخرزة
          canvas.drawCircle(
            tangent.position,
            5,
            Paint()
              ..color = Colors.white.withOpacity(.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
          // الخرزة نفسها
          canvas.drawCircle(
            tangent.position,
            2.5,
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
      oldDelegate.flowValue != flowValue ||
      oldDelegate.points != points;
}
class _LevelRow extends StatelessWidget {
  final LevelPathData level;
  final double nodeDx;
  final double containerWidth;
  final int index;

  const _LevelRow({
    required this.level,
    required this.nodeDx,
    required this.containerWidth,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 158;
    const double nodeHalf = 39;
    const double gap = 12;
    const double edgePadding = 4;

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
      height: 165,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (level.status == LevelStatus.current)
            Positioned(
              left: nodeDx - 35,
              top: -2,
              child: const _CurrentRibbon(),
            ),

          // ✅ العقدة
          Positioned(
            left: nodeDx - 40,
            top: 24,
            child: _LevelNode(level: level, index: index),
          ),

          // ✅ بطاقة المعلومات
          Positioned(
            left: clampedLeft,
            top: 28,
            child: _LevelInfoCard(level: level, width: cardWidth),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.yellow],
        ),
        borderRadius: BorderRadius.circular(14),
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
          const Icon(Icons.flag_rounded, color: Colors.black, size: 11),
          const SizedBox(width: 3),
          Text(
            "Current",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 9.5,
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
  const _LevelNode({required this.level, required this.index});

  void _handleTap(BuildContext context) {
    final isLocked = level.status == LevelStatus.locked;

    if (isLocked) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8.w),
              const Expanded(
                child: Text(
                    "Finish the previous level to unlock this one! 💪"),
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
    } else {
      HapticFeedback.lightImpact();
      // TODO: Navigator.pushNamed(context, levelDetailsRoute, arguments: level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = level.status == LevelStatus.current;
    final isLocked = level.status == LevelStatus.locked;
    final isBoss = level.status == LevelStatus.boss;
    final isCompleted = level.status == LevelStatus.completed;

    final size = isBoss ? 82.0 : (isCurrent ? 80.0 : 72.0);

    List<Color> gradientColors;
    if (isLocked) {
      gradientColors = [Colors.white.withOpacity(.12), Colors.white.withOpacity(.04)];
    } else if (isBoss) {
      gradientColors = [const Color(0xffFF6FB5), const Color(0xffB861F5)];
    } else if (isCurrent) {
      gradientColors = [AppColors.orange, AppColors.yellow];
    } else {
      gradientColors = [AppColors.sky, AppColors.primary];
    }

    Widget aura = const SizedBox.shrink();
    if (isCurrent) {
      aura = Container(
        width: size + 30,
        height: size + 30,
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
        width: size + 18,
        height: size + 18,
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
        top: -8,
        child: Icon(
          Icons.workspace_premium_rounded,
          color: const Color(0xFFFFD35B),
          size: 18,
          shadows: [
            const Shadow(color: Color(0xffB861F5), blurRadius: 12),
            const Shadow(color: Color(0xffFF6FB5), blurRadius: 20),
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
      padding: const EdgeInsets.all(4),
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
              ? Icon(Icons.lock_rounded, color: Colors.white54, size: 28)
              : Icon(level.icon,
                  color: Colors.white, size: isBoss ? 34 : (isCurrent ? 32 : 28)),
        ),
      ),
    );

    if (isCompleted) {
      node = Stack(
        clipBehavior: Clip.none,
        children: [
          node,
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
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
              child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
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
        width: size + 30,
        height: size + 30,
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
        .scale(begin: const Offset(.7, .7), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }
}
class _LevelInfoCard extends StatelessWidget {
  final LevelPathData level;
  final double width;
  const _LevelInfoCard({required this.level, required this.width});

  @override
  Widget build(BuildContext context) {
    final isCurrent = level.status == LevelStatus.current;
    final isLocked = level.status == LevelStatus.locked;
    final isBoss = level.status == LevelStatus.boss;
    final isCompleted = level.status == LevelStatus.completed;

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
    } else {
      statusColor = AppColors.yellow;
      statusText = "Current";
      statusIcon = Icons.play_circle_fill_rounded;
    }

    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(12),
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
                        : [
                            Colors.white.withOpacity(.10),
                            Colors.white.withOpacity(.04),
                          ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent
                    ? AppColors.yellow.withOpacity(.6)
                    : isBoss
                        ? const Color(0xffFF6FB5).withOpacity(.5)
                        : Colors.white.withOpacity(.15),
                width: isCurrent || isBoss ? 1.5 : 1,
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
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: .3,
                      ),
                    ),
                  )
                else
                  Text(
                    level.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: .2,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  level.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.72),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // TODO: Navigator.pushNamed(context, levelDetailsRoute);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.orange, AppColors.yellow],
                        ),
                        borderRadius: BorderRadius.circular(20),
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
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.play_arrow_rounded,
                              color: Colors.black, size: 14),
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