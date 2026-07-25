import 'package:dio/dio.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/teacher/questions/question_filter/question_filter_cubit.dart';
import 'package:fluent/cubit/teacher/questions/question_filter/question_filter_state.dart';
import 'package:fluent/cubit/teacher/tests/create/test_create_cubit.dart';
import 'package:fluent/cubit/teacher/tests/create/test_create_state.dart';
import 'package:fluent/cubit/teacher/tests/update/test_update_cubit.dart';
import 'package:fluent/cubit/teacher/tests/update/test_update_state.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:fluent/presentation/screens/teacher/questions/question_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

final RegExp enRegex = RegExp(r'^[a-zA-Z0-9\s.,!?;:()"\u0027-]+$');
final RegExp arRegex = RegExp(
  r'^[\u0600-\u06FF0-9\s،؟؛:()«»"\u0027!,-]+$',
  unicode: true,
);

class TestFormScreen extends StatefulWidget {
  final String testableType;
  final int testableId;
  final String title;
  final TestModel? initialTest; // ✅ جديد: لدعم وضع التعديل

  const TestFormScreen({
    super.key,
    required this.testableType,
    required this.testableId,
    required this.title,
    this.initialTest,
  });

  @override
  State<TestFormScreen> createState() => _TestFormScreenState();
}

