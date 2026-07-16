import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/auth/logout/logout_cubit.dart';
import 'package:fluent/cubit/auth/logout/logout_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================
/// MODELS
/// ============================================================

enum ProgressPeriod { daily, weekly, monthly }

class _ChartData {
  final List<String> labels;
  final List<double> values;
  final double maxValue;
  final String totalLabel;

  const _ChartData({
    required this.labels,
    required this.values,
    required this.maxValue,
    required this.totalLabel,
  });

  double get total => values.fold(0, (a, b) => a + b);
  double get average => values.isEmpty ? 0 : total / values.length;
}

/// ============================================================
/// PROFILE SCREEN
/// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ✅ TODO: هاي بيانات وهمية بس للعرض — اربطيها مع الـ AuthCubit / UserCubit
  String _name = "Rasha Ahmad";
  String _email = "rasha.ahmad@example.com";
  String _phone = "+970 59 123 4567";
  String? _avatarUrl;
  final int _level = 8;
  final int _streakDays = 15;
  final int _xpPoints = 2480;
  final int _nextLevelXp = 3000;

  ProgressPeriod _selectedPeriod = ProgressPeriod.weekly;

  late final Map<ProgressPeriod, _ChartData> _progressData = {
    ProgressPeriod.daily: const _ChartData(
      labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      values: [3, 5, 2, 6, 4, 7, 5],
      maxValue: 8,
      totalLabel: "lessons this week",
    ),
    ProgressPeriod.weekly: const _ChartData(
      labels: ["W1", "W2", "W3", "W4"],
      values: [18, 22, 15, 26],
      maxValue: 30,
      totalLabel: "lessons this month",
    ),
    ProgressPeriod.monthly: const _ChartData(
      labels: ["Feb", "Mar", "Apr", "May", "Jun", "Jul"],
      values: [40, 55, 38, 60, 72, 65],
      maxValue: 80,
      totalLabel: "lessons this year",
    ),
  };

  @override
  void initState() {
    super.initState();
    // ✅ الـ LogoutCubit عام (Provided) على مستوى التطبيق كامل، فمنصفّر حالته
    // كل ما تفتح هالشاشة حتى ما يضل في أثر لعملية logout سابقة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LogoutCubit>().reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _progressData[_selectedPeriod]!;

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: BlocListener<LogoutCubit, LogoutState>(
        listener: (context, state) {
          if (state is LogoutSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message.isNotEmpty
                      ? state.message
                      : "Logged out successfully",
                  style: GoogleFonts.poppins(fontSize: 13.sp),
                ),
                backgroundColor: AppColors.sky,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );

            // ✅ نفس منطق التوجيه المستخدم بعد اللوجن، بس بالاتجاه المعاكس:
            // نمسح الـ stack بالكامل ونرجّع المستخدم لصفحة تسجيل الدخول
            // حتى ما يقدر يرجع بزر الـ back لصفحات محمية بعد ما سجل خروج.
            Navigator.pushNamedAndRemoveUntil(
              context,
              loginRoute,
              (route) => false,
            );
          } else if (state is LogoutFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.error.isNotEmpty
                      ? state.error
                      : "Failed to log out. Please try again.",
                  style: GoogleFonts.poppins(fontSize: 13.sp),
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
        },
        child: Stack(
          children: [
            _buildBackground(),
            _TwinklingStars(count: 32),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        _buildTopBar(),
                        SizedBox(height: 24.h),
                        _buildHeroProfile(),
                        SizedBox(height: 22.h),
                        _buildStatsRow(),
                        SizedBox(height: 26.h),
                        _buildSectionHeader(
                          title: "Account",
                          icon: Icons.person_rounded,
                          color: AppColors.sky,
                        ),
                        SizedBox(height: 12.h),
                        _buildAccountInfoCard(),
                        SizedBox(height: 14.h),
                        _buildSecurityCard(),
                        SizedBox(height: 14.h),
                        _buildPreferencesCard(),
                        SizedBox(height: 26.h),
                        _buildSectionHeader(
                          title: "Activity",
                          icon: Icons.insights_rounded,
                          color: AppColors.yellow,
                        ),
                        SizedBox(height: 12.h),
                        _buildProgressCard(data),
                        SizedBox(height: 26.h),
                        _buildLogoutButton(),
                        SizedBox(height: 16.h),
                        _buildFooter(),
                        SizedBox(height: 24.h),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BACKGROUND
  // ============================================================
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
          top: 500.h,
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
          top: 950.h,
          right: -60.w,
          child: _glowCircle(const Color(0xffB861F5), 220.w, 140, 25)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-10, -8),
                duration: 7000.ms,
                curve: Curves.easeInOut,
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

  // ============================================================
  // TOP BAR
  // ============================================================
  Widget _buildTopBar() {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "My Profile",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  width: 22.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.yellow],
                    ),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ],
            ),
          ),
        ),
        _circleIconButton(
          icon: Icons.settings_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            // TODO: إعدادات
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(.14),
              Colors.white.withOpacity(.04),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }

  // ============================================================
  // HERO PROFILE — نسخة احترافية مطوّرة
  // ============================================================
  Widget _buildHeroProfile() {
    final xpProgress = (_xpPoints / _nextLevelXp).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 24.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(.10),
            Colors.white.withOpacity(.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ---- الأفاتار مع حلقة متدرّجة + مؤشر المستوى ----
          SizedBox(
            width: 130.w,
            height: 130.w,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // هالة خارجية ناعمة
                Container(
                  width: 130.w,
                  height: 130.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.yellow.withOpacity(.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // الحلقة المتدرّجة (تدور)
                SizedBox(
                  width: 122.w,
                  height: 122.w,
                  child:
                      CustomPaint(
                            painter: _GradientRingPainter(
                              progress: xpProgress,
                              colors: const [
                                AppColors.yellow,
                                AppColors.orange,
                                AppColors.sky,
                                AppColors.yellow,
                              ],
                              strokeWidth: 3.5,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .rotate(duration: 14.seconds, curve: Curves.linear),
                ),
                // الأفاتار الفعلي
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sky.withOpacity(.25),
                    image: _avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _avatarUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 48.sp,
                        )
                      : null,
                ),
                // شارة المستوى
                Positioned(
                  bottom: 4.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orange, AppColors.yellow],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.dark, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.black,
                          size: 12.sp,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          "LV $_level",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // زر الكاميرا
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showAvatarOptionsSheet();
                    },
                    child: Container(
                      padding: EdgeInsets.all(7.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sky,
                        border: Border.all(color: AppColors.dark, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.sky.withOpacity(.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 13.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // ---- الاسم + بادج "Pro" ----
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffB388FF), Color(0xff7C4DFF)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 11.sp,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      "PRO",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          // ---- الإيميل ----
          Text(
            _email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.55),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 18.h),

          // ---- شريط XP ----
          Container(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.06),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(.08)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: AppColors.yellow,
                          size: 14.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          "Experience",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.7),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "$_xpPoints / $_nextLevelXp XP",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Stack(
                  children: [
                    Container(
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: xpProgress,
                      child: Container(
                        height: 6.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.orange, AppColors.yellow],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellow.withOpacity(.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  "${(_nextLevelXp - _xpPoints)} XP to Level ${_level + 1}",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.5),
                    fontSize: 9.5.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).moveY(begin: 12, end: 0);
  }

  // ============================================================
  // STATS ROW (تحت الهيرو)
  // ============================================================
  Widget _buildStatsRow() {
    final stats = [
      _StatItem(
        icon: Icons.local_fire_department_rounded,
        value: "$_streakDays",
        label: "Day Streak",
        gradient: const [AppColors.orange, Color(0xFFFF6B35)],
      ),
      _StatItem(
        icon: Icons.emoji_events_rounded,
        value: "12",
        label: "Achievements",
        gradient: const [AppColors.yellow, Color(0xFFFFC107)],
      ),
      _StatItem(
        icon: Icons.menu_book_rounded,
        value: "84",
        label: "Lessons",
        gradient: const [AppColors.sky, Color(0xff4FC3F7)],
      ),
      _StatItem(
        icon: Icons.timer_rounded,
        value: "47h",
        label: "Study Time",
        gradient: const [Color(0xffB388FF), Color(0xff7C4DFF)],
      ),
    ];

    return Row(
      children: List.generate(stats.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == stats.length - 1 ? 0 : 10.w),
            child: _statCard(stats[i])
                .animate(delay: (120 * i).ms)
                .fadeIn(duration: 500.ms)
                .moveY(begin: 16, end: 0),
          ),
        );
      }),
    );
  }

  Widget _statCard(_StatItem stat) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
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
        border: Border.all(color: Colors.white.withOpacity(.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: stat.gradient,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: stat.gradient.first.withOpacity(.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(stat.icon, color: Colors.white, size: 16.sp),
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.value,
              maxLines: 1,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.55),
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: color.withOpacity(.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 14.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(.15),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACCOUNT INFO CARD — نسخة احترافية
  // ============================================================
  Widget _buildAccountInfoCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(.10),
            Colors.white.withOpacity(.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoTile(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.sky,
            label: "Full Name",
            value: _name,
            onTap: () => _showEditProfileSheet(),
          ),
          _tileDivider(),
          _infoTile(
            icon: Icons.alternate_email_rounded,
            iconColor: AppColors.yellow,
            label: "Email Address",
            value: _email,
            onTap: () => _showEditProfileSheet(),
          ),
          _tileDivider(),
          _infoTile(
            icon: Icons.phone_iphone_rounded,
            iconColor: const Color(0xffB388FF),
            label: "Phone Number",
            value: _phone,
            isLast: true,
            onTap: () => _showEditProfileSheet(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).moveY(begin: 12, end: 0);
  }

  Widget _tileDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0),
              Colors.white.withOpacity(.10),
              Colors.white.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(isLast ? 22.r : 0),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(.25),
                      iconColor.withOpacity(.08),
                    ],
                  ),
                  border: Border.all(color: iconColor.withOpacity(.30)),
                ),
                child: Icon(icon, color: iconColor, size: 18.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.55),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.06),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(.5),
                  size: 16.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECURITY CARD — مع خيارات إضافية
  // ============================================================
  Widget _buildSecurityCard() {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.10),
                Colors.white.withOpacity(.04),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _securityTile(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.sky,
                title: "Password",
                subtitle: "Last changed 30 days ago",
                trailing: "Update",
                onTap: _showChangePasswordSheet,
              ),
              _tileDivider(),
              _securityTile(
                icon: Icons.fingerprint_rounded,
                iconColor: AppColors.yellow,
                title: "Biometric Login",
                subtitle: "Use fingerprint to sign in",
                trailing: "Off",
                isSwitch: true,
                switchValue: false,
                onTap: () {},
              ),
              _tileDivider(),
              _securityTile(
                icon: Icons.devices_rounded,
                iconColor: const Color(0xffB388FF),
                title: "Active Sessions",
                subtitle: "2 devices logged in",
                isLast: true,
                onTap: () {},
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 100.ms, duration: 500.ms)
        .moveY(begin: 12, end: 0);
  }

  Widget _securityTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailing,
    bool isSwitch = false,
    bool switchValue = false,
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSwitch
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        borderRadius: BorderRadius.circular(isLast ? 22.r : 0),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(.25),
                      iconColor.withOpacity(.08),
                    ],
                  ),
                  border: Border.all(color: iconColor.withOpacity(.30)),
                ),
                child: Icon(icon, color: iconColor, size: 18.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.55),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSwitch)
                _miniSwitch(value: switchValue, onChanged: (_) => onTap())
              else if (trailing != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(.15),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: iconColor.withOpacity(.30)),
                  ),
                  child: Text(
                    trailing,
                    style: GoogleFonts.poppins(
                      color: iconColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(.5),
                  size: 18.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: 200.ms,
        width: 38.w,
        height: 22.h,
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: value
              ? const LinearGradient(
                  colors: [AppColors.orange, AppColors.yellow],
                )
              : null,
          color: value ? null : Colors.white.withOpacity(.10),
        ),
        child: AnimatedAlign(
          duration: 200.ms,
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.black : Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PREFERENCES CARD
  // ============================================================
  Widget _buildPreferencesCard() {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.10),
                Colors.white.withOpacity(.04),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.12)),
          ),
          child: Column(
            children: [
              _securityTile(
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.orange,
                title: "Notifications",
                subtitle: "Daily reminders & updates",
                isSwitch: true,
                switchValue: true,
                onTap: () {},
              ),
              _tileDivider(),
              _securityTile(
                icon: Icons.language_rounded,
                iconColor: AppColors.sky,
                title: "Language",
                subtitle: "English (US)",
                trailing: "Change",
                onTap: () {},
              ),
              _tileDivider(),
              _securityTile(
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xffB388FF),
                title: "Appearance",
                subtitle: "Dark mode",
                isLast: true,
                isSwitch: true,
                switchValue: true,
                onTap: () {},
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 150.ms, duration: 500.ms)
        .moveY(begin: 12, end: 0);
  }

  // ============================================================
  // PROGRESS CARD (Chart)
  // ============================================================
  Widget _buildProgressCard(_ChartData data) {
    return Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.10),
                Colors.white.withOpacity(.04),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _periodTabs(),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      icon: Icons.menu_book_rounded,
                      value: data.total.toStringAsFixed(0),
                      label: data.totalLabel,
                      color: AppColors.sky,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _miniStat(
                      icon: Icons.trending_up_rounded,
                      value: data.average.toStringAsFixed(1),
                      label: "average",
                      color: AppColors.yellow,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _miniStat(
                      icon: Icons.local_fire_department_rounded,
                      value: "$_streakDays",
                      label: "day streak",
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              _BarChart(key: ValueKey(_selectedPeriod), data: data),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .moveY(begin: 12, end: 0);
  }

  Widget _miniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(.18), color.withOpacity(.05)],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(height: 5.h),
          FittedBox(
            fit: BoxFit.scaleDown,
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
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.60),
              fontSize: 8.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodTabs() {
    final tabs = [
      (ProgressPeriod.daily, "Daily"),
      (ProgressPeriod.weekly, "Weekly"),
      (ProgressPeriod.monthly, "Monthly"),
    ];

    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(
        children: tabs.map((t) {
          final selected = _selectedPeriod == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPeriod = t.$1);
              },
              child: AnimatedContainer(
                duration: 250.ms,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [AppColors.orange, AppColors.yellow],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(11.r),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.yellow.withOpacity(.4),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  t.$2,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    color: selected
                        ? Colors.black
                        : Colors.white.withOpacity(.65),
                    fontSize: 11.5.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Widget _buildLogoutButton() {
    return BlocBuilder<LogoutCubit, LogoutState>(
      builder: (context, state) {
        final isLoading = state is LogoutLoading;

        return GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _showLogoutConfirmDialog();
                    },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.redAccent.withOpacity(isLoading ? .10 : .18),
                      Colors.redAccent.withOpacity(isLoading ? .06 : .10),
                    ],
                  ),
                  border: Border.all(color: Colors.redAccent.withOpacity(.40)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: const CircularProgressIndicator(
                          color: Colors.redAccent,
                          strokeWidth: 2.2,
                        ),
                      )
                    else
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 18.sp,
                      ),
                    SizedBox(width: 10.w),
                    Text(
                      isLoading ? "Logging Out..." : "Log Out",
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 250.ms, duration: 500.ms)
            .moveY(begin: 12, end: 0);
      },
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 1.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(.15),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Fluent",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.4),
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            "Version 1.0.0",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.25),
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRADIENT RING PAINTER (للأفاتار)
  // ============================================================

  // ============================================================
  // BOTTOM SHEETS & DIALOGS
  // ============================================================

  void _showAvatarOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BottomSheetShell(
          title: "Profile Photo",
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetOptionTile(
                icon: Icons.photo_camera_rounded,
                label: "Take a Photo",
                color: AppColors.sky,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 10.h),
              _sheetOptionTile(
                icon: Icons.photo_library_rounded,
                label: "Choose from Gallery",
                color: AppColors.yellow,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              if (_avatarUrl != null) ...[
                SizedBox(height: 10.h),
                _sheetOptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: "Remove Photo",
                  color: Colors.redAccent,
                  onTap: () {
                    setState(() => _avatarUrl = null);
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sheetOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withOpacity(.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withOpacity(.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _BottomSheetShell(
            title: "Edit Profile",
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sheetTextField(
                    controller: nameCtrl,
                    label: "Full Name",
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.sky,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Please enter your name"
                        : null,
                  ),
                  SizedBox(height: 14.h),
                  _sheetTextField(
                    controller: emailCtrl,
                    label: "Email Address",
                    icon: Icons.alternate_email_rounded,
                    iconColor: AppColors.yellow,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Please enter your email";
                      }
                      final regex = RegExp(
                        r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$',
                      );
                      if (!regex.hasMatch(v.trim()))
                        return "Enter a valid email";
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),
                  _sheetTextField(
                    controller: phoneCtrl,
                    label: "Phone Number",
                    icon: Icons.phone_iphone_rounded,
                    iconColor: const Color(0xffB388FF),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Please enter your phone number"
                        : null,
                  ),
                  SizedBox(height: 22.h),
                  _sheetSubmitButton(
                    label: "Save Changes",
                    onTap: () {
                      if (formKey.currentState?.validate() ?? false) {
                        setState(() {
                          _name = nameCtrl.text.trim();
                          _email = emailCtrl.text.trim();
                          _phone = phoneCtrl.text.trim();
                        });
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true, obscureNew = true, obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: _BottomSheetShell(
                title: "Change Password",
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _strengthIndicator(newCtrl),
                      SizedBox(height: 14.h),
                      _sheetTextField(
                        controller: currentCtrl,
                        label: "Current Password",
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.sky,
                        obscureText: obscureCurrent,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white54,
                            size: 18.sp,
                          ),
                          onPressed: () => setSheetState(
                            () => obscureCurrent = !obscureCurrent,
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Please enter your current password"
                            : null,
                      ),
                      SizedBox(height: 14.h),
                      _sheetTextField(
                        controller: newCtrl,
                        label: "New Password",
                        icon: Icons.lock_rounded,
                        iconColor: AppColors.yellow,
                        obscureText: obscureNew,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white54,
                            size: 18.sp,
                          ),
                          onPressed: () =>
                              setSheetState(() => obscureNew = !obscureNew),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Please enter a new password";
                          }
                          if (v.length < 8) return "At least 8 characters";
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),
                      _sheetTextField(
                        controller: confirmCtrl,
                        label: "Confirm New Password",
                        icon: Icons.lock_rounded,
                        iconColor: const Color(0xffB388FF),
                        obscureText: obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white54,
                            size: 18.sp,
                          ),
                          onPressed: () => setSheetState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Please confirm your password";
                          }
                          if (v != newCtrl.text)
                            return "Passwords do not match";
                          return null;
                        },
                      ),
                      SizedBox(height: 22.h),
                      _sheetSubmitButton(
                        label: "Update Password",
                        onTap: () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "Password updated successfully ✅",
                                ),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // مؤشر قوة كلمة المرور
  Widget _strengthIndicator(TextEditingController ctrl) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (context, value, _) {
        final strength = _passwordStrength(value.text);
        final labels = ["Weak", "Fair", "Good", "Strong"];
        final colors = [
          Colors.redAccent,
          Colors.orange,
          AppColors.yellow,
          Colors.greenAccent,
        ];
        final percent = (strength + 1) / 4;

        return Container(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.05),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Password Strength",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.6),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value.text.isEmpty ? "—" : labels[strength],
                    style: GoogleFonts.poppins(
                      color: value.text.isEmpty
                          ? Colors.white.withOpacity(.4)
                          : colors[strength],
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == 3 ? 0 : 4.w),
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.08),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: i <= strength ? 1 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors[strength], colors[strength]],
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  int _passwordStrength(String pwd) {
    if (pwd.isEmpty) return -1;
    int score = 0;
    if (pwd.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score++;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pwd)) score++;
    return (score - 1).clamp(0, 3);
  }

  Widget _sheetTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color? iconColor,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5.sp),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(.06),
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white.withOpacity(.55),
          fontSize: 12.sp,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.all(10.r),
          padding: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.sky).withOpacity(.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.sky, size: 16.sp),
        ),
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.sky, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 10.sp),
      ),
    );
  }

  Widget _sheetSubmitButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.orange, AppColors.yellow],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: AppColors.yellow.withOpacity(.5), blurRadius: 16),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 14.sp,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.all(22.w),
                decoration: BoxDecoration(
                  color: AppColors.dark.withOpacity(.85),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: Colors.white.withOpacity(.15)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.withOpacity(.25),
                            Colors.redAccent.withOpacity(.08),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(.30),
                        ),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 26.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      "Log Out?",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Are you sure you want to log out of your account?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.65),
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 13.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.08),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(.15),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              // ✅ نفس نمط التطبيق: نسكر الـ dialog الأول
                              // وبعدين ننادي الـ Cubit (متل حذف السؤال بالضبط)
                              context.read<LogoutCubit>().logout();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 13.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.redAccent, Color(0xFFFF6B6B)],
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Text(
                                "Log Out",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// MODELS صغيرة
// ============================================================
class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradient;
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });
}

