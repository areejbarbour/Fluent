import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/rate/rate_cubit.dart';
import 'package:fluent/cubit/student/rate/rate_state.dart';
import 'package:fluent/data/models/rate_model.dart';
import 'package:fluent/data/repository/rate_repository.dart';
import 'package:fluent/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional bottom sheet to rate a completed course (1–5 stars).
///
/// Usage:
/// ```dart
/// final result = await RateCourseSheet.show(
///   context,
///   courseId: course.id,
///   courseTitle: course.title,
///   initialStars: rateCubit.rateForCourse(course.id)?.stars,
///   existingRateId: rateCubit.rateForCourse(course.id)?.id,
/// );
/// // result is RateModel? after success, or null if dismissed
/// ```
class RateCourseSheet extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  final int? initialStars;
  final int? existingRateId;

  const RateCourseSheet({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.initialStars,
    this.existingRateId,
  });

  /// Shows the sheet and returns the saved [RateModel] on success, or null.
  ///
  /// Prefer passing [rateCubit] when the caller's context is above the provider
  /// (typical for State.context of the screen that owns the cubit).
  static Future<RateModel?> show(
    BuildContext context, {
    required int courseId,
    required String courseTitle,
    int? initialStars,
    int? existingRateId,
    RateCubit? rateCubit,
  }) {
    return showModalBottomSheet<RateModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        RateCubit? resolved = rateCubit;
        if (resolved == null) {
          try {
            resolved = context.read<RateCubit>();
          } catch (_) {
            resolved = null;
          }
        }

        final child = RateCourseSheet(
          courseId: courseId,
          courseTitle: courseTitle,
          initialStars: initialStars,
          existingRateId: existingRateId,
        );

        if (resolved != null) {
          return BlocProvider<RateCubit>.value(value: resolved, child: child);
        }
        return BlocProvider(
          create: (ctx) => RateCubit(ctx.read<RateRepository>()),
          child: child,
        );
      },
    );
  }

  @override
  State<RateCourseSheet> createState() => _RateCourseSheetState();
}

class _RateCourseSheetState extends State<RateCourseSheet> {
  late int _selectedStars;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStars ?? 0;
    _selectedStars = initial.clamp(0, 5);
  }

  void _onStarTap(int star) {
    HapticFeedback.selectionClick();
    setState(() => _selectedStars = star);
  }

  void _submit() {
    if (_selectedStars < 1 || _selectedStars > 5) {
      showAppSnackBar(
        context,
        'Please select a rating from 1 to 5 stars.',
        type: AppSnackType.warning,
      );
      return;
    }
    setState(() => _submitted = true);
    context.read<RateCubit>().rateCourse(
      courseId: widget.courseId,
      stars: _selectedStars,
    );
  }

  void _delete() {
    final rateId =
        widget.existingRateId ??
        context.read<RateCubit>().rateForCourse(widget.courseId)?.id;
    if (rateId == null) return;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Remove rating?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
        content: Text(
          'Your rating for "${widget.courseTitle}" will be removed.',
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
              'Remove',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<RateCubit>().deleteRate(
          courseId: widget.courseId,
          rateId: rateId,
        );
      }
    });
  }

  String _labelForStars(int stars) {
    switch (stars) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasExisting =
        (widget.existingRateId != null && widget.existingRateId! > 0) ||
        context.read<RateCubit>().hasRated(widget.courseId);

    return BlocListener<RateCubit, RateState>(
      listener: (context, state) {
        if (state is RateSuccess && state.courseId == widget.courseId) {
          showAppSnackBar(context, state.message, type: AppSnackType.success);
          Navigator.of(context).pop(state.rate);
        } else if (state is RateDeleted && state.courseId == widget.courseId) {
          showAppSnackBar(context, state.message, type: AppSnackType.info);
          Navigator.of(context).pop(null);
        } else if (state is RateFailure &&
            (state.courseId == null || state.courseId == widget.courseId)) {
          setState(() => _submitted = false);
          showAppSnackBar(context, state.message, type: AppSnackType.error);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B2A3A), Color(0xFF013C58)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border.all(color: AppColors.sky.withOpacity(0.25)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
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
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.yellow.withOpacity(0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: AppColors.yellow,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasExisting
                              ? 'Update your rating'
                              : 'Rate this course',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.courseTitle,
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasExisting)
                    IconButton(
                      tooltip: 'Remove rating',
                      onPressed: _delete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent.withOpacity(0.9),
                        size: 22.sp,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 22.h),
              Text(
                _labelForStars(_selectedStars),
                style: GoogleFonts.poppins(
                  color: _selectedStars > 0 ? AppColors.yellow : Colors.white54,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  final filled = star <= _selectedStars;
                  return GestureDetector(
                    onTap: () => _onStarTap(star),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: AnimatedScale(
                        scale: filled ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        child: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 40.sp,
                          color: filled
                              ? AppColors.yellow
                              : Colors.white.withOpacity(0.35),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 24.h),
              BlocBuilder<RateCubit, RateState>(
                builder: (context, state) {
                  final loading =
                      state is RateLoading &&
                      state.courseId == widget.courseId &&
                      !state.isDeleting;
                  return SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: loading || _submitted ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        disabledBackgroundColor: AppColors.yellow.withOpacity(
                          0.5,
                        ),
                        foregroundColor: AppColors.dark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 0,
                      ),
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
                              hasExisting ? 'Update rating' : 'Submit rating',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  );
                },
              ),
              SizedBox(height: 8.h),
              Text(
                'You can rate only courses you have completed.',
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 11.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