class _TestFormScreenState extends State<TestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleEnCtrl = TextEditingController();
  final _titleArCtrl = TextEditingController();
  final _passingScoreCtrl = TextEditingController(text: '50');

  List<Question> _selectedQuestions = [];
  bool get isEditMode => widget.initialTest != null;

  @override
  void initState() {
    super.initState();
    // ✅ ملء البيانات تلقائياً إذا كنا في وضع التعديل
    if (isEditMode && widget.initialTest != null) {
      _titleEnCtrl.text = widget.initialTest!.titleEn;
      _titleArCtrl.text = widget.initialTest!.titleAr;
      _passingScoreCtrl.text = widget.initialTest!.passingScore.toString();
      _selectedQuestions = List.from(widget.initialTest!.questions);
    }
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleArCtrl.dispose();
    _passingScoreCtrl.dispose();
    super.dispose();
  }

  int get _totalScore => _selectedQuestions.fold(0, (sum, q) => sum + q.score);

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestions.length < 2) {
      _showSnackBar('You must select at least 2 questions', Colors.redAccent);
      return;
    }

    // ✅ تحذيرات ما قبل الإرسال بناءً على حالة الاختبار (Update Conditions)
    if (isEditMode && widget.initialTest != null) {
      final status = widget.initialTest!.status.toLowerCase();
      if (status == 'published') {
        _showVersioningWarning(context, 'published');
        return;
      } else if (status == 'approved') {
        _showVersioningWarning(context, 'approved');
        return;
      }
    }

    _performSubmit(context);
  }

  // ✅ دالة جديدة لعرض التحذيرات الذكية
  void _showVersioningWarning(BuildContext context, String status) {
    final message = status == 'published'
        ? 'This test is PUBLISHED. Editing it will create a completely new version, and the old version will be saved as a previous version.'
        : 'This test is APPROVED. Saving changes will automatically revert its status to CHANGES_REQUESTED.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.orange,
              size: 24,
            ),
            SizedBox(width: 8.w),
            Text(
              'Action Warning',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          message,
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
              _performSubmit(context);
            },
            child: Text(
              'Proceed',
              style: GoogleFonts.poppins(
                color: AppColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ دالة جديدة لتنفيذ الإرسال الفعلي
  void _performSubmit(BuildContext context) {
    final formData = FormData.fromMap({
      'testable_type': widget.testableType,
      'testable_id': widget.testableId,
      'title_en': _titleEnCtrl.text.trim(),
      'title_ar': _titleArCtrl.text.trim(),
      'passing_score': int.parse(_passingScoreCtrl.text.trim()),
    });

    // ✅ ضمان الترتيب التسلسلي (Sequential Order) يبدأ من 1
    for (int i = 0; i < _selectedQuestions.length; i++) {
      formData.fields.add(
        MapEntry('questions[$i][id]', _selectedQuestions[i].id.toString()),
      );
      formData.fields.add(MapEntry('questions[$i][order]', (i + 1).toString()));
    }

    if (isEditMode) {
      context.read<TestUpdateCubit>().updateTest(
        widget.initialTest!.id,
        formData,
      );
    } else {
      context.read<TestCreateCubit>().createTest(formData);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openQuestionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider(
        create: (_) => QuestionFilterCubit(context.read<QuestionRepository>())
          ..applyFilters(
            courseId: widget.testableType == 'course'
                ? widget.testableId
                : null,
            onlyEligible: widget.testableType == 'course' ? true : null,
          ),
        child: _QuestionPickerSheet(
          selectedQuestions: _selectedQuestions,
          isCourseTest: widget.testableType == 'course',
          courseId: widget.testableType == 'course' ? widget.testableId : null,
          onConfirm: (selected) {
            setState(() => _selectedQuestions = selected);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TestCreateCubit(context.read())),
        BlocProvider(create: (_) => TestUpdateCubit(context.read())), // ✅ جديد
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TestCreateCubit, TestCreateState>(
            listener: (context, state) {
              if (state is TestCreateSuccess) {
                _showSnackBar('Test created successfully!', Colors.greenAccent);
                Navigator.pop(context, true);
              } else if (state is TestCreateFailure) {
                _showError(state.error, state.errors);
              }
            },
          ),
          BlocListener<TestUpdateCubit, TestUpdateState>(
            listener: (context, state) {
              if (state is TestUpdateSuccess) {
                _showSnackBar(state.message, Colors.greenAccent);
                Navigator.pop(context, true);
              } else if (state is TestUpdateFailure) {
                _showError(state.error, state.errors);
              }
            },
          ),
        ],
        child: _buildUI(context),
      ),
    );
  }

  void _showError(String msg, Map<String, dynamic>? errors) {
    String errorMsg = msg;
    if (errors != null && errors.isNotEmpty) {
      errorMsg += '\n\nDetails:\n';
      errors.forEach((key, value) {
        errorMsg += '- $key: ${(value is List ? value.join(', ') : value)}\n';
      });
    }
    _showSnackBar(errorMsg, Colors.redAccent);
  }

  Widget _buildUI(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: QuestionUI.backgroundGradient()),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                _buildTopBar(),
                SizedBox(height: 12.h),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(),
                          SizedBox(height: 16.h),
                          _buildTextField(
                            _titleEnCtrl,
                            'Title (English)',
                            isArabic: false,
                          ),
                          SizedBox(height: 12.h),
                          _buildTextField(
                            _titleArCtrl,
                            'Title (Arabic)',
                            isArabic: true,
                          ),
                          SizedBox(height: 12.h),
                          _buildTextField(
                            _passingScoreCtrl,
                            'Passing Score (10-100)',
                            isNum: true,
                          ),
                          SizedBox(height: 20.h),
                          _buildSmartSummaryCard(),
                          SizedBox(height: 20.h),
                          _buildQuestionsSection(context),
                          SizedBox(height: 30.h),
                          _buildSubmitButton(context),
                          SizedBox(height: 30.h),
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

  Widget _buildTopBar() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
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
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isEditMode
                  ? "Edit Test"
                  : "New ${widget.testableType == 'course' ? 'Course' : 'Lesson'} Test",
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildInfoCard() => QuestionUI.glass(
    padding: EdgeInsets.all(12.w),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: AppColors.yellow, size: 20.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            "${isEditMode ? 'Editing' : 'Creating'} test for: ${widget.title}",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool isArabic = false,
    bool isNum = false,
  }) {
    return QuestionUI.glass(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: TextFormField(
        controller: ctrl,
        maxLength: isNum ? 3 : 255, // ✅ حد أقصى 255 حرف للعناوين
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        inputFormatters: isNum
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12.sp,
          ),
          border: InputBorder.none,
          counterText: "", // إخفاء عداد الأحرف الافتراضي
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';

          if (label.contains('English')) {
            if (v.length > 255) return 'Maximum 255 characters allowed';
            if (!enRegex.hasMatch(v))
              return 'Only English letters, numbers, spaces, and basic punctuation allowed';
          }

          if (label.contains('Arabic')) {
            if (v.length > 255) return 'Maximum 255 characters allowed';
            if (!arRegex.hasMatch(v))
              return 'Only Arabic letters, numbers, spaces, and basic punctuation allowed';
          }

          if (isNum) {
            final score = int.tryParse(v);
            if (score == null || score < 10 || score > 100)
              return 'Must be a number between 10 and 100';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSmartSummaryCard() {
    final totalScore = _totalScore;
    final passingScore = int.tryParse(_passingScoreCtrl.text) ?? 0;

    return QuestionUI.glass(
      padding: EdgeInsets.all(14.w),
      borderColor: AppColors.sky.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_outlined, color: AppColors.sky, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                "Test Summary",
                style: GoogleFonts.poppins(
                  color: AppColors.sky,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(
                'Questions',
                '${_selectedQuestions.length}',
                AppColors.yellow,
              ),
              _summaryItem('Total Score', '$totalScore pts', AppColors.sky),
              _summaryItem('Passing (%)', '$passingScore%', AppColors.yellow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10.sp),
        ),
      ],
    );
  }

  Widget _buildQuestionsSection(BuildContext context) {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Questions (${_selectedQuestions.length}/2 min)",
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: _openQuestionPicker,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sky.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.sky.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: AppColors.sky, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        "Add",
                        style: GoogleFonts.poppins(
                          color: AppColors.sky,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_selectedQuestions.isEmpty)
            Center(
              child: Text(
                "No questions added yet. Tap 'Add' to select.",
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 11.sp,
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedQuestions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _selectedQuestions.removeAt(oldIndex);
                  _selectedQuestions.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final q = _selectedQuestions[index];
                return Container(
                  key: ValueKey(q.id),
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.drag_handle,
                        color: Colors.white38,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.yellow.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: GoogleFonts.poppins(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          q.titleQuestionEn.isNotEmpty
                              ? q.titleQuestionEn
                              : q.titleQuestionAr,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedQuestions.removeAt(index)),
                        child: Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 18.sp,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<TestCreateCubit, TestCreateState>(
      builder: (context, createState) {
        return BlocBuilder<TestUpdateCubit, TestUpdateState>(
          builder: (context, updateState) {
            final isLoading =
                createState is TestCreateLoading ||
                updateState is TestUpdateLoading;
            return GestureDetector(
              onTap: isLoading ? null : () => _submit(context),
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
                          child: CircularProgressIndicator(
                            color: AppColors.dark,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEditMode ? 'Update Test' : 'Create Test',
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
      },
    );
  }
}

// ... (احتفظ بكلاس _QuestionPickerSheet كما هو)

class _QuestionPickerSheet extends StatefulWidget {
  final List<Question> selectedQuestions;
  final bool isCourseTest;
  final int? courseId;
  final Function(List<Question>) onConfirm;

  const _QuestionPickerSheet({
    required this.selectedQuestions,
    required this.isCourseTest,
    required this.courseId,
    required this.onConfirm,
  });

  @override
  State<_QuestionPickerSheet> createState() => _QuestionPickerSheetState();
}

class _QuestionPickerSheetState extends State<_QuestionPickerSheet> {
  late List<Question> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedQuestions);
  }

  void _toggleSelection(Question q) {
    // لاختبار كورس: امنع اختيار غير المؤهل
    if (widget.isCourseTest && q.isEligible == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This question is not eligible for this course test. '
            'Use it in a lesson test first.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      if (_tempSelected.any((e) => e.id == q.id)) {
        _tempSelected.removeWhere((e) => e.id == q.id);
      } else {
        _tempSelected.add(q);
      }
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestionFilterSheet(
        initialCourseId: widget.courseId,
        // ✅ افتراضي true، بس المستخدم يقدر يغيّر
        initialOnlyEligible: widget.isCourseTest ? true : null,
        // ✅ أظهر الـ Toggle لاختبار الكورس
        hideEligibleToggle: false,
      ),
    );

    if (result != null && mounted) {
      final onlyEligible = widget.isCourseTest
          ? (result['onlyEligible'] as bool? ?? true)
          : result['onlyEligible'] as bool?;

      context.read<QuestionFilterCubit>().applyFilters(
        type: result['type'] as String?,
        difficulty: result['difficulty'] as String?,
        minScore: result['min_score'] as int?,
        maxScore: result['max_score'] as int?,
        search: result['search'] as String?,
        sort: result['sort'] as String?,
        courseId: result['courseId'] as int? ?? widget.courseId,
        onlyEligible: onlyEligible,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      color: AppColors.yellow,
                      size: 24.sp,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      "Select Questions",
                      style: GoogleFonts.cinzelDecorative(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openFilters,
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: AppColors.orange,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: BlocBuilder<QuestionFilterCubit, QuestionFilterState>(
                  builder: (context, state) {
                    if (state is QuestionFilterLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.yellow,
                        ),
                      );
                    }
                    if (state is QuestionFilterLoaded) {
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 200) {
                            context.read<QuestionFilterCubit>().loadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount:
                              state.questions.length +
                              (state.currentPage < state.lastPage ? 1 : 0),
                          itemBuilder: (_, i) {
                            // آخر عنصر = مؤشر التحميل
                            if (i >= state.questions.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Center(
                                  child: state.isLoadingMore
                                      ? SizedBox(
                                          width: 22.w,
                                          height: 22.w,
                                          child:
                                              const CircularProgressIndicator(
                                                color: AppColors.yellow,
                                                strokeWidth: 2.5,
                                              ),
                                        )
                                      : Text(
                                          'Scroll for more',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                ),
                              );
                            }

                            final q = state.questions[i];
                            final isSelected = _tempSelected.any(
                              (element) => element.id == q.id,
                            );

                            return ListTile(
                              leading: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? AppColors.yellow
                                    : Colors.white54,
                              ),
                              title: Text(
                                q.titleQuestionEn.isNotEmpty
                                    ? q.titleQuestionEn
                                    : q.titleQuestionAr,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                ),
                                maxLines: 2,
                              ),
                              subtitle: Text(
                                "${q.type.value} • ${q.difficulty.value} • ${q.score} pts"
                                "${q.isEligible == true
                                    ? ' • Eligible'
                                    : q.isEligible == false
                                    ? ' • Not eligible'
                                    : ''}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 11.sp,
                                ),
                              ),
                              onTap: () => _toggleSelection(q),
                            );
                          },
                        ),
                      );
                    }
                    return Center(
                      child: Text(
                        "No questions found",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _tempSelected.length >= 2
                        ? () => widget.onConfirm(_tempSelected)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tempSelected.length >= 2
                          ? AppColors.yellow
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      "Confirm (${_tempSelected.length} Selected)",
                      style: GoogleFonts.poppins(
                        color: AppColors.dark,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
