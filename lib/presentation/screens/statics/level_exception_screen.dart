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

/// Visual tokens aligned with teacher [StatusUI] / Status Board.
class _ExceptionStatusStyle {
  final String status;
  final String label;
  final Color color;
  final IconData icon;

  const _ExceptionStatusStyle({
    required this.status,
    required this.label,
    required this.color,
    required this.icon,
  });

  static const List<_ExceptionStatusStyle> all = [
    _ExceptionStatusStyle(
      status: LevelExceptionStatuses.pending,
      label: 'Pending',
      // StatusUI.pending → lightOrange
      color: AppColors.lightOrange,
      icon: Icons.hourglass_top_rounded,
    ),
    _ExceptionStatusStyle(
      status: LevelExceptionStatuses.inReview,
      label: 'In Review',
      // StatusUI.inReview → sky
      color: AppColors.sky,
      icon: Icons.rate_review_outlined,
    ),
    _ExceptionStatusStyle(
      status: LevelExceptionStatuses.approved,
      label: 'Approved',
      // StatusUI.approved → greenAccent
      color: Color(0xFF69F0AE),
      icon: Icons.verified_outlined,
    ),
    _ExceptionStatusStyle(
      status: LevelExceptionStatuses.rejected,
      label: 'Rejected',
      color: Colors.redAccent,
      icon: Icons.cancel_outlined,
    ),
  ];

  static _ExceptionStatusStyle of(String status) {
    return all.firstWhere(
      (s) => s.status == status.toLowerCase(),
      orElse: () => all.first,
    );
  }
}

class LevelExceptionsScreen extends StatefulWidget {
  const LevelExceptionsScreen({super.key});

  @override
  State<LevelExceptionsScreen> createState() => _LevelExceptionsScreenState();
}

class _LevelExceptionsScreenState extends State<LevelExceptionsScreen> {
  /// Same expand/collapse pattern as teacher Status Board.
  final Set<String> _expanded = {LevelExceptionStatuses.pending};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LevelExceptionCubit>().loadBoard();
    });
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
                Expanded(
                  child: BlocBuilder<LevelExceptionCubit, LevelExceptionState>(
                    builder: (context, state) {
                      if (state is LevelExceptionLoading ||
                          state is LevelExceptionInitial) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.yellow,
                            strokeWidth: 2.4,
                          ),
                        );
                      }

                      if (state is LevelExceptionFailure) {
                        return _buildError(state.message);
                      }

                      if (state is LevelExceptionSuccess) {
                        return RefreshIndicator(
                          color: AppColors.yellow,
                          backgroundColor: AppColors.dark,
                          onRefresh: () =>
                              context.read<LevelExceptionCubit>().loadBoard(),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
                            itemCount: _ExceptionStatusStyle.all.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              final style = _ExceptionStatusStyle.all[index];
                              final items = state.itemsFor(style.status);
                              return _buildStatusSection(
                                    style: style,
                                    items: items,
                                    boardState: state,
                                  )
                                  .animate(delay: (60 * index).ms)
                                  .fadeIn(duration: 400.ms)
                                  .moveY(begin: 10, end: 0);
                            },
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Board section (mirrors teacher board glass header) ──
  Widget _buildStatusSection({
    required _ExceptionStatusStyle style,
    required List<LevelExceptionModel> items,
    required LevelExceptionSuccess boardState,
  }) {
    final isOpen = _expanded.contains(style.status);
    final color = style.color;
    final total = boardState.countFor(style.status);
    final hasMore = boardState.hasMore(style.status);
    final loadingMore = boardState.isLoadingMore(style.status);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isOpen) {
                      _expanded.remove(style.status);
                    } else {
                      _expanded.add(style.status);
                    }
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: color.withOpacity(0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(style.icon, color: color, size: 18.sp),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        style.label,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: color.withOpacity(0.45)),
                      ),
                      child: Text(
                        '$total',
                        style: GoogleFonts.poppins(
                          color: color,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.6),
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: isOpen
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: items.isEmpty
                      ? _sectionEmpty(style)
                      : Column(
                          children: [
                            for (int i = 0; i < items.length; i++) ...[
                              if (i != 0) SizedBox(height: 8.h),
                              _ExceptionCard(
                                item: items[i],
                                status: style.status,
                                index: i,
                              ),
                            ],
                            if (hasMore) ...[
                              SizedBox(height: 10.h),
                              _LoadMoreButton(
                                loading: loadingMore,
                                loaded: items.length,
                                total: total,
                                onTap: () {
                                  context.read<LevelExceptionCubit>().loadMore(
                                    style.status,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                ),
                secondChild: const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionEmpty(_ExceptionStatusStyle style) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        'Nothing in this status',
        style: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.5),
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 40.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: () => context.read<LevelExceptionCubit>().loadBoard(),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(.08),
              border: Border.all(color: Colors.white.withOpacity(.15)),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Level Exceptions',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 44.w),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ===============================================================
//                         Exception Card
// ===============================================================
class _ExceptionCard extends StatelessWidget {
  final LevelExceptionModel item;
  final String status;
  final int index;

  const _ExceptionCard({
    required this.item,
    required this.status,
    required this.index,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete request?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this exception request?\nThis action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<LevelExceptionDeleteCubit>().delete(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _ExceptionStatusStyle.of(status);
    final statusColor = style.color;
    final statusLabel = style.label;
    final statusIcon = style.icon;

    final levelName = item.requestedLevelName ?? 'Level exception request';

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
          // Optimistic local remove + soft refresh
          context.read<LevelExceptionCubit>().removeLocally(item.id);
          context.read<LevelExceptionCubit>().loadBoard();
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
            arguments: {
              'id': item.id,
              // List endpoint eager-loads requested_level; details view does not.
              // Pass the model so the details screen can show the level name
              // without any backend change.
              'seed': item,
            },
          ).then((_) {
            if (context.mounted) {
              context.read<LevelExceptionCubit>().loadBoard();
            }
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.05),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.white.withOpacity(.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(.28),
                      statusColor.withOpacity(.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: statusColor.withOpacity(.35)),
                ),
                child: Icon(statusIcon, color: statusColor, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        // Status chip — same language as Status Board badges
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
                              Icon(statusIcon, color: statusColor, size: 11.sp),
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
              if (status.toLowerCase() == LevelExceptionStatuses.pending) ...[
                SizedBox(width: 8.w),
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
            ],
          ),
        ),
      ),
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

          return Positioned(
            left: left * MediaQuery.sizeOf(context).width,
            top: top * MediaQuery.sizeOf(context).height,
            child:
                Container(
                      width: size,
                      height: size,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(
                      begin: 0.15,
                      end: maxOpacity,
                      duration: Duration(milliseconds: duration),
                      delay: Duration(milliseconds: delay),
                    ),
          );
        }),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool loading;
  final int loaded;
  final int total;
  final VoidCallback onTap;

  const _LoadMoreButton({
    required this.loading,
    required this.loaded,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            color: Colors.white.withOpacity(0.04),
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.yellow,
                  ),
                )
              : Text(
                  'Load more ($loaded / $total)',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
