import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/courses/all/teacher_courses_cubit.dart';
import 'package:fluent/cubit/teacher/courses/all/teacher_courses_state.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                _buildTopBar(),
                SizedBox(height: 16.h),
                _buildTitle(),
                SizedBox(height: 18.h),
                _buildSearchBar(),
                SizedBox(height: 12.h),
                _buildFilterChips(),
                SizedBox(height: 16.h),
                Expanded(
                  child: BlocBuilder<TeacherCoursesCubit, TeacherCoursesState>(
                    builder: (context, state) {
                      if (state is TeacherCoursesLoading ||
                          state is TeacherCoursesInitial) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.yellow,
                          ),
                        );
                      }
                      if (state is TeacherCoursesFailure) {
                        return _buildError(state.error);
                      }
                      if (state is TeacherCoursesLoaded) {
                        if (state.filteredCourses.isEmpty) return _buildEmpty();
                        return RefreshIndicator(
                          color: AppColors.yellow,
                          // ✅ السحب للتحديث لا يزال متاحاً كخيار احتياطي
                          onRefresh: () =>
                              context.read<TeacherCoursesCubit>().refresh(),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 18.w,
                              vertical: 8.h,
                            ),
                            itemCount: state.filteredCourses.length,
                            itemBuilder: (context, index) =>
                                _buildCourseCard(
                                      state.filteredCourses[index],
                                      index,
                                    )
                                    .animate()
                                    .fadeIn(
                                      duration: 400.ms,
                                      delay: (60 * index).ms,
                                    )
                                    .moveY(begin: 20, end: 0, duration: 400.ms),
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

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(decoration: QuestionUI.backgroundGradient()),
        Positioned(
          top: -120.h,
          left: -100.w,
          child: QuestionUI.glowingCircle(AppColors.yellow, 320.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(15, 10),
                duration: 5000.ms,
              ),
        ),
        Positioned(
          bottom: -160.h,
          right: -110.w,
          child: QuestionUI.glowingCircle(AppColors.sky, 380.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-20, -15),
                duration: 6000.ms,
              ),
        ),
      ],
    );
  }

  // ✅ 1. تم إزالة أيقونة التحديث من هنا، وأصبح يحتوي فقط على العداد
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<TeacherCoursesCubit, TeacherCoursesState>(
            builder: (context, state) {
              if (state is TeacherCoursesLoaded) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(
                    "${state.allCourses.length} Total",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // تم حذف GestureDetector الخاص بأيقونة التحديث
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
                ),
                child: Icon(
                  Icons.library_books_rounded,
                  color: AppColors.yellow,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "My Courses",
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
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            "Organize and update your courses easily",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: QuestionUI.glass(
        radius: 14,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13.sp,
            ),
            border: InputBorder.none,
            icon: Icon(
              Icons.search_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20.sp,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.clear_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 18.sp,
              ),
              onPressed: () {
                _searchController.clear();
                context.read<TeacherCoursesCubit>().searchCourses('');
              },
            ),
          ),
          onChanged: (value) =>
              context.read<TeacherCoursesCubit>().searchCourses(value),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All', Colors.white),
      ('published', 'Live', Colors.greenAccent),
      ('pending', 'In Prep', AppColors.lightOrange),
      ('archived', 'Archived', Colors.purpleAccent),
      ('closed', 'Closed', Colors.blueGrey),
    ];
    return BlocBuilder<TeacherCoursesCubit, TeacherCoursesState>(
      builder: (context, state) {
        final currentFilter = state is TeacherCoursesLoaded
            ? state.currentFilter
            : 'all';
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: filters.map((f) {
              final (value, label, color) = f;
              final isSelected = currentFilter == value;
              return GestureDetector(
                onTap: () =>
                    context.read<TeacherCoursesCubit>().filterByStatus(value),
                child: AnimatedContainer(
                  duration: 250.ms,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.25)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? color.withOpacity(0.8)
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: isSelected ? color : Colors.white.withOpacity(0.7),
                      fontSize: 11.sp,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(CourseModel course, int index) {
    final statusColor = _getStatusColor(course.status);
    final statusLabel = _getStatusFriendlyName(course.status);
    return GestureDetector(
      // ✅ 2. التحديث التلقائي عند العودة من شاشة التفاصيل/التعديل
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          teacherCourseDetailRoute,
          arguments: course,
        );

        // إذا أرجعت الشاشة التالية قيمة true، فهذا يعني أنه تم إجراء تعديل
        if (result == true && context.mounted) {
          context.read<TeacherCoursesCubit>().refresh();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: QuestionUI.glass(
          radius: 18,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18.r),
                    ),
                    child: course.image.isNotEmpty
                        ? Image.network(
                            course.image,
                            height: 120.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name.isNotEmpty ? course.name : 'Untitled Course',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        _infoChip(
                          Icons.low_priority_rounded,
                          'Order ${course.order}',
                          Colors.white70,
                        ),
                        _infoChip(
                          Icons.schedule_rounded,
                          '${course.estimatedDuration}h',
                          AppColors.sky,
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    height: 120.h,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.5),
          AppColors.dark.withOpacity(0.8),
        ],
      ),
    ),
    child: Icon(
      Icons.menu_book_rounded,
      color: Colors.white.withOpacity(0.3),
      size: 40.sp,
    ),
  );

  Widget _infoChip(IconData icon, String label, Color color) => Container(
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
        return 'In Prep';
      case 'draft':
        return 'Draft';
      case 'in_review':
        return 'Reviewing';
      case 'archived':
        return 'Archived';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.library_books_rounded,
          color: Colors.white.withOpacity(0.3),
          size: 64.sp,
        ),
        SizedBox(height: 14.h),
        Text(
          "No courses found",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          "Courses assigned to you will appear here",
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildError(String msg) => Center(
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
            onPressed: () => context.read<TeacherCoursesCubit>().refresh(),
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
