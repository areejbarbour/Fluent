

import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/student/levels/level_exception_cubit.dart';
import 'package:fluent/cubit/student/levels/level_exception_delete_cubit.dart';
import 'package:fluent/cubit/student/levels/level_exception_delete_state.dart';
import 'package:fluent/cubit/student/levels/level_exception_state.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelExceptionsScreen extends StatefulWidget {
  const LevelExceptionsScreen({super.key});

  @override
  State<LevelExceptionsScreen> createState() => _LevelExceptionsScreenState();
}

class _LevelExceptionsScreenState extends State<LevelExceptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_TabInfo> _tabs = const [
    _TabInfo(
      status: 'pending',
      title: 'Pending',
      icon: Icons.hourglass_top_rounded,
    ),
    _TabInfo(
      status: 'approved',
      title: 'Approved',
      icon: Icons.check_circle_rounded,
    ),
    _TabInfo(
      status: 'rejected',
      title: 'Rejected',
      icon: Icons.cancel_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LevelExceptionCubit>().fetchByStatus('pending');
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = _tabs[_tabController.index].status;
        context.read<LevelExceptionCubit>().fetchByStatus(status);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          _buildBackground(),
          _TwinklingStars(count: 28),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: _buildTopBar(),
                ),
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildTabs(),
                ),
                SizedBox(height: 18.h),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabs.map((t) {
                      return BlocBuilder<LevelExceptionCubit,
                          LevelExceptionState>(
                        builder: (context, state) {
                          if (state is LevelExceptionLoading) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 36.w,
                                    height: 36.w,
                                    child: const CircularProgressIndicator(
                                      color: AppColors.yellow,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(height: 14.h),
                                  Text(
                                    'Loading...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (state is LevelExceptionFailure) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(16.r),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Colors.redAccent.withOpacity(.12),
                                        border: Border.all(
                                          color: Colors.redAccent
                                              .withOpacity(.25),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 32.sp,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 13.sp,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (state is LevelExceptionSuccess &&
                              state.status == t.status) {
                            if (state.exceptions.isEmpty) {
                              return _buildEmptyState(t);
                            }

                            return ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                20.w,
                                4.h,
                                20.w,
                                28.h,
                              ),
                              itemCount: state.exceptions.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 12.h),
                              itemBuilder: (context, i) {
                                return _ExceptionCard(
                                  item: state.exceptions[i],
                                  status: t.status,
                                  index: i,
                                );
                              },
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
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
          top: 400.h,
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
          top: 750.h,
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
                  'Level Exceptions',
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
                  width: 28.w,
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
        SizedBox(width: 44.w),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
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

  Widget _buildTabs() {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.orange, AppColors.yellow],
          ),
          borderRadius: BorderRadius.circular(11.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withOpacity(.35),
              blurRadius: 10,
            ),
          ],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white.withOpacity(.65),
        labelStyle: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: _tabs
            .map(
              (t) => Tab(
                height: 40.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 14.sp),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ).animate().fadeIn(duration: 450.ms).moveY(begin: 8, end: 0);
  }

  Widget _buildEmptyState(_TabInfo tab) {
    IconData icon;
    String message;
    String subtitle;
    Color accent;

    switch (tab.status) {
      case 'approved':
        icon = Icons.check_circle_outline_rounded;
        message = 'No approved requests yet';
        subtitle = 'Approved requests will appear here';
        accent = Colors.greenAccent;
        break;
      case 'rejected':
        icon = Icons.cancel_outlined;
        message = 'No rejected requests';
        subtitle = 'Rejected requests will appear here';
        accent = Colors.redAccent;
        break;
      default:
        icon = Icons.hourglass_empty_rounded;
        message = 'No pending requests';
        subtitle = 'Your pending requests will appear here';
        accent = AppColors.yellow;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withOpacity(.18),
                  accent.withOpacity(.05),
                ],
              ),
              border: Border.all(color: accent.withOpacity(.25)),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(icon, color: accent.withOpacity(.7), size: 36.sp),
          ),
          SizedBox(height: 18.h),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.55),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.30),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
        );
  }
}

class _TabInfo {
  final String status;
  final String title;
  final IconData icon;
  const _TabInfo({
    required this.status,
    required this.title,
    required this.icon,
  });
}

class _ExceptionCard extends StatelessWidget {
  final LevelExceptionModel item;
  final String status;
  final int index;

  const _ExceptionCard({
    required this.item,
    required this.status,
    required this.index,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
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
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 26.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Delete Request?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Are you sure you want to delete exception request #${item.id}?\nThis action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.65),
                        fontSize: 12.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
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
                              context
                                  .read<LevelExceptionDeleteCubit>()
                                  .delete(item.id);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 13.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.redAccent,
                                    Color(0xFFFF6B6B),
                                  ],
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
                                'Yes, Delete',
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

  @override
  Widget build(BuildContext context) {
    late Color statusColor;
    late String statusLabel;
    late IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = const Color(0xFF69F0AE);
        statusLabel = 'Approved';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.yellow;
        statusLabel = 'Pending';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return BlocListener<LevelExceptionDeleteCubit, LevelExceptionDeleteState>(
      listener: (context, state) {
        if (state is LevelExceptionDeleteSuccess && state.id == item.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.poppins(fontSize: 13.sp),
              ),
              backgroundColor: AppColors.sky,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
          context.read<LevelExceptionCubit>().fetchByStatus(status);
        } else if (state is LevelExceptionDeleteFailure) {
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
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pushNamed(
            context,
            levelExceptionDetailsRoute,
            arguments: {'id': item.id},
          );
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
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
          child: Row(
            children: [
              // Level badge
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor.withOpacity(.28),
                      statusColor.withOpacity(.08),
                    ],
                  ),
                  border: Border.all(color: statusColor.withOpacity(.35)),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(.20),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    item.requestedLevel?.name ?? '?',
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                       //'Move to Level ${item.requestedLevel?.name ?? ''}',
                      "Proceed to the details of the excepion request",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          color: Colors.white.withOpacity(.40),
                          size: 12.sp,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          '${item.id}',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.50),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // Status badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(.14),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: statusColor.withOpacity(.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                color: statusColor,
                                size: 11.sp,
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                statusLabel,
                                style: GoogleFonts.poppins(
                                  color: statusColor,
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              // Delete button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _confirmDelete(context);
                },
                child: Container(
                  padding: EdgeInsets.all(9.r),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(.28),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 17.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: (80 * index).ms)
          .fadeIn(duration: 450.ms)
          .moveY(begin: 14, end: 0, curve: Curves.easeOut),
    );
  }
}

class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 40});

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