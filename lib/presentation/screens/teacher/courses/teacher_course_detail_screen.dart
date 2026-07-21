import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/courses/details/teacher_course_detail_cubit.dart';
import 'package:fluent/cubit/teacher/courses/details/teacher_course_detail_state.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherCourseDetailScreen extends StatelessWidget {
  final CourseModel course;
  const TeacherCourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) => _CourseDetailView(course: course);
}

class _CourseDetailView extends StatelessWidget {
  final CourseModel course;
  const _CourseDetailView({required this.course});

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
                _buildTopBar(context),
                SizedBox(height: 10.h),
                Expanded(
                  child:
                      BlocBuilder<
                        TeacherCourseDetailCubit,
                        TeacherCourseDetailState
                      >(
                        builder: (context, state) {
                          if (state is TeacherCourseDetailLoading ||
                              state is TeacherCourseDetailInitial) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.yellow,
                              ),
                            );
                          }
                          if (state is TeacherCourseDetailFailure) {
                            return _buildError(context, state.error);
                          }
                          if (state is TeacherCourseDetailLoaded) {
                            return _buildLessonsList(context, state);
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
      // ✅ سيتم إخفاء هذا الزر تلقائياً إذا لم يكن الكورس في حالة 'pending'
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildBackground() => Stack(
    children: [
      Container(decoration: QuestionUI.backgroundGradient()),
      Positioned(
        top: -120.h,
        right: -100.w,
        child: QuestionUI.glowingCircle(AppColors.yellow, 320.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(-15, 10),
              duration: 5000.ms,
            ),
      ),
      Positioned(
        bottom: -160.h,
        left: -110.w,
        child: QuestionUI.glowingCircle(AppColors.sky, 380.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(20, -15),
              duration: 6000.ms,
            ),
      ),
    ],
  );

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        children: [
          SizedBox(width: 12.w),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.yellow,
              size: 22,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                "Lessons of ${course.name}",
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

  Widget _buildLessonsList(
    BuildContext context,
    TeacherCourseDetailLoaded state,
  ) {
    if (state.lessons.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: () => context.read<TeacherCourseDetailCubit>().refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        itemCount: state.lessons.length,
        itemBuilder: (context, index) =>
            _buildLessonCard(context, state.lessons[index], index)
                .animate()
                .fadeIn(duration: 400.ms, delay: (60 * index).ms)
                .moveY(begin: 20, end: 0, duration: 400.ms),
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, LessonModel lesson, int index) {
    final statusColor = _getStatusColor(lesson.status);
    final statusLabel = _getStatusFriendlyName(lesson.status);
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          lessonFormRoute,
          arguments: {
            'lesson': lesson,
            'courseStatus': course
                .status, // ✅ نمرر حالة الكورس هنا لمنع التعديل إذا كان منشوراً
          },
        );
        if (result == true && context.mounted) {
          context.read<TeacherCourseDetailCubit>().refresh();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          // ✅ تم إزالة const وإصلاح تكرار colors ليظهر التأثير الزجاجي الداكن بشكل صحيح
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: statusColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ تحديث ليتطابق مع LessonModel الجديد (titleEn / titleAr)
                  Text(
                    lesson.titleEn.isNotEmpty ? lesson.titleEn : lesson.titleAr,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _miniChip(
                        icon: Icons.star_rounded,
                        label: '${lesson.xpPoints} XP',
                        color: AppColors.yellow,
                      ),
                      _miniChip(
                        icon: Icons.low_priority_rounded,
                        label: 'Order ${lesson.order}',
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11.sp),
          SizedBox(width: 3.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    // ✅ قاعدة الـ Backend: لا يمكن إضافة دروس إلا إذا كان الكورس في حالة 'pending'
    if (course.status != 'pending') {
      return const SizedBox.shrink(); // إخفاء الزر تماماً
    }

    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.pushNamed(
          context,
          lessonFormRoute,
          arguments: {
            'courseId': course.id,
            'courseStatus': course.status, // ✅ نمرر حالة الكورس هنا أيضاً
          },
        );
        if (result == true && context.mounted) {
          context.read<TeacherCourseDetailCubit>().refresh();
        }
      },
      backgroundColor: AppColors.yellow,
      foregroundColor: AppColors.dark,
      icon: Icon(Icons.add_rounded, size: 20.sp),
      label: Text(
        'Add Lesson',
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.video_library_outlined,
          color: Colors.white.withOpacity(0.3),
          size: 64.sp,
        ),
        SizedBox(height: 14.h),
        Text(
          "No lessons yet",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          "Add your first lesson to this course",
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildError(BuildContext context, String msg) => Center(
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
            onPressed: () => context.read<TeacherCourseDetailCubit>().refresh(),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published':
        return Colors.greenAccent;
      case 'pending':
        return AppColors.lightOrange;
      case 'draft':
        return Colors.white70;
      case 'in_review':
        return AppColors.sky;
      case 'changes_requested':
        return Colors.redAccent;
      case 'approved':
        return Colors.teal;
      case 'archived':
        return Colors.purpleAccent;
      case 'closed':
        return Colors.blueGrey;
      default:
        return Colors.white54;
    }
  }

  String _getStatusFriendlyName(String status) {
    switch (status) {
      case 'published':
        return 'Live';
      case 'pending':
        return 'Submitted';
      case 'draft':
        return 'Draft';
      case 'in_review':
        return 'Under Review';
      case 'changes_requested':
        return 'Needs Revision';
      case 'approved':
        return 'Approved';
      case 'archived':
        return 'Archived';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }
}
