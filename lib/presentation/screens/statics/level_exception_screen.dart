
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
      color: AppColors.lightOrange,
      icon: Icons.hourglass_top_rounded,
    ),
    _ExceptionStatusStyle(
      status: LevelExceptionStatuses.inReview,
      label: 'In Review',
      color: AppColors.sky,
      icon: Icons.rate_review_outlined,
    ),
    _ExceptionStatusStyle(
      status: LevelExceptionStatuses.approved,
      label: 'Approved',
      color: Color(0xFF00E676),
      icon: Icons.verified_outlined,
    ),
    _ExceptionStatusStyle(
      status: LevelExceptionStatuses.rejected,
      label: 'Rejected',
      color: Color(0xFFFF5252),
      icon: Icons.cancel_outlined,
    ),
  ];

  static _ExceptionStatusStyle of(String status) {
    return all.firstWhere(
      (s) => s.status == status.toLowerCase(),
      orElse: () => all.first,
    );
  }

  static List<_ExceptionStatusStyle> get tabbed => [
        all.firstWhere((s) => s.status == LevelExceptionStatuses.pending),
        all.firstWhere((s) => s.status == LevelExceptionStatuses.approved),
        all.firstWhere((s) => s.status == LevelExceptionStatuses.rejected),
      ];
}

class LevelExceptionsScreen extends StatefulWidget {
  const LevelExceptionsScreen({super.key});

  @override
  State<LevelExceptionsScreen> createState() => _LevelExceptionsScreenState();
}

class _LevelExceptionsScreenState extends State<LevelExceptionsScreen> {
  late final List<_ExceptionStatusStyle> _tabs = _ExceptionStatusStyle.tabbed;
  late final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LevelExceptionCubit>().loadBoard();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
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
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: _buildTopBar(),
                ),
                BlocBuilder<LevelExceptionCubit, LevelExceptionState>(
                  builder: (context, state) {
                    final success = state is LevelExceptionSuccess ? state : null;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 14.h),
                      child: _buildTabGates(success),
                    ).animate().fadeIn(duration: 350.ms).moveY(begin: 8, end: 0);
                  },
                ),
                Expanded(
                  child: BlocBuilder<LevelExceptionCubit, LevelExceptionState>(
                    builder: (context, state) {
                      if (state is LevelExceptionLoading || state is LevelExceptionInitial) {
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
                        return PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: _onPageChanged,
                          itemCount: _tabs.length,
                          itemBuilder: (context, index) {
                            final style = _tabs[index];
                            return _buildGateContent(style: style, state: state);
                          },
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

  Widget _buildTabGates(LevelExceptionSuccess? state) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final style = _tabs[i];
          final count = state?.countFor(style.status) ?? 0;
          final selected = i == _selectedIndex;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onTabTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? style.color : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          size: 14.sp,
                          color: selected
                              ? style.color
                              : style.color.withOpacity(0.55),
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            style.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.65),
                              fontSize: 12.sp,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        // Count badge - smaller & tighter
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? style.color.withOpacity(0.22)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.poppins(
                              color: selected
                                  ? style.color
                                  : Colors.white.withOpacity(0.6),
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGateContent({
    required _ExceptionStatusStyle style,
    required LevelExceptionSuccess state,
  }) {
    final items = state.itemsFor(style.status);
    final total = state.countFor(style.status);
    final hasMore = state.hasMore(style.status);
    final loadingMore = state.isLoadingMore(style.status);

    return RefreshIndicator(
      color: AppColors.yellow,
      backgroundColor: AppColors.dark,
      onRefresh: () => context.read<LevelExceptionCubit>().loadBoard(),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                SizedBox(height: 0.28.sh),
                _buildGateEmpty(style),
              ],
            )
          : ListView.separated(
              key: PageStorageKey(style.status),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
              itemCount: items.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return _LoadMoreButton(
                    loading: loadingMore,
                    loaded: items.length,
                    total: total,
                    onTap: () {
                      context.read<LevelExceptionCubit>().loadMore(style.status);
                    },
                  );
                }
                return _ExceptionCard(
                  item: items[index],
                  status: style.status,
                  index: index,
                )
                    .animate(delay: (40 * index).ms)
                    .fadeIn(duration: 320.ms)
                    .moveY(begin: 10, end: 0);
              },
            ),
    );
  }

  Widget _buildGateEmpty(_ExceptionStatusStyle style) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68.w,
            height: 68.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.color.withOpacity(.12),
              border: Border.all(color: style.color.withOpacity(.35), width: 1.5),
            ),
            child: Icon(style.icon, color: style.color.withOpacity(.75), size: 28.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            'Nothing here yet',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'No ${style.label.toLowerCase()} requests to show',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 42.sp),
            SizedBox(height: 14.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13.sp),
            ),
            SizedBox(height: 18.h),
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
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ),
        ),
        SizedBox(width: 44.w),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
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

    final isRejected = status.toLowerCase() == LevelExceptionStatuses.rejected;

    return BlocListener<LevelExceptionDeleteCubit, LevelExceptionDeleteState>(
      listener: (context, state) {
    if (state is LevelExceptionDeleteSuccess && state.id == item.id) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.15),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: const Color(0xFF4ADE80),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  state.message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5.sp,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          duration: const Duration(seconds: 3),
        ),
      );
      context.read<LevelExceptionCubit>().removeLocally(item.id);
      context.read<LevelExceptionCubit>().loadBoard();
    } else if (state is LevelExceptionDeleteFailure) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.15),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  state.message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5.sp,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          duration: const Duration(seconds: 3),
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
              'seed': item,
            },
          ).then((_) {
            if (context.mounted) {
              context.read<LevelExceptionCubit>().loadBoard();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.055),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: statusColor.withOpacity(isRejected ? 0.55 : 0.45),
              width: isRejected ? 1.6 : 1.35,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(isRejected ? 0.18 : 0.12),
                blurRadius: isRejected ? 14 : 10,
                spreadRadius: 0.4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(.32),
                      statusColor.withOpacity(.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13.r),
                  border: Border.all(color: statusColor.withOpacity(.40)),
                ),
                child: Icon(statusIcon, color: statusColor, size: 19.sp),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.5.h),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: statusColor.withOpacity(.40)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12.sp),
                          SizedBox(width: 4.w),
                          Text(
                            statusLabel,
                            style: GoogleFonts.poppins(
                              color: statusColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
                      border: Border.all(color: Colors.redAccent.withOpacity(.30)),
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
        )
            .animate(
              onPlay: isRejected ? (c) => c.repeat(reverse: true) : null,
            )
            .custom(
              duration: 1800.ms,
              builder: (context, value, child) {
                if (!isRejected) return child;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.12 + (value * 0.18)),
                        blurRadius: 10 + (value * 8),
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
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
            child: Container(
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
          padding: EdgeInsets.symmetric(vertical: 11.h),
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