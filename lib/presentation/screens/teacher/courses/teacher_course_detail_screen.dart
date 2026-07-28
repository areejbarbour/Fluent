import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/courses/details/teacher_course_detail_cubit.dart';
import 'package:fluent/cubit/teacher/courses/details/teacher_course_detail_state.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/test_repository.dart';
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
      floatingActionButton: _buildFab(context),
    );
  }

  // ─────────────────────────────────────────────
  // Background
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Top bar
  // ─────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
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

          // ── Course Tests Icon Button ──
          // GestureDetector(
          //   onTap: () => _openCourseTests(context),
          //   child: Container(
          //     width: 44.w,
          //     height: 44.w,
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topLeft,
          //         end: Alignment.bottomRight,
          //         colors: [
          //           AppColors.orange.withOpacity(0.35),
          //           AppColors.orange.withOpacity(0.15),
          //         ],
          //       ),
          //       borderRadius: BorderRadius.circular(12.r),
          //       border: Border.all(color: AppColors.orange.withOpacity(0.5)),
          //       boxShadow: [
          //         BoxShadow(
          //           color: AppColors.orange.withOpacity(0.2),
          //           blurRadius: 8,
          //           offset: const Offset(0, 2),
          //         ),
          //       ],
          //     ),
          //     child: Stack(
          //       alignment: Alignment.center,
          //       children: [
          //         Icon(
          //           Icons.quiz_rounded,
          //           color: AppColors.orange,
          //           size: 24.sp,
          //         ),
          //         Positioned(
          //           right: 6,
          //           top: 6,
          //           child: Container(
          //             width: 12.w,
          //             height: 12.w,
          //             decoration: BoxDecoration(
          //               color: AppColors.yellow,
          //               borderRadius: BorderRadius.circular(6.r),
          //               border: Border.all(color: AppColors.dark, width: 1.5),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          SizedBox(width: 8.w),
        ],
      ),
    );
  }

  void _openCourseTests(BuildContext context) {
    Navigator.pushNamed(
      context,
      courseTestsRoute,
      arguments: {'course': course},
    ).then((result) {
      if (context.mounted) {
        context.read<TeacherCourseDetailCubit>().refresh();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Lessons list
  // ─────────────────────────────────────────────

  Widget _buildCourseTestsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCourseTests(context),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.orange.withOpacity(.22),
              AppColors.yellow.withOpacity(.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.orange.withOpacity(.45)),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(.18),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.quiz_rounded,
                color: AppColors.orange,
                size: 28.sp,
              ),
            ),

            SizedBox(width: 14.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Course Tests",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Create, edit and manage all course tests",
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList(
    BuildContext context,
    TeacherCourseDetailLoaded state,
  ) {
    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: () => context.read<TeacherCourseDetailCubit>().refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        itemCount: state.lessons.isEmpty ? 2 : state.lessons.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCourseTestsButton(
              context,
            ).animate().fadeIn(duration: 350.ms).moveY(begin: 15, end: 0);
          }

          if (state.lessons.isEmpty) {
            return _buildEmptyInline();
          }

          final lesson = state.lessons[index - 1];

          return _buildLessonCard(
            context,
            lesson,
            index - 1,
            state,
          ).animate().fadeIn(delay: (50 * index).ms).moveY(begin: 20, end: 0);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Course test card
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // Course Tests Section (multi-test)
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // Lesson card
  // ─────────────────────────────────────────────
  Widget _buildLessonCard(
    BuildContext context,
    LessonModel lesson,
    int index,
    TeacherCourseDetailLoaded state,
  ) {
    final statusColor = _getStatusColor(lesson.status);
    final statusLabel = _getStatusFriendlyName(lesson.status);
    final lessonTest = state.testForLesson(lesson.id);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          lessonDetailRoute, // ← هنا التعديل
          arguments: {
            'lessonId': lesson.id,
            'lessonTitle': lesson.titleEn.isNotEmpty
                ? lesson.titleEn
                : lesson.titleAr,
          },
        );
        // لما ترجع من التفاصيل (بعد تعديل أو حذف) نحدّث القائمة
        if (context.mounted) {
          context.read<TeacherCourseDetailCubit>().refresh();
        }
      },

      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
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
                      if (lessonTest != null)
                        _miniChip(
                          icon: Icons.quiz_outlined,
                          label: 'Test',
                          color: AppColors.sky,
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

  // ─────────────────────────────────────────────
  // Empty / FAB / Error
  // ─────────────────────────────────────────────
  Widget _buildEmptyInline() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 56.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            'No lessons yet',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Add your first lesson to this course',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    if (course.status != 'pending') {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.pushNamed(
          context,
          lessonFormRoute,
          arguments: {'courseId': course.id, 'courseStatus': course.status},
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

  // ─────────────────────────────────────────────
  // Status helpers
  // ─────────────────────────────────────────────
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
    switch (status.toLowerCase()) {
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
