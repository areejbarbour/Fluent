// lib/presentation/screens/teacher/status_board/teacher_status_board_screen.dart
import 'dart:ui';
import 'package:fluent/presentation/widgets/app_snackbar.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/statuses/teacher_status_board_cubit.dart';
import 'package:fluent/cubit/teacher/statuses/teacher_status_board_state.dart';
import 'package:fluent/data/models/content_status.dart';
import 'package:fluent/utils/teacher_permissions.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart'; // ➕ جديد
import 'package:fluent/data/repository/test_repository.dart';
import 'package:fluent/helper/lessons/lesson_helpers.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:fluent/presentation/widgets/content_review_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherStatusBoardScreen extends StatefulWidget {
  const TeacherStatusBoardScreen({super.key});
  @override
  State<TeacherStatusBoardScreen> createState() =>
      _TeacherStatusBoardScreenState();
}

class _TeacherStatusBoardScreenState extends State<TeacherStatusBoardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _expandedCourseStatuses = {};
  final Set<String> _expandedLessonStatuses = {};
  final Set<String> _expandedTestStatuses = {}; // ➕ جديد

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // ➕ تم التغيير من 2 إلى 3
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ➕ دالة جديدة لجلب تفاصيل الاختبار قبل التعديل (نفس منطق شاشة الكورس)
  Future<void> _openTestForm(BuildContext context, TestModel test) async {
    TestModel? fullTest;

    // 1. جلب الاختبار الكامل مع الأسئلة من الباك إند
    final repo = context.read<TestRepository>();
    final result = await repo.getTestById(test.id);

    if (!context.mounted) return;

    if (result['success'] == true && result['data'] is TestModel) {
      fullTest = result['data'] as TestModel;
    } else {
      showAppSnackBar(
        context,
        result['message'] ?? 'Failed to load test details',
        type: AppSnackType.error,
      );
      return;
    }

    // 2. فتح شاشة التعديل مع الاختبار الكامل (الذي يحتوي الآن على الأسئلة)
    final editResult = await Navigator.pushNamed(
      context,
      testFormRoute,
      arguments: {
        'testableType': test.testableType.toLowerCase(),
        'testableId': test.testableId,
        'title': test.titleEn.isNotEmpty ? test.titleEn : test.titleAr,
        'initialTest': fullTest, // ✅ الآن يحتوي على الأسئلة
      },
    );

    // 3. تحديث لوحة الحالات بعد العودة في حال تم التعديل بنجاح
    if (editResult == true && context.mounted) {
      context.read<TeacherStatusBoardCubit>().refresh();
    }
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
                _buildTabs(),
                SizedBox(height: 12.h),
                Expanded(
                  child:
                      BlocBuilder<
                        TeacherStatusBoardCubit,
                        TeacherStatusBoardState
                      >(
                        builder: (context, state) {
                          if (state is TeacherStatusBoardLoading ||
                              state is TeacherStatusBoardInitial) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.yellow,
                              ),
                            );
                          }
                          if (state is TeacherStatusBoardFailure) {
                            return _buildError(state.error);
                          }
                          if (state is TeacherStatusBoardLoaded) {
                            return TabBarView(
                              controller: _tabController,
                              children: [
                                // 1. Courses Tab
                                _buildBoard<CourseModel>(
                                  grouped: state.coursesByStatus,
                                  total: state.totalCourses,
                                  expandedSet: _expandedCourseStatuses,
                                  emptyTitle: 'No courses yet',
                                  emptySubtitle:
                                      "Courses assigned to you will appear here",
                                  rowBuilder: _buildCourseRow,
                                  isCoursesTab: true,
                                ),
                                // 2. Lessons Tab
                                _buildBoard<LessonModel>(
                                  grouped: state.lessonsByStatus,
                                  total: state.totalLessons,
                                  expandedSet: _expandedLessonStatuses,
                                  emptyTitle: 'No lessons yet',
                                  emptySubtitle:
                                      "Lessons you create will appear here",
                                  rowBuilder: _buildLessonRow,
                                  isCoursesTab: false,
                                ),
                                // 3. Tests Tab ➕ جديد
                                _buildBoard<TestModel>(
                                  grouped: state.testsByStatus,
                                  total: state.totalTests,
                                  expandedSet: _expandedTestStatuses,
                                  emptyTitle: 'No tests yet',
                                  emptySubtitle:
                                      "Tests you create will appear here",
                                  rowBuilder: _buildTestRow,
                                  isCoursesTab:
                                      false, // Lessons & Tests: hide published/closed
                                ),
                              ],
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

  // =================== BACKGROUND & TOP BAR ===================
  Widget _buildBackground() => Stack(
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

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<TeacherStatusBoardCubit, TeacherStatusBoardState>(
            builder: (context, state) {
              if (state is TeacherStatusBoardLoaded) {
                String label;
                if (_tabController.index == 0)
                  label = "${state.totalCourses} courses";
                else if (_tabController.index == 1)
                  label = "${state.totalLessons} lessons";
                else
                  label = "${state.totalTests} tests"; // ➕ جديد

                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Row(
            children: [
              Tooltip(
                message: 'Questions Bank',
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, questionsListRoute),
                  child: Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.quiz_outlined,
                      color: AppColors.yellow,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Tooltip(
                message: 'My Courses',
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, teacherCoursesRoute),
                  child: Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.library_books_rounded,
                      color: AppColors.sky,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 18.w),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
              ),
              child: Icon(
                Icons.view_kanban_outlined,
                color: AppColors.yellow,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Status Board",
                  style: GoogleFonts.cinzelDecorative(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: AppColors.sky.withOpacity(0.7),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          "Track your courses, lessons, and tests",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10.sp,
          ),
        ),
      ],
    ),
  );

  // =================== TABS ===================
  Widget _buildTabs() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 18.w),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            indicator: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: EdgeInsets.all(3.r),
            labelColor: AppColors.dark,
            unselectedLabelColor: Colors.white.withOpacity(0.85),
            labelStyle: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.menu_book_outlined, size: 16),
                text: 'Courses',
              ),
              Tab(
                icon: Icon(Icons.play_lesson_outlined, size: 16),
                text: 'Lessons',
              ),
              Tab(
                icon: Icon(Icons.quiz_outlined, size: 16),
                text: 'Tests',
              ), // ➕ جديد
            ],
          ),
        ),
      ),
    ),
  );

  // =================== BOARD & SECTIONS ===================
  Widget _buildBoard<T>({
    required Map<String, List<T>> grouped,
    required int total,
    required Set<String> expandedSet,
    required String emptyTitle,
    required String emptySubtitle,
    required Widget Function(T item) rowBuilder,
    required bool isCoursesTab,
  }) {
    if (total == 0) return _buildEmpty(emptyTitle, emptySubtitle);

    // Courses: pending / published / archived / closed only
    // Lessons & Tests: hide published & closed (teacher workflow focuses on editable statuses)
    final statusesToShow = isCoursesTab
        ? ContentStatus.values
              .where(
                (s) => [
                  ContentStatus.pending.value,
                  ContentStatus.published.value,
                  ContentStatus.archived.value,
                  ContentStatus.closed.value,
                ].contains(s.value),
              )
              .toList()
        : ContentStatus.values
              .where(
                (s) =>
                    s != ContentStatus.published && s != ContentStatus.closed,
              )
              .toList();

    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: () => context.read<TeacherStatusBoardCubit>().refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        itemCount: statusesToShow.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final status = statusesToShow[index];
          final items = grouped[status.value] ?? const [];
          return _buildStatusSection<T>(
                status: status,
                items: items,
                expandedSet: expandedSet,
                rowBuilder: rowBuilder,
                isCoursesTab: isCoursesTab,
              )
              .animate()
              .fadeIn(duration: 350.ms, delay: (40 * index).ms)
              .moveY(begin: 16, end: 0, duration: 350.ms);
        },
      ),
    );
  }

  Widget _buildStatusSection<T>({
    required ContentStatus status,
    required List<T> items,
    required Set<String> expandedSet,
    required Widget Function(T item) rowBuilder,
    required bool isCoursesTab,
  }) {
    final color = StatusUI.statusColor(status.value);
    final isOpen = expandedSet.contains(status.value);
    final statusLabel = isCoursesTab ? status.courseLabel : status.lessonLabel;

    return QuestionUI.glass(
      radius: 18,
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: () => setState(() {
              if (isOpen)
                expandedSet.remove(status.value);
              else
                expandedSet.add(status.value);
            }),
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
                  child: Icon(
                    StatusUI.statusIcon(status.value),
                    color: color,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: color.withOpacity(0.45)),
                  ),
                  child: Text(
                    "${items.length}",
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
            duration: 220.ms,
            crossFadeState: isOpen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: items.isEmpty
                  ? _buildSectionEmpty()
                  : Column(
                      children: [
                        for (int i = 0; i < items.length; i++) ...[
                          if (i != 0) SizedBox(height: 6.h),
                          rowBuilder(items[i]),
                        ],
                      ],
                    ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionEmpty() => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.h),
    child: Text(
      "Nothing in this status",
      style: GoogleFonts.poppins(
        color: Colors.white.withOpacity(0.5),
        fontSize: 11.sp,
      ),
    ),
  );

  // =================== ROW BUILDERS ===================
  Widget _buildCourseRow(CourseModel course) {
    final color = StatusUI.statusColor(course.status);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        teacherCourseDetailRoute,
        arguments: course,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: course.image.isNotEmpty
                  ? Image.network(
                      course.image,
                      width: 36.w,
                      height: 36.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _courseImageFallback(color),
                    )
                  : _courseImageFallback(color),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name.isNotEmpty ? course.name : 'Untitled course',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  Wrap(
                    spacing: 5.w,
                    runSpacing: 3.h,
                    children: [
                      _miniChip(
                        icon: Icons.low_priority_rounded,
                        label: 'Order ${course.order}',
                        color: Colors.white70,
                      ),
                      _miniChip(
                        icon: Icons.schedule_rounded,
                        label: '${course.estimatedDuration}h',
                        color: AppColors.sky,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseImageFallback(Color color) => Container(
    width: 36.w,
    height: 36.w,
    color: color.withOpacity(0.2),
    child: Icon(Icons.menu_book_outlined, color: color, size: 18.sp),
  );

  Widget _buildLessonRow(LessonModel lesson) {
    final color = StatusUI.statusColor(lesson.status);

    // Backend ContentReviewService requires exactly one draft test linked
    // to the lesson before submit. Use the tests already loaded on the board.
    final boardState = context.read<TeacherStatusBoardCubit>().state;
    bool hasDraftTest = false;
    if (boardState is TeacherStatusBoardLoaded) {
      final draftCount = boardState.testsByStatus.values
          .expand((list) => list)
          .where(
            (t) =>
                t.isLessonTest &&
                t.testableId == lesson.id &&
                t.normalizedStatus == 'draft',
          )
          .length;
      // Exactly one draft test → allowed. Zero or more than one → blocked.
      hasDraftTest = draftCount == 1;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          lessonDetailRoute,
          arguments: {
            'lessonId': lesson.id,
            'lessonTitle': lesson.titleEn.isNotEmpty
                ? lesson.titleEn
                : lesson.titleAr,
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 5.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.titleEn.isNotEmpty ? lesson.titleEn : lesson.titleAr,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  Wrap(
                    spacing: 5.w,
                    runSpacing: 3.h,
                    children: [
                      if (lesson.courseName != null &&
                          lesson.courseName!.isNotEmpty)
                        _miniChip(
                          icon: Icons.menu_book_outlined,
                          label: lesson.courseName!,
                          color: AppColors.sky,
                        ),
                      _miniChip(
                        icon: Icons.low_priority_rounded,
                        label: 'Order ${lesson.order}',
                        color: Colors.white70,
                      ),
                      _miniChip(
                        icon: Icons.star_rounded,
                        label: '${lesson.xpPoints} XP',
                        color: AppColors.yellow,
                      ),
                    ],
                  ),
                  // Last review note (backend sends review_notes when changes_requested)
                  if (lesson.reviewNotes.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 11.sp,
                          color: Colors.orange.shade300,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            lesson.reviewNotes.first,
                            style: GoogleFonts.poppins(
                              color: Colors.orange.shade200,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Content Review compact actions (Submit / Resubmit / History)
            ContentReviewActionsBar(
              status: lesson.status,
              targetId: lesson.id,
              isLesson: true,
              compact: true,
              hasVideo: (lesson.videoUrl ?? '').trim().isNotEmpty,
              // Matches backend: exactly one draft test required for submit
              hasDraftTest: hasDraftTest,
              onSuccess: () {
                context.read<TeacherStatusBoardCubit>().loadAll();
              },
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  // ➕ دالة بناء صف الاختبار — بنفس روح الكورسات والدروس
  Widget _buildTestRow(TestModel test) {
    final color = StatusUI.statusColor(test.status);
    final statusLabel = StatusUI.statusLabel(test.status);
    final isCourseTest = test.testableType.toLowerCase() == 'course';
    final targetLabel = isCourseTest
        ? 'Course #${test.testableId}'
        : 'Lesson #${test.testableId}';
    final typeLabel = isCourseTest ? 'Course Test' : 'Lesson Test';
    final canEdit = TeacherPermissions.canEditTest(test.status);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          testDetailViewRoute,
          arguments: {'testId': test.id},
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          test.titleEn.isNotEmpty ? test.titleEn : test.titleAr,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _statusChip(label: statusLabel, color: color),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    targetLabel,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 5.w,
                    runSpacing: 3.h,
                    children: [
                      _miniChip(
                        icon: isCourseTest
                            ? Icons.menu_book_outlined
                            : Icons.play_lesson_outlined,
                        label: typeLabel,
                        color: AppColors.sky,
                      ),
                      _miniChip(
                        icon: Icons.check_circle_outline,
                        label: 'Pass ${test.passingScore}%',
                        color: AppColors.yellow,
                      ),
                    ],
                  ),
                  if (canEdit) ...[
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        // ✅ تم التعديل هنا لاستدعاء الدالة الجديدة
                        onTap: () => _openTestForm(context, test),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sky.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.sky.withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 12.sp,
                                color: AppColors.sky,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Edit',
                                style: GoogleFonts.poppins(
                                  color: AppColors.sky,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Content Review compact actions
            ContentReviewActionsBar(
              status: test.status,
              targetId: test.id,
              isLesson: false,
              compact: true,
              onSuccess: () {
                context.read<TeacherStatusBoardCubit>().loadAll();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip({required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =================== HELPERS ===================
  Widget _miniChip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 11.sp),
            SizedBox(width: 3.w),
          ],
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.view_kanban_outlined,
              color: Colors.white.withOpacity(0.5),
              size: 56.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
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

  Widget _buildError(String msg) {
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
                  context.read<TeacherStatusBoardCubit>().refresh(),
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
