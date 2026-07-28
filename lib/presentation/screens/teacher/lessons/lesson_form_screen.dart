import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_cubit.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_state.dart';
import 'package:fluent/cubit/teacher/courses/form/lesson_form_cubit.dart';
import 'package:fluent/cubit/teacher/courses/form/lesson_form_state.dart';
import 'package:fluent/cubit/teacher/tests/delete/test_delete_cubit.dart';
import 'package:fluent/cubit/teacher/tests/delete/test_delete_state.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'package:fluent/helper/lessons/lesson_helpers.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

final RegExp enRegex = RegExp(r'^[a-zA-Z0-9\s.,!?;:()"\u0027-]+$');
final RegExp arRegex = RegExp(
  r'^[\u0600-\u06FF0-9\s،؟؛:()«»"\u0027!,-]+$',
  unicode: true,
);

class LessonFormScreen extends StatefulWidget {
  final int? courseId;
  final LessonModel? lesson;
  final String? courseStatus;

  const LessonFormScreen({
    super.key,
    this.courseId,
    this.lesson,
    this.courseStatus,
  });

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleEnCtrl,
      _titleArCtrl,
      _orderCtrl,
      _xpCtrl;
  PlatformFile? _selectedVideo;

  List<TestModel> _lessonTests = [];
  bool _isLoadingTest = false;

  String? _currentVideoUrl;
  int _commentsCount = 0;
  bool _isLoadingDetails = false;

  bool get isEditMode => widget.lesson != null;

  /// حالة الدرس الفعلية (مش الكورس)
  String get _lessonStatus => (widget.lesson?.status ?? '').toLowerCase();

  /// إنشاء درس جديد: فقط إذا الكورس pending
  bool get canCreateLesson {
    if (isEditMode) return true;
    return (widget.courseStatus ?? '').toLowerCase() == 'pending';
  }

  /// تعديل كامل ممنوع حسب حالة الدرس
  bool get isRestrictedEdit {
    if (!isEditMode) return !canCreateLesson;
    const blocked = {'closed', 'archived', 'approved', 'in_review'};
    return blocked.contains(_lessonStatus);
  }

  /// درس منشور → order + video مقفولين
  bool get isPublishedEdit => isEditMode && _lessonStatus == 'published';

  /// حذف حسب حالة الدرس فقط
  bool get canDelete {
    if (!isEditMode) return false;
    const deletable = {'draft', 'pending', 'changes_requested'};
    return deletable.contains(_lessonStatus);
  }

  @override
  void initState() {
    super.initState();
    _titleEnCtrl = TextEditingController(text: widget.lesson?.titleEn ?? '');
    _titleArCtrl = TextEditingController(text: widget.lesson?.titleAr ?? '');
    _orderCtrl = TextEditingController(
      text: widget.lesson?.order.toString() ?? '1',
    );
    _xpCtrl = TextEditingController(
      text: widget.lesson?.xpPoints.toString() ?? '20',
    );

    if (isEditMode && widget.lesson != null) {
      _fetchLessonDetails();
      _fetchLessonTests();
    }
  }

