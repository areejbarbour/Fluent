// lib/presentation/screens/teacher/lessons/lesson_form_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_cubit.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_state.dart';
import 'package:fluent/cubit/teacher/courses/form/lesson_form_cubit.dart';
import 'package:fluent/cubit/teacher/courses/form/lesson_form_state.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ Regex مطابقة تماماً للـ Backend Validation Rules
final RegExp enRegex = RegExp(r'^[a-zA-Z0-9\s\-_]+$');
final RegExp arRegex = RegExp(r'^[\u0600-\u06FF\s0-9\-_]+$');

class LessonFormScreen extends StatefulWidget {
  final int? courseId;
  final LessonModel? lesson;
  final String? courseStatus; // ✅ جديد: لاستقبال حالة الكورس
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
  bool get isEditMode => widget.lesson != null;

  // ✅ قواعد العمل من الـ Backend
  // ✅ قواعد العمل من الـ Backend (تم التعديل لفحص حالة الكورس)
  bool get isRestrictedEdit {
    // 1. إذا كان الكورس منشوراً، ممنوع أي تعديل أو حذف بغض النظر عن حالة الدرس
    if (widget.courseStatus == 'published') return true;

    // 2. إذا لم نكن في وضع التعديل، لا يوجد تقييد (نحن في وضع الإنشاء)
    if (!isEditMode || widget.lesson == null) return false;

    // 3. تقييدات إضافية بناءً على حالة الدرس نفسه (للاحتياط)
    return [
      'closed',
      'archived',
      'approved',
      'in_review',
    ].contains(widget.lesson!.status);
  }

  bool get isPublishedEdit {
    return isEditMode && widget.lesson?.status == 'published';
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
    if (result != null && result.files.isNotEmpty)
      setState(() => _selectedVideo = result.files.first);
  }

  void _submit(BuildContext context) async {
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

    // ✅ تأكد من تحويل القيم إلى int بشكل صحيح
    final orderValue = int.tryParse(_orderCtrl.text) ?? 1;
    final xpValue = int.tryParse(_xpCtrl.text) ?? 20;

    final formData = FormData.fromMap({
      'title_en': _titleEnCtrl.text.trim(),
      'title_ar': _titleArCtrl.text.trim(),
      'order': orderValue, // ✅ أرسل كـ int مباشرة
      'xp_points': xpValue, // ✅ أرسل كـ int مباشرة
      if (_selectedVideo != null && _selectedVideo!.path != null)
        'video': await MultipartFile.fromFile(
          _selectedVideo!.path!,
          filename: _selectedVideo!.name,
        ),
    });

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
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              "Delete Lesson?",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          "This action cannot be undone. The lesson will be permanently removed.",
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LessonDeleteCubit>().deleteLesson(widget.lesson!.id);
            },
            child: Text(
              "Delete",
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
    // ✅ إذا كان التعديل مقيداً (بسبب نشر الكورس أو حالة الدرس)، اعرض رسالة القفل
    if (isRestrictedEdit) {
      return Scaffold(
        body: Stack(
          children: [
            Container(decoration: QuestionUI.backgroundGradient()),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.redAccent,
                        size: 64.sp,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "Action Not Allowed",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        widget.courseStatus == 'published'
                            ? "This course is published. You cannot add, edit, or delete lessons."
                            : "This lesson is in a restricted status and cannot be modified.",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, size: 18.sp),
                        label: Text(
                          "Go Back",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: AppColors.dark,
                        ),
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

    return MultiBlocListener(
      listeners: [
        BlocListener<LessonFormCubit, LessonFormState>(
          listener: (context, state) {
            if (state is LessonFormSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditMode ? 'Lesson updated!' : 'Lesson created!',
                  ),
                  backgroundColor: Colors.greenAccent,
                ),
              );
              Navigator.pop(context, true);
            } else if (state is LessonFormFailure) {
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
              Navigator.pop(context, true); // العودة وتحديث القائمة
            } else if (state is LessonDeleteFailure) {
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
        isEditMode: isEditMode,
        isPublishedEdit: isPublishedEdit, // ✅ تمرير الحالة
        onPickVideo: _pickVideo,
        onSubmit: () => _submit(context),
        onDelete: () => _confirmDelete(context), // ✅ تمرير دالة الحذف
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleEnCtrl, titleArCtrl, orderCtrl, xpCtrl;
  final PlatformFile? selectedVideo;
  final bool isEditMode;
  final bool isPublishedEdit; // ✅ جديد
  final VoidCallback onPickVideo, onSubmit, onDelete;

  const _FormView({
    required this.formKey,
    required this.titleEnCtrl,
    required this.titleArCtrl,
    required this.orderCtrl,
    required this.xpCtrl,
    required this.selectedVideo,
    required this.isEditMode,
    required this.isPublishedEdit,
    required this.onPickVideo,
    required this.onSubmit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                          _buildTextField(
                            titleEnCtrl,
                            'Title (English)',
                            Icons.translate,
                            isArabic: false,
                          ),
                          SizedBox(height: 10.h),
                          _buildTextField(
                            titleArCtrl,
                            'Title (Arabic)',
                            Icons.translate,
                            isArabic: true,
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
                                  isEnabled: !isPublishedEdit,
                                ),
                              ), // ✅ تعطيل إذا كان Published
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildTextField(
                                  xpCtrl,
                                  'XP Points',
                                  Icons.star_rounded,
                                  isNum: true,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _buildVideoPicker(
                            context,
                            isEnabled: !isPublishedEdit,
                          ), // ✅ تعطيل إذا كان Published
                          SizedBox(height: 24.h),
                          _buildSubmitButton(context),
                          if (isEditMode) ...[
                            SizedBox(height: 16.h),
                            _buildDeleteButton(context), // ✅ زر الحذف الجديد
                          ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
            ),
            child: Icon(
              Icons.play_lesson_rounded,
              color: AppColors.yellow,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isEditMode ? "Edit Lesson" : "New Lesson",
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
        enabled: isEnabled, // ✅ التحكم في التفعيل
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
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
          if (v == null || v.isEmpty) return 'Required';
          // ✅ تطبيق نفس قواعد الـ Regex الموجودة في الـ Backend
          if (label.contains('English') && !enRegex.hasMatch(v))
            return 'Only English letters, numbers, spaces, - and _ allowed';
          if (label.contains('Arabic') && !arRegex.hasMatch(v))
            return 'Only Arabic letters, numbers, spaces, - and _ allowed';
          return null;
        },
      ),
    );
  }

  Widget _buildVideoPicker(BuildContext context, {bool isEnabled = true}) {
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
              Icon(
                Icons.video_library_rounded,
                color: isEnabled ? AppColors.sky : Colors.white54,
                size: 28.sp,
              ),
              SizedBox(height: 6.h),
              Text(
                selectedVideo != null
                    ? selectedVideo!.name
                    : (isEnabled
                          ? 'Tap to select video file'
                          : 'Video cannot be changed for published lessons'),
                style: GoogleFonts.poppins(
                  color: isEnabled ? Colors.white : Colors.white54,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (selectedVideo != null) ...[
                SizedBox(height: 4.h),
                Text(
                  '${(selectedVideo!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 10.sp,
                  ),
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
                      child: CircularProgressIndicator(
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

  // ✅ زر الحذف الاحترافي الجديد
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
                      child: CircularProgressIndicator(
                        color: Colors.redAccent,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 18.sp,
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
