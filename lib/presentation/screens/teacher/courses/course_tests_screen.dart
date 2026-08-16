import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/presentation/widgets/app_snackbar.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/tests/delete/test_delete_cubit.dart';
import 'package:fluent/cubit/teacher/tests/delete/test_delete_state.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// شاشة عرض و إدارة اختبارات الكورس
/// تصميم شبيه بشاشة تفاصيل الدرس للاختبارات
class CourseTestsScreen extends StatefulWidget {
  final CourseModel course;

  const CourseTestsScreen({super.key, required this.course});

  @override
  State<CourseTestsScreen> createState() => _CourseTestsScreenState();
}

class _CourseTestsScreenState extends State<CourseTestsScreen> {
  List<TestModel> _tests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<TestRepository>();
      final result = await repo.getAllTests();

      if (!mounted) return;

      if (result['success'] == true) {
        final allTests = result['data'] as List<TestModel>;
        final courseTests = allTests
            .where(
              (t) =>
                  t.testableType.toLowerCase() == 'course' &&
                  t.testableId == widget.course.id,
            )
            .toList();

        setState(() {
          _tests = courseTests;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Failed to load tests';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TestDeleteCubit, TestDeleteState>(
      listener: (context, state) {
        if (state is TestDeleteSuccess) {
          showAppSnackBar(context, state.message, type: AppSnackType.success);
          _loadTests();
        }
        if (state is TestDeleteFailure) {
          showAppSnackBar(context, state.error, type: AppSnackType.error);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  _buildTopBar(context),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(context),
      ),
    );
  }

  // ─── Background ───
  Widget _buildBackground() => Stack(
    children: [
      Container(decoration: QuestionUI.backgroundGradient()),
      Positioned(
        top: -120.h,
        right: -100.w,
        child: QuestionUI.glowingCircle(AppColors.orange, 320.w)
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
        child: QuestionUI.glowingCircle(AppColors.yellow, 380.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(20, -15),
              duration: 6000.ms,
            ),
      ),
    ],
  );

  // ─── Top Bar ───
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.orange.withOpacity(0.5)),
            ),
            child: const Icon(
              Icons.quiz_rounded,
              color: AppColors.orange,
              size: 22,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Tests',
                  style: GoogleFonts.cinzelDecorative(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: AppColors.orange.withOpacity(0.7),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.course.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 11.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.orange.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz_outlined, color: AppColors.orange, size: 14.sp),
                SizedBox(width: 4.w),
                Text(
                  '${_tests.length}',
                  style: GoogleFonts.poppins(
                    color: AppColors.orange,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ───
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_tests.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: _loadTests,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
        itemCount: _tests.length,
        itemBuilder: (context, index) =>
            _buildTestCard(context, _tests[index], index),
      ),
    );
  }

  // ─── Test Card ───
  Widget _buildTestCard(BuildContext context, TestModel test, int index) {
    final statusColor = _statusColor(test.status);

    return GestureDetector(
      onTap: () => _showTestDetailSheet(context, test),
      child:
          Container(
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: statusColor.withOpacity(0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.quiz_outlined,
                            color: statusColor,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                test.titleEn.isNotEmpty
                                    ? test.titleEn
                                    : test.titleAr,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (test.titleAr.isNotEmpty &&
                                  test.titleEn.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  test.titleAr,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        _statusBadge(test.status, statusColor),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // Info chips — only passing score (type is implied by this screen)
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _miniChip(
                          Icons.check_circle_outline,
                          'Pass ${test.passingScore}%',
                          AppColors.yellow,
                        ),
                      ],
                    ),

                    // Action buttons
                    if (test.canEdit || test.canDelete) ...[
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          if (test.canEdit)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openTestForm(context, test),
                                icon: Icon(Icons.edit_rounded, size: 16.sp),
                                label: Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.sky.withOpacity(
                                    0.2,
                                  ),
                                  foregroundColor: AppColors.sky,
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ),
                            ),
                          if (test.canEdit && test.canDelete)
                            SizedBox(width: 10.w),
                          if (test.canDelete)
                            Expanded(
                              child: BlocBuilder<TestDeleteCubit, TestDeleteState>(
                                builder: (context, state) {
                                  final loading = state is TestDeleteLoading;
                                  return ElevatedButton.icon(
                                    onPressed: loading
                                        ? null
                                        : () => _confirmDelete(context, test),
                                    icon: loading
                                        ? SizedBox(
                                            width: 14.w,
                                            height: 14.w,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.redAccent,
                                                ),
                                          )
                                        : Icon(
                                            Icons.delete_outline,
                                            size: 16.sp,
                                          ),
                                    label: Text(
                                      'Delete',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent
                                          .withOpacity(0.2),
                                      foregroundColor: Colors.redAccent,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10.h,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: (80 * index).ms)
              .moveY(begin: 20, end: 0, duration: 400.ms),
    );
  }

  // ─── FAB ───
  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openTestForm(context, null),
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      icon: Icon(Icons.add_rounded, size: 20.sp),
      label: Text(
        'Add Test',
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─── Empty State ───
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.quiz_outlined,
                color: AppColors.orange,
                size: 40.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No Course Tests Yet',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Create your first test to assess\nstudent knowledge',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _openTestForm(context, null),
              icon: Icon(Icons.add_rounded, size: 18.sp),
              label: Text(
                'Create Test',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ───
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _loadTests,
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

  // ─── Test Detail Sheet ───
  void _showTestDetailSheet(BuildContext context, TestModel test) {
    Navigator.pushNamed(
      context,
      testDetailViewRoute,
      arguments: {'testId': test.id},
    );
  }

  // ─── Open Test Form ───
  Future<void> _openTestForm(BuildContext context, TestModel? existing) async {
    TestModel? fullTest;

    if (existing != null) {
      final repo = context.read<TestRepository>();
      final result = await repo.getTestById(existing.id);
      if (result['success'] == true && result['data'] is TestModel) {
        fullTest = result['data'] as TestModel;
      } else {
        if (context.mounted) {
          showAppSnackBar(context, result['message'] ?? 'Failed to load test', type: AppSnackType.error);
        }
        return;
      }
    }

    final result = await Navigator.pushNamed(
      context,
      testFormRoute,
      arguments: {
        'testableType': 'course',
        'testableId': widget.course.id,
        'title': widget.course.name,
        if (fullTest != null) 'initialTest': fullTest,
      },
    );

    if (result == true && mounted) {
      _loadTests();
    }
  }

  // ─── Confirm Delete ───
  Future<void> _confirmDelete(BuildContext context, TestModel test) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Delete Test?',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              test.titleEn.isNotEmpty ? test.titleEn : test.titleAr,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'This action cannot be undone. All questions in this test will be permanently removed.',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
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

    if (confirmed != true || !context.mounted) return;

    context.read<TestDeleteCubit>().deleteTest(test.id);
  }

  // ─── Helpers ───
  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
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
        return Colors.tealAccent;
      case 'archived':
        return Colors.purpleAccent;
      case 'closed':
        return Colors.blueGrey;
      default:
        return Colors.white54;
    }
  }
}
