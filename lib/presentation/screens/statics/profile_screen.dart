import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/auth/logout/logout_cubit.dart';
import 'package:fluent/cubit/auth/logout/logout_state.dart';
import 'package:fluent/cubit/auth/reset_password/reset_password_cubit.dart';
import 'package:fluent/cubit/auth/reset_password/reset_password_state.dart';
import 'package:fluent/cubit/auth/forgot_password/forgot_password_cubit.dart';
import 'package:fluent/cubit/auth/forgot_password/forgot_password_state.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_cubit.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_state.dart';
import 'package:fluent/cubit/profile/profile_cubit.dart';
import 'package:fluent/cubit/profile/profile_state.dart';
import 'package:fluent/data/models/profile_model.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// null = still loading; true = student has ≥1 exception request.
  bool? _hasLevelExceptions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LogoutCubit>().reset();
      context.read<ProfileCubit>().loadProfile();
      _loadHasLevelExceptions();
    });
  }

  Future<void> _loadHasLevelExceptions() async {
    try {
      final repo = context.read<LevelExceptionRepository>();
      const statuses = ['pending', 'in_review', 'approved', 'rejected'];
      final results = await Future.wait(
        statuses.map((s) => repo.getByStatus(s, page: 1)),
      );

      var has = false;
      for (final r in results) {
        if (r['success'] != true) continue;
        final total = r['total'];
        if (total is int && total > 0) {
          has = true;
          break;
        }
        final data = r['data'];
        if (data is List && data.isNotEmpty) {
          has = true;
          break;
        }
      }

      if (mounted) setState(() => _hasLevelExceptions = has);
    } catch (_) {
      if (mounted) setState(() => _hasLevelExceptions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: MultiBlocListener(
        listeners: [
          BlocListener<LogoutCubit, LogoutState>(
            listener: (context, state) {
              if (state is LogoutSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message.isNotEmpty
                          ? state.message
                          : 'Logged out successfully',
                      style: GoogleFonts.poppins(fontSize: 13.sp),
                    ),
                    backgroundColor: AppColors.sky,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
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
                          : 'Failed to log out. Please try again.',
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
          ),
          BlocListener<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileUpdateSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: GoogleFonts.poppins(fontSize: 13.sp),
                    ),
                    backgroundColor: Colors.greenAccent.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
              } else if (state is ProfileFailure && state.profile == null) {
                // Hard failure on first load — soft failures keep previous data
              } else if (state is ProfileFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
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
          ),
          // Success/error feedback for password change is shown inside
          // the Change Password sheet Scaffold so it stays visible there.
          BlocListener<ResetPasswordCubit, ResetPasswordState>(
            listener: (context, state) {
              if (state is ResetPasswordSuccess) {
                context.read<ResetPasswordCubit>().reset();
              }
            },
          ),
        ],
        child: Stack(
          children: [
            _buildBackground(),
            const _TwinklingStars(count: 32),
            SafeArea(
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  if (state is ProfileLoading || state is ProfileInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.yellow),
                    );
                  }

                  if (state is ProfileFailure && state.profile == null) {
                    return _buildErrorState(state.message);
                  }

                  final ProfileViewData profile;
                  final bool isUpdating;
                  if (state is ProfileLoaded) {
                    profile = state.profile;
                    isUpdating = false;
                  } else if (state is ProfileUpdating) {
                    profile = state.profile;
                    isUpdating = true;
                  } else if (state is ProfileUpdateSuccess) {
                    profile = state.profile;
                    isUpdating = false;
                  } else if (state is ProfileFailure && state.profile != null) {
                    profile = state.profile!;
                    isUpdating = false;
                  } else {
                    return const SizedBox.shrink();
                  }

                  return Stack(
                    children: [
                      CustomScrollView(
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
                                _buildHeroProfile(profile),
                                SizedBox(height: 22.h),
                                if (!profile.isTeacher) ...[
                                  // Student order:
                                  // stats → change password → exception (if any) → weekly chart
                                  _buildStudentStatsRow(profile),
                                  SizedBox(height: 16.h),
                                  _buildChangePasswordCard(profile),
                                  SizedBox(height: 14.h),
                                  if (_hasLevelExceptions == true) ...[
                                    _buildLevelExceptionsCard(),
                                    SizedBox(height: 14.h),
                                  ],
                                  _buildWeeklyActivityCard(profile),
                                  SizedBox(height: 14.h),
                                ] else ...[
                                  _buildTeacherBadgeRow(profile),
                                  SizedBox(height: 26.h),
                                  // Account box — teachers only
                                  _buildSectionHeader(
                                    title: 'Account',
                                    icon: Icons.person_rounded,
                                    color: AppColors.sky,
                                  ),
                                  SizedBox(height: 12.h),
                                  _buildAccountInfoCard(profile),
                                  SizedBox(height: 14.h),
                                  _buildChangePasswordCard(profile),
                                  SizedBox(height: 14.h),
                                ],
                                SizedBox(height: 12.h),
                                // Logout — same mechanism for student & teacher
                                _buildLogoutButton(),
                                SizedBox(height: 16.h),
                                _buildFooter(),
                                SizedBox(height: 24.h),
                              ]),
                            ),
                          ),
                        ],
                      ),
                      if (isUpdating)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black45,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.yellow,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0: // Home
        Navigator.pushNamedAndRemoveUntil(
          context,
          studentHomeRoute, // أو homeRoute حسب اسمك
          (route) => false,
        );
        break;
      case 1: // Word Bank
        Navigator.pushNamed(context, wordBankRoute);
        break;
      case 2: // Podcasts
        Navigator.pushNamed(context, podcastsRoute);
        break;
      case 3: // AI Conversation
        Navigator.pushNamed(context, aiConversationRoute);
        break;
      case 4: // Profile — already here
        break;
    }
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.sky, size: 42.sp),
            SizedBox(height: 14.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 18.h),
            GestureDetector(
              onTap: () => context.read<ProfileCubit>().loadProfile(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.yellow, AppColors.orange],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 28.h),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  // Widget _buildBackground() {
  //   return Container(
  //     decoration: const BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topCenter,
  //         end: Alignment.bottomCenter,
  //         colors: [
  //           Color(0xff020B18),
  //           Color(0xff072238),
  //           AppColors.primary,
  //           Color(0xff01344F),
  //           Color(0xff020B18),
  //         ],
  //         stops: [0.0, 0.22, 0.55, 0.8, 1.0],
  //       ),
  //     ),
  //   );
  // }

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
        // توهج أصفر فوق يمين (متل الهوم)
        Positioned(
          top: -100.h,
          right: -70.w,
          child: Container(
            width: 260.w,
            height: 260.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.yellow.withOpacity(0.10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.28),
                  blurRadius: 140,
                  spreadRadius: 35,
                ),
              ],
            ),
          ),
        ),
        // توهج سماوي وسط يسار
        Positioned(
          top: 320.h,
          left: -90.w,
          child: Container(
            width: 240.w,
            height: 240.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sky.withOpacity(0.12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sky.withOpacity(0.25),
                  blurRadius: 130,
                  spreadRadius: 30,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Text(
            'My Profile',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzelDecorative(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _circleIconButton(
          icon: Icons.edit_rounded,
          onTap: () {
            final state = context.read<ProfileCubit>().state;
            ProfileViewData? data;
            if (state is ProfileLoaded) data = state.profile;
            if (state is ProfileUpdateSuccess) data = state.profile;
            if (state is ProfileUpdating) data = state.profile;
            if (data != null) _showEditProfileSheet(data);
          },
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }

  Widget _buildHeroProfile(ProfileViewData profile) {
    final hasImage =
        profile.imageUrl != null && profile.imageUrl!.trim().isNotEmpty;
    final progress = profile.isTeacher
        ? 1.0
        : (profile.points <= 0 ? 0.15 : (profile.points % 1000) / 1000.0).clamp(
            0.12,
            1.0,
          );

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
          SizedBox(
            width: 130.w,
            height: 130.w,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
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
                SizedBox(
                  width: 122.w,
                  height: 122.w,
                  child:
                      CustomPaint(
                            painter: _GradientRingPainter(
                              progress: progress,
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
                GestureDetector(
                  onTap: () => _showEditProfileSheet(profile),
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.sky.withOpacity(0.45),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(0.25),
                          blurRadius: 18,
                        ),
                      ],
                      image: hasImage
                          ? DecorationImage(
                              image: NetworkImage(profile.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: hasImage ? null : AppColors.primary,
                    ),
                    child: hasImage
                        ? null
                        : Icon(
                            Icons.person_rounded,
                            color: Colors.white70,
                            size: 42.sp,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showEditProfileSheet(profile),
                    child: Container(
                      padding: EdgeInsets.all(7.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.yellow, AppColors.orange],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.yellow.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.dark,
                        size: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            profile.name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            profile.email,
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
          if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                profile.bio!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12.sp,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityCard(ProfileViewData profile) {
    final days = profile.weeklyActivity?.days ?? const <WeeklyActivityDay>[];
    final items = days.isEmpty
        ? List.generate(7, (i) {
            final now = DateTime.now();
            final sunday = now.subtract(Duration(days: now.weekday % 7));
            return WeeklyActivityDay(
              date: DateTime(sunday.year, sunday.month, sunday.day + i),
              completedLessons: 0,
            );
          })
        : days;

    final maxCount = items.fold<int>(
      1,
      (m, d) => d.completedLessons > m ? d.completedLessons : m,
    );
    final totalLessons = items.fold<int>(0, (s, d) => s + d.completedLessons);
    final activeDays = items.where((d) => d.isActive).length;

    // Attractive gradients per day (app palette + soft variants)
    const barGradients = <List<Color>>[
      [Color(0xFF7FDBF5), Color(0xFF2B9BC2)], // sky
      [Color(0xFFFFE08A), Color(0xFFF5A201)], // yellow-orange
      [Color(0xFFFFB347), Color(0xFFE67E22)], // orange
      [Color(0xFF6FE3C1), Color(0xFF1ABC9C)], // mint
      [Color(0xFFA8E8F9), Color(0xFF00537A)], // sky → primary
      [Color(0xFFFFD35B), Color(0xFFFF9F1C)], // gold
      [Color(0xFF9B8CFF), Color(0xFF6C5CE7)], // soft violet
    ];

    const weekdayFull = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.dark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sky.withOpacity(0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.sky,
                  size: 17.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Activity',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$totalLessons lessons · $activeDays active days',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 10.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Chart area — fixed height prevents bottom overflow
          SizedBox(
            height: 128.h,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final labelH = 18.h;
                final valueH = 16.h;
                final gapV = 4.h;
                final chartH =
                    constraints.maxHeight - labelH - valueH - gapV * 2;
                final n = items.length;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(n, (index) {
                    final day = items[index];
                    final count = day.completedLessons;
                    final ratio = (count / maxCount).clamp(0.0, 1.0);
                    // Real proportional height; empty days get a tiny base
                    final barH = count == 0
                        ? 8.h
                        : (8.h + (chartH - 8.h) * ratio);

                    final now = DateTime.now();
                    final isToday =
                        day.date.year == now.year &&
                        day.date.month == now.month &&
                        day.date.day == now.day;

                    final grads = barGradients[index % barGradients.length];
                    final topColor = grads[0];
                    final bottomColor = grads[1];

                    final weekdayName = weekdayFull[day.date.weekday % 7];
                    // DateTime.weekday: Mon=1..Sun=7 → map to our Sun-first labels
                    final fullName = switch (day.date.weekday) {
                      DateTime.sunday => 'Sunday',
                      DateTime.monday => 'Monday',
                      DateTime.tuesday => 'Tuesday',
                      DateTime.wednesday => 'Wednesday',
                      DateTime.thursday => 'Thursday',
                      DateTime.friday => 'Friday',
                      DateTime.saturday => 'Saturday',
                      _ => weekdayName,
                    };

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: GestureDetector(
                          onTap: () => _showDayActivitySheet(
                            context,
                            day: day,
                            dayName: fullName,
                            barColor: topColor,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Value
                              SizedBox(
                                height: valueH,
                                child: count > 0
                                    ? Text(
                                        '$count',
                                        style: GoogleFonts.poppins(
                                          color: topColor,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                          height: 1,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              SizedBox(height: gapV),
                              // Shiny bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                height: barH,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(10.r),
                                    bottom: Radius.circular(5.r),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: count > 0
                                        ? [
                                            topColor,
                                            bottomColor.withOpacity(0.85),
                                          ]
                                        : [
                                            Colors.white.withOpacity(0.14),
                                            Colors.white.withOpacity(0.05),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: isToday
                                        ? AppColors.yellow
                                        : Colors.white.withOpacity(
                                            count > 0 ? 0.22 : 0.08,
                                          ),
                                    width: isToday ? 1.6 : 0.8,
                                  ),
                                  boxShadow: count > 0
                                      ? [
                                          BoxShadow(
                                            color: topColor.withOpacity(0.45),
                                            blurRadius: 12,
                                            spreadRadius: -1,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: count > 0
                                    ? Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          margin: EdgeInsets.only(top: 3.h),
                                          height: (barH * 0.28).clamp(
                                            4.0,
                                            14.0,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.white.withOpacity(0.55),
                                                Colors.white.withOpacity(0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              SizedBox(height: gapV),
                              // Weekday
                              SizedBox(
                                height: labelH,
                                child: Text(
                                  day.shortLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5.sp,
                                    fontWeight: isToday
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isToday
                                        ? AppColors.yellow
                                        : Colors.white.withOpacity(0.62),
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          SizedBox(height: 6.h),
          Center(
            child: Text(
              'Tap a bar to see details',
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 9.5.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDayActivitySheet(
    BuildContext context, {
    required WeeklyActivityDay day,
    required String dayName,
    required Color barColor,
  }) {
    final dateStr =
        '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
    final count = day.completedLessons;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 22.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.dark.withOpacity(0.98),
                AppColors.primary.withOpacity(0.95),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(color: barColor.withOpacity(0.25), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      gradient: LinearGradient(
                        colors: [barColor, barColor.withOpacity(0.55)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      count > 0
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_empty_rounded,
                      color: AppColors.dark,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: barColor, size: 20.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        count > 0
                            ? 'Completed $count lesson${count == 1 ? '' : 's'} this day'
                            : 'No lessons completed this day',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (count > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: barColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: barColor.withOpacity(0.45)),
                        ),
                        child: Text(
                          '×$count',
                          style: GoogleFonts.poppins(
                            color: barColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentStatsRow(ProfileViewData profile) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.stars_rounded,
            value: '${profile.points}',
            label: 'XP Points',
            gradient: const [AppColors.yellow, AppColors.orange],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _statCard(
            icon: Icons.local_fire_department_rounded,
            value: '${profile.streak}',
            label: 'Day Streak',
            gradient: const [Color(0xFFFF6B6B), AppColors.orange],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherBadgeRow(ProfileViewData profile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          colors: [
            AppColors.sky.withOpacity(0.18),
            AppColors.primary.withOpacity(0.25),
          ],
        ),
        border: Border.all(color: AppColors.sky.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.sky.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.school_rounded,
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
                  'Teacher Account',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Manage courses, lessons & tests',
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(18.r),
      //   gradient: LinearGradient(
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //     colors: [
      //       Colors.white.withOpacity(0.10),
      //       Colors.white.withOpacity(0.04),
      //     ],
      //   ),
      //   border: Border.all(color: Colors.white.withOpacity(0.12)),
      // ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.dark, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Account card ───────────────────────────────────────────

  Widget _buildAccountInfoCard(ProfileViewData profile) {
    return Container(
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(22.r),
      //   color: Colors.white.withOpacity(0.06),
      //   border: Border.all(color: Colors.white.withOpacity(0.10)),
      // ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          _infoTile(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.sky,
            label: 'Full Name',
            value: profile.name,
            onTap: () => _showEditProfileSheet(profile),
          ),
          _tileDivider(),
          _infoTile(
            icon: Icons.alternate_email_rounded,
            iconColor: AppColors.yellow,
            label: 'Email',
            value: profile.email,
            onTap: () {},
          ),
          _tileDivider(),
          _infoTile(
            icon: Icons.notes_rounded,
            iconColor: const Color(0xffB388FF),
            label: 'Bio',
            value: (profile.bio == null || profile.bio!.trim().isEmpty)
                ? 'Add a short bio'
                : profile.bio!,
            onTap: () => _showEditProfileSheet(profile),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _tileDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.06),
      indent: 16.w,
      endIndent: 16.w,
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
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      value,
                      maxLines: 2,
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Change password (uses existing ResetPasswordCubit + API) ──

  Widget _buildChangePasswordCard(ProfileViewData profile) {
    return GestureDetector(
      onTap: () => _showChangePasswordSheet(profile),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.orange.withOpacity(0.35)),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                color: AppColors.orange,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Update your account password securely',
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordSheet(ProfileViewData profile) async {
    context.read<ResetPasswordCubit>().reset();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(email: profile.email),
    );
  }

  // ── Level exception (kept for student + teacher profiles) ──

  Widget _buildLevelExceptionsCard() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, levelExceptionsRoute),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: LinearGradient(
            colors: [
              AppColors.yellow.withOpacity(0.14),
              AppColors.orange.withOpacity(0.08),
            ],
          ),
          border: Border.all(color: AppColors.yellow.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.assignment_late_rounded,
                color: AppColors.yellow,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exception Request',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'View or manage level exception requests',
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout (same for student & teacher) ────────────────────

  Widget _buildLogoutButton() {
    return BlocBuilder<LogoutCubit, LogoutState>(
      builder: (context, state) {
        final isLoading = state is LogoutLoading;
        return GestureDetector(
          onTap: isLoading ? null : _showLogoutConfirmDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.redAccent.withOpacity(0.45)),
              color: Colors.redAccent.withOpacity(0.12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.redAccent,
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
                  isLoading ? 'Logging out...' : 'Log Out',
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Text(
      'Fluent · Learn with confidence',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(color: Colors.white30, fontSize: 11.sp),
    );
  }

  // ── Edit profile sheet (bio + image → backend) ─────────────

  Future<void> _showEditProfileSheet(ProfileViewData profile) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        profile: profile,
        onSave: (bio, imagePath) {
          context.read<ProfileCubit>().updateProfile(
            bio: bio,
            imagePath: imagePath,
          );
        },
      ),
    );
  }

  Widget _sheetTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
        decoration: InputDecoration(
          counterStyle: GoogleFonts.poppins(
            color: Colors.white38,
            fontSize: 10.sp,
          ),
          prefixIcon: Icon(icon, color: iconColor, size: 18.sp),
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12.sp,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _sheetSubmitButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.yellow, AppColors.orange],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withOpacity(0.35),
              blurRadius: 12,
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.dark,
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2A3A).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Log Out?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'You will need to sign in again to continue.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 13.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
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
                              Navigator.pop(ctx);
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
                                'Log Out',
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

class _ChangePasswordSheet extends StatefulWidget {
  final String email;
  const _ChangePasswordSheet({required this.email});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  int _step = 0;

  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a new password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (value.length > 50) return 'Password must be at most 50 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value)) {
      return 'Use upper and lower case letters';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Include at least one symbol';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  void _sendOtp() {
    final email = widget.email.trim();
    if (email.isEmpty || email == '—') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email not available. Please re-login.',
            style: GoogleFonts.poppins(fontSize: 13.sp),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<ForgotPasswordCubit>().forgotPassword(email: email);
  }

  void _verifyOtp() {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the OTP code',
            style: GoogleFonts.poppins(fontSize: 13.sp),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<VerifyOtpCubit>().verifyOtp(
      email: widget.email.trim(),
      otp: otp,
      type: OtpType.forgotPassword,
    );
  }

  void _submitPassword() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ResetPasswordCubit>().resetPassword(
      email: widget.email.trim(),
      password: _passwordCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
    );
  }

  Widget _stepIndicator() {
    Widget dot(int i, String label) {
      final active = _step == i;
      final done = _step > i;
      return Expanded(
        child: Column(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: (active || done)
                    ? const LinearGradient(
                        colors: [AppColors.yellow, AppColors.orange],
                      )
                    : null,
                color: (active || done) ? null : Colors.white12,
                border: Border.all(
                  color: (active || done) ? Colors.transparent : Colors.white24,
                ),
              ),
              child: done
                  ? Icon(
                      Icons.check_rounded,
                      size: 16.sp,
                      color: AppColors.dark,
                    )
                  : Text(
                      '${i + 1}',
                      style: GoogleFonts.poppins(
                        color: active ? AppColors.dark : Colors.white60,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: active ? Colors.white : Colors.white54,
                fontSize: 10.sp,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        dot(0, 'OTP'),
        Expanded(
          child: Container(
            height: 2,
            margin: EdgeInsets.only(bottom: 18.h),
            color: _step > 0 ? AppColors.orange : Colors.white12,
          ),
        ),
        dot(1, 'Verify'),
        Expanded(
          child: Container(
            height: 2,
            margin: EdgeInsets.only(bottom: 18.h),
            color: _step > 1 ? AppColors.orange : Colors.white12,
          ),
        ),
        dot(2, 'Password'),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onTap,
    required bool loading,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.yellow, AppColors.orange],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withOpacity(0.35),
              blurRadius: 12,
            ),
          ],
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.dark,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppColors.dark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12.sp,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: AppColors.orange,
            size: 18.sp,
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.white54,
              size: 18.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _step0SendOtp(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We will send a verification code to',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12.sp),
        ),
        SizedBox(height: 6.h),
        Text(
          widget.email,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'This protects your account before changing the password.',
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11.sp),
        ),
        SizedBox(height: 22.h),
        _primaryButton(label: 'Send OTP', onTap: _sendOtp, loading: loading),
      ],
    );
  }

  Widget _step1VerifyOtp(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the OTP sent to your email',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12.sp),
        ),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18.sp,
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white24,
                letterSpacing: 8,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: loading ? null : _sendOtp,
            child: Text(
              'Resend OTP',
              style: GoogleFonts.poppins(
                color: AppColors.yellow,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 18.h),
        _primaryButton(
          label: 'Verify OTP',
          onTap: _verifyOtp,
          loading: loading,
        ),
      ],
    );
  }

  Widget _step2NewPassword(bool loading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a strong new password',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12.sp),
          ),
          SizedBox(height: 14.h),
          _field(
            controller: _passwordCtrl,
            label: 'New Password',
            obscure: _obscurePass,
            onToggle: () => setState(() => _obscurePass = !_obscurePass),
            validator: _validatePassword,
          ),
          _field(
            controller: _confirmCtrl,
            label: 'Confirm Password',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            validator: _validateConfirm,
          ),
          Text(
            'Min 8 chars · upper & lower · number · symbol',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10.sp),
          ),
          SizedBox(height: 18.h),
          _primaryButton(
            label: 'Update Password',
            onTap: _submitPassword,
            loading: loading,
          ),
        ],
      ),
    );
  }

  void _showSheetSnack(
    BuildContext context, {
    required String message,
    required Color background,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: MultiBlocListener(
        listeners: [
          BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
            listener: (context, state) {
              if (state is ForgotPasswordSuccess) {
                setState(() => _step = 1);
                _showSheetSnack(
                  context,
                  message: state.message.isNotEmpty
                      ? state.message
                      : 'OTP sent to your email',
                  background: const Color(0xFF1B8A5A),
                );
              } else if (state is ForgotPasswordFailure) {
                _showSheetSnack(
                  context,
                  message: state.error,
                  background: Colors.redAccent,
                );
              }
            },
          ),
          BlocListener<VerifyOtpCubit, VerifyOtpState>(
            listener: (context, state) {
              if (state is VerifyOtpSuccess) {
                setState(() => _step = 2);
                _showSheetSnack(
                  context,
                  message: state.message.isNotEmpty
                      ? state.message
                      : 'OTP verified. Set your new password.',
                  background: const Color(0xFF1B8A5A),
                );
              } else if (state is VerifyOtpFailure) {
                _showSheetSnack(
                  context,
                  message: state.error,
                  background: Colors.redAccent,
                );
              }
            },
          ),
          BlocListener<ResetPasswordCubit, ResetPasswordState>(
            listener: (context, state) {
              if (state is ResetPasswordSuccess) {
                _showSheetSnack(
                  context,
                  message: state.message.isNotEmpty
                      ? state.message
                      : 'Password reset successfully',
                  background: const Color(0xFF1B8A5A),
                );
                Future.delayed(const Duration(milliseconds: 1400), () {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                });
              } else if (state is ResetPasswordFailure) {
                final details = state.errors;
                String msg = state.error;
                if (details != null && details.isNotEmpty) {
                  final first = details.values.first;
                  if (first is List && first.isNotEmpty) {
                    msg = first.first.toString();
                  } else if (first is String && first.isNotEmpty) {
                    msg = first;
                  }
                }
                _showSheetSnack(
                  context,
                  message: msg,
                  background: Colors.redAccent,
                );
              }
            },
          ),
        ],
        child: Padding(
          // Push sheet above keyboard without shrinking past content
          padding: EdgeInsets.only(bottom: bottomInset),
          child: DraggableScrollableSheet(
            expand: true,
            initialChildSize: bottomInset > 0 ? 0.78 : 0.58,
            minChildSize: 0.40,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              final forgotLoading =
                  context.watch<ForgotPasswordCubit>().state
                      is ForgotPasswordLoading;
              final otpLoading =
                  context.watch<VerifyOtpCubit>().state is VerifyOtpLoading;
              final resetLoading =
                  context.watch<ResetPasswordCubit>().state
                      is ResetPasswordLoading;

              return Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0B2A3A), Color(0xFF013C58)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                  border: Border.all(color: AppColors.sky.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Padding(
                      padding: EdgeInsets.only(top: 10.h, bottom: 6.h),
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    Text(
                      'Change Password',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          _stepIndicator(),
                          SizedBox(height: 14.h),
                          if (_step == 0) _step0SendOtp(forgotLoading),
                          if (_step == 1)
                            _step1VerifyOtp(otpLoading || forgotLoading),
                          if (_step == 2) _step2NewPassword(resetLoading),
                          SizedBox(height: 12.h),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final ProfileViewData profile;
  final void Function(String bio, String? imagePath) onSave;

  const _EditProfileSheet({required this.profile, required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _bioCtrl;
  String? _pickedImagePath;
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
    _previewUrl = widget.profile.imageUrl;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        setState(() {
          _pickedImagePath = result.files.first.path;
          _previewUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Widget _avatar() {
    final path = _pickedImagePath;
    final url = _previewUrl;
    Widget child;
    if (path != null) {
      child = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (url != null && url.isNotEmpty) {
      child = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      child = _placeholder();
    }
    return ClipOval(
      child: SizedBox(width: 96.w, height: 96.w, child: child),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primary,
      child: Icon(Icons.person_rounded, color: Colors.white70, size: 40.sp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final maxHeight = (media.size.height - media.viewInsets.bottom) * 0.92;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: Colors.transparent,
            child: _BottomSheetShell(
              title: 'Edit Profile',
              bottomPadding: bottomInset > 0 ? 12.h : 24.h,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: 8.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _avatar(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [AppColors.yellow, AppColors.orange],
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.dark,
                                size: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Tap to change photo',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: TextField(
                        controller: _bioCtrl,
                        maxLines: 4,
                        maxLength: 500,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13.sp,
                        ),
                        decoration: InputDecoration(
                          counterStyle: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 10.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.notes_rounded,
                            color: const Color(0xffB388FF),
                            size: 18.sp,
                          ),
                          labelText: 'Bio',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12.sp,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    GestureDetector(
                      onTap: () {
                        final bio = _bioCtrl.text.trim();
                        final imagePath = _pickedImagePath;
                        Navigator.pop(context);
                        widget.onSave(bio, imagePath);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.yellow, AppColors.orange],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellow.withOpacity(0.35),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Text(
                          'Save Changes',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: AppColors.dark,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  final double? bottomPadding;
  const _BottomSheetShell({
    required this.title,
    required this.child,
    this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B2A3A), Color(0xFF013C58)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: AppColors.sky.withOpacity(0.25)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, bottomPadding ?? 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}

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
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(center, radius, bgPaint);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 32});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(11);
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
                      decoration: const BoxDecoration(
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