// ============================================================
// Gradient Ring Painter — حلقة الأفاتار
// ============================================================
class _GradientRingPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double strokeWidth;

  _GradientRingPainter({
    required this.progress,
    required this.colors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // الخلفية
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withOpacity(.08);
    canvas.drawCircle(center, radius, bgPaint);

    // القوس المتدرّج (الجزء المتقدّم)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: colors,
      startAngle: 0,
      endAngle: 2 * math.pi,
    ).createShader(rect);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

/// ============================================================
/// SHARED BOTTOM SHEET SHELL
/// ============================================================
class _BottomSheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _BottomSheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: AppColors.dark.withOpacity(.92),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(.12)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.25),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 18.h),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// BAR CHART (Daily / Weekly / Monthly)
/// ============================================================
class _BarChart extends StatelessWidget {
  final _ChartData data;
  const _BarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double chartAreaHeight = 132.h;
    final double labelHeadroom = 26.h;
    final double usableBarHeight = chartAreaHeight - labelHeadroom;
    final double peakValue = data.values.reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: chartAreaHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Column(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(i == 0 ? .10 : .05),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 1.4,
                  color: Colors.white.withOpacity(.18),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(data.values.length, (i) {
                  final value = data.values[i];
                  final fraction = (value / data.maxValue).clamp(0.0, 1.0);
                  final barHeight = usableBarHeight * fraction;
                  final isPeak = value == peakValue;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            bottom: barHeight + 6.h,
                            child: Text(
                              value.toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                color: isPeak
                                    ? AppColors.yellow
                                    : Colors.white60,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isPeak)
                            Positioned(
                              bottom: barHeight + 22.h,
                              child: _peakBadge(),
                            ),
                          Container(
                                height: barHeight <= 0 ? 4 : barHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isPeak
                                        ? [AppColors.orange, AppColors.yellow]
                                        : [
                                            AppColors.primary,
                                            AppColors.sky.withOpacity(.9),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(8.r),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isPeak
                                                  ? AppColors.yellow
                                                  : AppColors.sky)
                                              .withOpacity(isPeak ? .55 : .25),
                                      blurRadius: isPeak ? 14 : 8,
                                      spreadRadius: isPeak ? 0.5 : 0,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8.r),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(.35),
                                        Colors.white.withOpacity(0),
                                      ],
                                      stops: const [0.0, 0.4],
                                    ),
                                  ),
                                ),
                              )
                              .animate(delay: (150 + i * 90).ms)
                              .scaleY(
                                begin: 0,
                                end: 1,
                                alignment: Alignment.bottomCenter,
                                duration: 650.ms,
                                curve: Curves.easeOutBack,
                              ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: List.generate(data.labels.length, (i) {
            final isPeak = data.values[i] == peakValue;
            return Expanded(
              child: Text(
                data.labels[i],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: isPeak
                      ? AppColors.yellow
                      : Colors.white.withOpacity(.6),
                  fontSize: 9.5.sp,
                  fontWeight: isPeak ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _peakBadge() {
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.yellow],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(.6),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: Colors.black, size: 9.sp),
                  SizedBox(width: 2.w),
                  Text(
                    "Best",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            ClipPath(
              clipper: _TriangleClipper(),
              child: Container(
                width: 8.w,
                height: 5.h,
                color: AppColors.yellow,
              ),
            ),
          ],
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -3, duration: 1000.ms, curve: Curves.easeInOut);
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 40});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(7);
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
