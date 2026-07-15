
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
          Container(decoration: QuestionUI.backgroundGradient()),
          Positioned(
            top: -100.h,
            left: -80.w,
            child: QuestionUI
                .glowingCircle(AppColors.sky, 260.w)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(15, 10),
                    duration: 5000.ms),
          ),
          Positioned(
            bottom: -140.h,
            right: -90.w,
            child: QuestionUI
                .glowingCircle(AppColors.yellow, 300.w)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(-20, -15),
                    duration: 6000.ms),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 12.h),
                _buildTopBar(context),
                SizedBox(height: 12.h),
                Expanded(
                  child: BlocBuilder<QuestionStatusCubit, QuestionStatusState>(
                    builder: (context, state) {
                      if (state is QuestionStatusLoading ||
                          state is QuestionStatusInitial) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.yellow),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Text("Question Status",
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: AppColors.sky.withOpacity(0.7), blurRadius: 10),
                ],
              )),
          const Spacer(),
          GestureDetector(
            onTap: () =>
                context.read<QuestionStatusCubit>().checkStatus(questionId),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: Icon(Icons.refresh, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, QuestionStatus s) {
    final color = _statusColor(s.status);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      children: [
        _buildStatusHero(s, color).animate().fadeIn(duration: 400.ms).moveY(begin: 16, end: 0),
        SizedBox(height: 16.h),
        _buildMessage(s),
        SizedBox(height: 16.h),
        if (s.willRevertToPending) ...[
          _buildRevertNotice(),
          SizedBox(height: 16.h),
        ],
        _buildAffectedSection(
          "Published Tests",
          s.affectedPublishedTests,
          AppColors.sky,
          Icons.public,
        ),
        SizedBox(height: 12.h),
        _buildAffectedSection(
          "Archived Tests",
          s.affectedArchivedTests,
          AppColors.orange,
          Icons.archive_outlined,
        ),
        SizedBox(height: 12.h),
        _buildAffectedSection(
          "In Review Tests",
          s.affectedInReviewTests,
          Colors.amber,
          Icons.rate_review_outlined,
        ),
        SizedBox(height: 12.h),
        _buildAffectedSection(
          "Approved Tests",
          s.affectedApprovedTests,
          Colors.greenAccent,
          Icons.verified_outlined,
        ),
        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _buildStatusHero(QuestionStatus s, Color color) {
    return QuestionUI.glass(
      borderColor: color.withOpacity(0.5),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
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
            child: Icon(_statusIcon(s.status), color: color, size: 40.sp),
          ),
          SizedBox(height: 14.h),
          Text(_statusLabel(s.status),
              style: GoogleFonts.cinzelDecorative(
                color: color,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(color: color.withOpacity(0.6), blurRadius: 12),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildMessage(QuestionStatus s) {
    return QuestionUI.glass(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.yellow, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(s.message,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 13.sp, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildRevertNotice() {
    return QuestionUI.glass(
      borderColor: Colors.amber.withOpacity(0.5),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 20.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "This question is also used in approved test(s) that will be reverted to pending and require re-review after this edit.",
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 12.sp, height: 1.4),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(width: 6.w),
              Text(title,
                  style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text("${tests.length}",
                    style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...tests.map((t) => _testTile(t, color)),
        ],
      ),
    );
  }

  Widget _testTile(AffectedTest t, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(t.displayTitle,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (t.testableType != null) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(t.testableType!,
                  style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700)),
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
            Icon(Icons.error_outline,
                color: Colors.redAccent.withOpacity(0.8), size: 56.sp),
            SizedBox(height: 12.h),
            Text(msg,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 14.sp),
                textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<QuestionStatusCubit>()
                  .checkStatus(questionId),
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

  // ─── Status helpers ─────────────────────────────
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