import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/teacher/questions/blocking_tests/question_blocking_tests_cubit.dart';
import 'package:fluent/cubit/teacher/questions/blocking_tests/question_blocking_tests_state.dart';
import 'package:fluent/data/models/question_status_model.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class BlockingTestsScreen extends StatelessWidget {
  final int questionId;
  const BlockingTestsScreen({super.key, required this.questionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          QuestionBlockingTestsCubit(ctx.read<QuestionRepository>())
            ..fetchBlockingTests(questionId),
      child: _BlockingView(questionId: questionId),
    );
  }
}

class _BlockingView extends StatelessWidget {
  final int questionId;
  const _BlockingView({required this.questionId});

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
                _buildTopBar(), // ✅ تم إزالة الـ context لأننا لا نحتاجه للأزرار
                SizedBox(height: 16.h),
                Expanded(
                  child:
                      BlocBuilder<
                        QuestionBlockingTestsCubit,
                        QuestionBlockingTestsState
                      >(
                        builder: (context, state) {
                          if (state is QuestionBlockingTestsLoading ||
                              state is QuestionBlockingTestsInitial) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.yellow,
                              ),
                            );
                          }
                          if (state is QuestionBlockingTestsFailure) {
                            return _buildError(context, state.error);
                          }
                          if (state is QuestionBlockingTestsLoaded) {
                            return _buildLoaded(
                              context,
                              state.data.blockingTests,
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

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(decoration: QuestionUI.backgroundGradient()),
        Positioned(
          top: -100.h,
          right: -90.w,
          child: QuestionUI.glowingCircle(AppColors.orange, 280.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-15, 10),
                duration: 5000.ms,
              ),
        ),
        Positioned(
          bottom: -140.h,
          left: -100.w,
          child: QuestionUI.glowingCircle(AppColors.sky, 320.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(20, -15),
                duration: 6000.ms,
              ),
        ),
      ],
    );
  }

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
              color: AppColors.orange.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.orange.withOpacity(0.5)),
            ),
            child: Icon(Icons.block, color: AppColors.orange, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Blocking Tests",
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
  Widget _buildLoaded(BuildContext context, List<AffectedTest> tests) {
    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: () async {
        // عند السحب، يتم طلب البيانات من الباك اند مجدداً
        await context.read<QuestionBlockingTestsCubit>().fetchBlockingTests(
          questionId,
        );
      },
      child: ListView(
        // AlwaysScrollableScrollPhysics ضرورية لعمل الـ RefreshIndicator حتى لو كانت القائمة قصيرة
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _buildInfoBanner(
            tests.length,
          ).animate().fadeIn(duration: 400.ms).moveY(begin: 16, end: 0),
          SizedBox(height: 14.h),
          if (tests.isEmpty)
            _buildEmpty()
          else
            ...tests.asMap().entries.map((e) {
              final idx = e.key;
              return _testCard(tests[idx])
                  .animate()
                  .fadeIn(duration: 350.ms, delay: (40 * idx).ms)
                  .moveY(begin: 16, end: 0);
            }),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(int count) {
    return QuestionUI.glass(
      borderColor: AppColors.orange.withOpacity(0.4),
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.block, color: AppColors.orange, size: 22.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$count Published Test${count == 1 ? '' : 's'}",
                  style: GoogleFonts.poppins(
                    color: AppColors.orange,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  count > 0
                      ? "These tests are currently using this question. They must be unlinked before editing."
                      : "No tests are blocking this question. You can edit or delete it freely.",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11.sp,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.greenAccent.withOpacity(0.7),
              size: 56.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              "Nothing blocking",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "You can edit or delete this question freely.",
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _testCard(AffectedTest t) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: AppColors.orange.withOpacity(0.1), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: AppColors.orange,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.titleEn != null && t.titleEn!.isNotEmpty)
                  Text(
                    t.titleEn!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (t.titleAr != null && t.titleAr!.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    t.titleAr!,
                    style: GoogleFonts.cairo(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                  ),
                ],
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    t.testableType ?? "Published Test",
                    style: GoogleFonts.poppins(
                      color: AppColors.yellow,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
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
              onPressed: () => context
                  .read<QuestionBlockingTestsCubit>()
                  .fetchBlockingTests(questionId),
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
}
