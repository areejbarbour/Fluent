import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/teacher/questions/status/question_status_cubit.dart';
import 'package:fluent/cubit/teacher/questions/status/question_status_state.dart';
import 'package:fluent/data/models/question_status_model.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionStatusScreen extends StatelessWidget {
  final int questionId;
  const QuestionStatusScreen({super.key, required this.questionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          QuestionStatusCubit(ctx.read<QuestionRepository>())
            ..checkStatus(questionId),
      child: _StatusView(questionId: questionId),
    );
  }
}

class _StatusView extends StatelessWidget {
  final int questionId;
  const _StatusView({required this.questionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 12.h),
                _buildTopBar(), // ✅ تم إزالة الـ context لأننا لا نحتاجه للرجوع يدوياً
                SizedBox(height: 16.h),
                Expanded(
                  child: BlocBuilder<QuestionStatusCubit, QuestionStatusState>(
                    builder: (context, state) {
                      if (state is QuestionStatusLoading ||
                          state is QuestionStatusInitial) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.yellow,
                          ),
                        );
                      }
                      if (state is QuestionStatusFailure) {
                        return _buildError(context, state.error);
                      }
                      if (state is QuestionStatusLoaded) {
                        return _buildLoaded(context, state.status);
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

  Widget _buildBackground() => Stack(
    children: [
      Container(decoration: QuestionUI.backgroundGradient()),
      Positioned(
        top: -100.h,
        left: -80.w,
        child: QuestionUI.glowingCircle(AppColors.sky, 260.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(15, 10),
              duration: 5000.ms,
            ),
      ),
      Positioned(
        bottom: -140.h,
        right: -90.w,
        child: QuestionUI.glowingCircle(AppColors.yellow, 300.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(-20, -15),
              duration: 6000.ms,
            ),
      ),
    ],
  );

  // ✅ 1. الـ App Bar في المنتصف تماماً وبدون أزرار رجوع أو تحديث
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // توسيط المحتوى
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.sky.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.sky.withOpacity(0.5)),
            ),
            child: Icon(Icons.info_outline, color: AppColors.sky, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Question Status",
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: AppColors.sky.withOpacity(0.7),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }





  // ✅ 2. إضافة RefreshIndicator للسحب للتحديث
  Widget _buildLoaded(BuildContext context, QuestionStatus s) {
    final color = _statusColor(s.status);
    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: () async {
        // عند السحب، يتم طلب البيانات من الباك اند مجدداً
        await context.read<QuestionStatusCubit>().checkStatus(questionId);
      },
      child: ListView(
        // AlwaysScrollableScrollPhysics ضرورية لعمل الـ RefreshIndicator حتى لو كانت القائمة قصيرة
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _buildStatusHero(
            s,
            color,
          ).animate().fadeIn(duration: 400.ms).moveY(begin: 16, end: 0),
          SizedBox(height: 14.h),
          _buildMessage(s),
          SizedBox(height: 14.h),
          if (s.willRevertToPending) ...[
            _buildRevertNotice(),
            SizedBox(height: 14.h),
          ],
          _buildAffectedSection(
            "Published Tests",
            s.affectedPublishedTests,
            AppColors.sky,
            Icons.public,
          ),
          SizedBox(height: 10.h),
          _buildAffectedSection(
            "Archived Tests",
            s.affectedArchivedTests,
            AppColors.orange,
            Icons.archive_outlined,
          ),
          SizedBox(height: 10.h),
          _buildAffectedSection(
            "In Review Tests",
            s.affectedInReviewTests,
            Colors.amber,
            Icons.rate_review_outlined,
          ),
          SizedBox(height: 10.h),
          _buildAffectedSection(
            "Approved Tests",
            s.affectedApprovedTests,
            Colors.greenAccent,
            Icons.verified_outlined,
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildStatusHero(QuestionStatus s, Color color) {
    return QuestionUI.glass(
      radius: 18,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(_statusIcon(s.status), color: color, size: 36.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            _statusLabel(s.status),
            style: GoogleFonts.cinzelDecorative(
              color: color,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 12)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(QuestionStatus s) {
    return QuestionUI.glass(
      radius: 16,
      padding: EdgeInsets.all(12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.yellow, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              s.message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevertNotice() {
    return QuestionUI.glass(
      radius: 16,
      borderColor: Colors.amber.withOpacity(0.5),
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              "This question is also used in approved test(s) that will be reverted to pending and require re-review after this edit.",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11.sp,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffectedSection(
    String title,
    List<AffectedTest> tests,
    Color color,
    IconData icon,
  ) {
    if (tests.isEmpty) return const SizedBox.shrink();
    return QuestionUI.glass(
      radius: 16,
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  "${tests.length}",
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...tests.map((t) => _testTile(t, color)),
        ],
      ),
    );
  }

  Widget _testTile(AffectedTest t, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 7.w,
            height: 7.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              t.displayTitle,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (t.testableType != null) ...[
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                t.testableType!,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.redAccent.withOpacity(0.8),
              size: 56.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              msg,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<QuestionStatusCubit>().checkStatus(questionId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'locked':
        return Colors.redAccent;
      case 'versioned':
        return AppColors.orange;
      case 'locked_in_review':
        return Colors.amber;
      case 'Editable.':
      default:
        return Colors.greenAccent;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'locked':
        return Icons.lock_outline;
      case 'versioned':
        return Icons.history;
      case 'locked_in_review':
        return Icons.rate_review_outlined;
      case 'Editable.':
      default:
        return Icons.edit_outlined;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'locked':
        return 'LOCKED';
      case 'versioned':
        return 'VERSIONED';
      case 'locked_in_review':
        return 'IN REVIEW';
      case 'Editable.':
      default:
        return 'EDITABLE';
    }
  }
}