  Future<void> _fetchLessonDetails() async {
    if (widget.lesson == null) return;

    setState(() => _isLoadingDetails = true);
    try {
      final lessonRepo = context.read<LessonRepository>();
      final result = await lessonRepo.getLessonDetails(widget.lesson!.id);

      if (!mounted) return;

      if (result['success'] == true) {
        final lessonJson = result['lesson'];
        final comments = result['comments'];

        String? video;
        if (lessonJson is Map) {
          final v = lessonJson['video']?.toString();
          if (v != null && v.trim().isNotEmpty) video = v;

          final en = lessonJson['title_en']?.toString();
          final ar = lessonJson['title_ar']?.toString();
          final order = lessonJson['order'];
          final xp = lessonJson['xp_points'];

          if (en != null && en.isNotEmpty) _titleEnCtrl.text = en;
          if (ar != null && ar.isNotEmpty) _titleArCtrl.text = ar;
          if (order != null) _orderCtrl.text = order.toString();
          if (xp != null) _xpCtrl.text = xp.toString();
        }

        setState(() {
          _currentVideoUrl = video;
          _commentsCount = comments is List ? comments.length : 0;
          _isLoadingDetails = false;
        });
      } else {
        setState(() => _isLoadingDetails = false);
      }
    } catch (e) {
      print('_fetchLessonDetails error: $e');
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _fetchLessonTests() async {
    if (widget.lesson == null) {
      setState(() {
        _lessonTests = [];
        _isLoadingTest = false;
      });
      return;
    }

    setState(() => _isLoadingTest = true);
    try {
      final testRepo = context.read<TestRepository>();
      final result = await testRepo.getAllTests();

      if (!mounted) return;

      if (result['success'] == true) {
        final all = result['data'] as List<TestModel>;
        final matches = all
            .where(
              (t) =>
                  t.testableType.toLowerCase() == 'lesson' &&
                  t.testableId == widget.lesson!.id,
            )
            .toList();
        setState(() {
          _lessonTests = matches;
          _isLoadingTest = false;
        });
      } else {
        setState(() {
          _lessonTests = [];
          _isLoadingTest = false;
        });
      }
    } catch (e, stack) {
      print('_fetchLessonTests error: $e');
      print('stack: $stack');
      if (mounted) {
        setState(() {
          _lessonTests = [];
          _isLoadingTest = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleArCtrl.dispose();
    _orderCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 150 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video size must not exceed 150MB'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() => _selectedVideo = file);
    }
  }

  void _submit(BuildContext context) async {
    if (isRestrictedEdit && !isPublishedEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This lesson cannot be modified in its current status'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (!isEditMode && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final orderValue = int.tryParse(_orderCtrl.text) ?? 1;
    final xpValue = int.tryParse(_xpCtrl.text) ?? 20;

    final formData = FormData.fromMap({
      'title_en': _titleEnCtrl.text.trim(),
      'title_ar': _titleArCtrl.text.trim(),
      'order': orderValue,
      'xp_points': xpValue,
    });

    if (_selectedVideo != null && _selectedVideo!.path != null) {
      formData.files.add(
        MapEntry(
          'video',
          await MultipartFile.fromFile(
            _selectedVideo!.path!,
            filename: _selectedVideo!.name,
          ),
        ),
      );
    }

    if (isEditMode) {
      context.read<LessonFormCubit>().updateLesson(widget.lesson!.id, formData);
    } else {
      context.read<LessonFormCubit>().createLesson(widget.courseId!, formData);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: Text(
          'Delete Lesson?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete the lesson with all its tests and details. This cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LessonDeleteCubit>().deleteLesson(widget.lesson!.id);
            },
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
  }

  // 📁 lib/presentation/screens/teacher/lessons/lesson_form_screen.dart

  // ❌ احذف الدالة القديمة واستبدلها بهذه:

  Future<void> _openEditTest(TestModel test) async {
    // ✅ 1. عرض مؤشر تحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      ),
    );

    try {
      // ✅ 2. جلب الاختبار الكامل مع الأسئلة من الباك إند
      final repo = context.read<TestRepository>();
      final result = await repo.getTestById(test.id);

      // ✅ 3. إغلاق مؤشر التحميل
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      if (result['success'] == true && result['data'] is TestModel) {
        final fullTest = result['data'] as TestModel;

        // ✅ 4. فتح شاشة التعديل مع الاختبار الكامل
        final editResult = await Navigator.pushNamed(
          context,
          testFormRoute,
          arguments: {
            'testableType': 'lesson',
            'testableId': widget.lesson!.id,
            'title': widget.lesson!.titleEn.isNotEmpty
                ? widget.lesson!.titleEn
                : widget.lesson!.titleAr,
            'initialTest': fullTest, // ✅ الآن يحتوي على الأسئلة
          },
        );

        // ✅ 5. تحديث قائمة الاختبارات بعد العودة
        if (editResult == true && mounted) {
          _fetchLessonTests();
        }
      } else {
        // ❌ عرض رسالة خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load test details'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // ✅ إغلاق مؤشر التحميل في حالة الخطأ
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openCreateTest() {
    Navigator.pushNamed(
      context,
      testFormRoute,
      arguments: {
        'testableType': 'lesson',
        'testableId': widget.lesson!.id,
        'title': widget.lesson!.titleEn.isNotEmpty
            ? widget.lesson!.titleEn
            : widget.lesson!.titleAr,
      },
    ).then((_) {
      if (mounted) _fetchLessonTests();
    });
  }

  void _confirmDeleteTest(TestModel test) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: Text(
          'Delete Test?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Delete "${test.titleEn.isNotEmpty ? test.titleEn : test.titleAr}"?\nThis cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TestDeleteCubit>().deleteTest(test.id);
            },
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
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LessonFormCubit, LessonFormState>(
          listener: (context, state) {
            if (state is LessonFormSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditMode
                        ? 'Lesson updated successfully'
                        : 'Lesson created successfully',
                  ),
                  backgroundColor: Colors.greenAccent,
                ),
              );
              Navigator.pop(context, true);
            }
            if (state is LessonFormFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
        BlocListener<LessonDeleteCubit, LessonDeleteState>(
          listener: (context, state) {
            if (state is LessonDeleteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.greenAccent,
                ),
              );
              Navigator.pop(context, true);
            }
            if (state is LessonDeleteFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
        BlocListener<TestDeleteCubit, TestDeleteState>(
          listener: (context, state) {
            if (state is TestDeleteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.greenAccent,
                ),
              );
              _fetchLessonTests();
            }
            if (state is TestDeleteFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
      ],
      child: _FormView(
        formKey: _formKey,
        titleEnCtrl: _titleEnCtrl,
        titleArCtrl: _titleArCtrl,
        orderCtrl: _orderCtrl,
        xpCtrl: _xpCtrl,
        selectedVideo: _selectedVideo,
        currentVideoUrl: _currentVideoUrl,
        commentsCount: _commentsCount,
        isLoadingDetails: _isLoadingDetails,
        isEditMode: isEditMode,
        isRestrictedEdit: isRestrictedEdit,
        isPublishedEdit: isPublishedEdit,
        canDelete: canDelete,
        lesson: widget.lesson,
        lessonTests: _lessonTests,
        isLoadingTest: _isLoadingTest,
        onPickVideo: _pickVideo,
        onSubmit: () => _submit(context),
        onDelete: () => _confirmDelete(context),
        onEditTest: _openEditTest,
        onCreateTest: _openCreateTest,
        onDeleteTest: _confirmDeleteTest,
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Form View
// ═══════════════════════════════════════════════

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleEnCtrl, titleArCtrl, orderCtrl, xpCtrl;
  final PlatformFile? selectedVideo;
  final String? currentVideoUrl;
  final int commentsCount;
  final bool isLoadingDetails;
  final bool isEditMode;
  final bool isRestrictedEdit;
  final bool isPublishedEdit;
  final bool canDelete;
  final LessonModel? lesson;
  final List<TestModel> lessonTests;
  final bool isLoadingTest;
  final VoidCallback onPickVideo, onSubmit, onDelete;
  final void Function(TestModel test)? onEditTest;
  final VoidCallback? onCreateTest;
  final void Function(TestModel test)? onDeleteTest;

  const _FormView({
    required this.formKey,
    required this.titleEnCtrl,
    required this.titleArCtrl,
    required this.orderCtrl,
    required this.xpCtrl,
    required this.selectedVideo,
    this.currentVideoUrl,
    this.commentsCount = 0,
    this.isLoadingDetails = false,
    required this.isEditMode,
    required this.isRestrictedEdit,
    required this.isPublishedEdit,
    required this.canDelete,
    required this.lesson,
    required this.lessonTests,
    required this.isLoadingTest,
    required this.onPickVideo,
    required this.onSubmit,
    required this.onDelete,
    this.onEditTest,
    this.onCreateTest,
    this.onDeleteTest,
  });

  @override
  Widget build(BuildContext context) {
    final fieldsEnabled = !isRestrictedEdit || isPublishedEdit;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                _buildTopBar(context),
                SizedBox(height: 12.h),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isRestrictedEdit && !isPublishedEdit) ...[
                            _buildRestrictedBanner(),
                            SizedBox(height: 12.h),
                          ],
                          _buildTextField(
                            titleEnCtrl,
                            'Title (English)',
                            Icons.translate,
                            isArabic: false,
                            isEnabled: fieldsEnabled,
                          ),
                          SizedBox(height: 10.h),
                          _buildTextField(
                            titleArCtrl,
                            'Title (Arabic)',
                            Icons.translate,
                            isArabic: true,
                            isEnabled: fieldsEnabled,
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  orderCtrl,
                                  'Order',
                                  Icons.format_list_numbered,
                                  isNum: true,
                                  isEnabled: fieldsEnabled && !isPublishedEdit,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildTextField(
                                  xpCtrl,
                                  'XP Points',
                                  Icons.star_rounded,
                                  isNum: true,
                                  isEnabled: fieldsEnabled,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _buildVideoPicker(
                            context,
                            isEnabled: fieldsEnabled && !isPublishedEdit,
                          ),
                          if (isEditMode && commentsCount > 0) ...[
                            SizedBox(height: 10.h),
                            QuestionUI.glass(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    color: AppColors.sky,
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '$commentsCount comment${commentsCount == 1 ? '' : 's'}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (fieldsEnabled) ...[
                            SizedBox(height: 24.h),
                            _buildSubmitButton(context),
                          ],
                          if (isEditMode) ...[
                            SizedBox(height: 20.h),
                            _buildTestSection(context),
                          ],
                          if (isEditMode && canDelete) ...[
                            SizedBox(height: 16.h),
                            _buildDeleteButton(context),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedBanner() {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      borderColor: Colors.redAccent.withOpacity(0.4),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.redAccent, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'This lesson is in a restricted status and cannot be modified.',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(BuildContext context) {
    return QuestionUI.glass(
      padding: EdgeInsets.all(14.w),
      borderColor: AppColors.sky.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.sky, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Lesson Tests (${lessonTests.length})',
                  style: GoogleFonts.poppins(
                    color: AppColors.sky,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (isLoadingTest)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: const CircularProgressIndicator(color: AppColors.yellow),
              ),
            )
          else if (lessonTests.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'No tests yet for this lesson',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
            )
          else
            ...lessonTests.map((test) {
              // ✅ حالة الاختبار فقط
              final canEdit = test.canEdit;
              final canDel = test.canDelete;

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.sky.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.titleEn.isNotEmpty ? test.titleEn : test.titleAr,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        _testChip(
                          icon: Icons.check_circle_outline,
                          label: 'Pass: ${test.passingScore}%',
                          color: AppColors.yellow,
                        ),
                        _testChip(
                          icon: Icons.info_outline,
                          label: test.status.toUpperCase(),
                          color: StatusUI.statusColor(test.status),
                        ),
                      ],
                    ),
                    if (canEdit || canDel) ...[
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          if (canEdit && onEditTest != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => onEditTest!(test),
                                icon: Icon(Icons.edit, size: 14.sp),
                                label: Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.sky.withOpacity(
                                    0.2,
                                  ),
                                  foregroundColor: AppColors.sky,
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ),
                            ),
                          if (canEdit && canDel) SizedBox(width: 8.w),
                          if (canDel && onDeleteTest != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => onDeleteTest!(test),
                                icon: Icon(Icons.delete_outline, size: 14.sp),
                                label: Text(
                                  'Delete',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withOpacity(
                                    0.2,
                                  ),
                                  foregroundColor: Colors.redAccent,
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          // Add Test: مسموح طالما الدرس مش restricted بالكامل
          if (!isRestrictedEdit || isPublishedEdit) ...[
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCreateTest,
                icon: Icon(Icons.add, size: 18.sp),
                label: Text(
                  'Add Test',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sky.withOpacity(0.2),
                  foregroundColor: AppColors.sky,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _testChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.4)),
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
              fontWeight: FontWeight.w700,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
            ),
            child: const Icon(
              Icons.play_lesson_rounded,
              color: AppColors.yellow,
              size: 20,
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isEditMode ? 'Edit Lesson' : 'New Lesson',
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontSize: 18.sp,
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
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isArabic = false,
    bool isNum = false,
    bool isEnabled = true,
  }) {
    return QuestionUI.glass(
      radius: 12,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: TextFormField(
        controller: ctrl,
        enabled: isEnabled,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        inputFormatters: isNum
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        style: GoogleFonts.poppins(
          color: isEnabled ? Colors.white : Colors.white54,
          fontSize: 13.sp,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12.sp,
          ),
          prefixIcon: Icon(icon, color: AppColors.yellow, size: 18.sp),
          border: InputBorder.none,
        ),
        validator: (v) {
          if (!isEnabled) return null;
          if (v == null || v.isEmpty) return 'Required';
          if (label.contains('English') && !enRegex.hasMatch(v)) {
            return 'Only English letters, numbers, spaces allowed';
          }
          if (label.contains('Arabic') && !arRegex.hasMatch(v)) {
            return 'Only Arabic letters, numbers, spaces allowed';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildVideoPicker(BuildContext context, {bool isEnabled = true}) {
    final hasExistingVideo =
        currentVideoUrl != null && currentVideoUrl!.isNotEmpty;
    final hasNewVideo = selectedVideo != null;

    return QuestionUI.glass(
      radius: 14,
      borderColor: isEnabled
          ? AppColors.sky.withOpacity(0.4)
          : Colors.white.withOpacity(0.1),
      child: GestureDetector(
        onTap: isEnabled ? onPickVideo : null,
        child: Container(
          padding: EdgeInsets.all(14.w),
          child: Column(
            children: [
              if (isLoadingDetails)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                      color: AppColors.sky,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.video_library_rounded,
                  color: isEnabled ? AppColors.sky : Colors.white54,
                  size: 28.sp,
                ),
              SizedBox(height: 6.h),
              Text(
                hasNewVideo
                    ? selectedVideo!.name
                    : hasExistingVideo
                    ? 'Current video attached'
                    : (isEnabled
                          ? 'Tap to select video file'
                          : 'Video cannot be changed'),
                style: GoogleFonts.poppins(
                  color: isEnabled ? Colors.white : Colors.white54,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasNewVideo) ...[
                SizedBox(height: 4.h),
                Text(
                  '${(selectedVideo!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 10.sp,
                  ),
                ),
              ] else if (hasExistingVideo) ...[
                SizedBox(height: 4.h),
                Text(
                  currentVideoUrl!,
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 9.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<LessonFormCubit, LessonFormState>(
      builder: (context, state) {
        final isLoading = state is LessonFormLoading;
        return GestureDetector(
          onTap: isLoading ? null : onSubmit,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.yellow, AppColors.orange],
              ),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        color: AppColors.dark,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      isEditMode ? 'Update Lesson' : 'Create Lesson',
                      style: GoogleFonts.poppins(
                        color: AppColors.dark,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return BlocBuilder<LessonDeleteCubit, LessonDeleteState>(
      builder: (context, state) {
        final isDeleting = state is LessonDeleteLoading;
        return GestureDetector(
          onTap: isDeleting ? null : onDelete,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            ),
            child: Center(
              child: isDeleting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        color: Colors.redAccent,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Delete Lesson',
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
