import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/levels/level_exception_create_cubit.dart';
import 'package:fluent/cubit/student/levels/level_exception_create_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateLevelExceptionSheet extends StatefulWidget {
  final int levelId;
  final String levelTitle;

  const CreateLevelExceptionSheet({
    super.key,
    required this.levelId,
    required this.levelTitle,
  });

  @override
  State<CreateLevelExceptionSheet> createState() =>
      _CreateLevelExceptionSheetState();
}

class _CreateLevelExceptionSheetState extends State<CreateLevelExceptionSheet> {
  final TextEditingController _reasonCtrl = TextEditingController();
  final List<String> _selectedFilePaths = [];

  /// Inline form error (shown inside the sheet — no need to go back).
  String? _formError;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          // أضف الملفات الجديدة بدون مسح الموجودين
          for (final file in result.files) {
            if (file.path != null && !_selectedFilePaths.contains(file.path)) {
              _selectedFilePaths.add(file.path!);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('FilePicker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to pick files',
              style: GoogleFonts.poppins(fontSize: 13.sp),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _formError = 'Please enter a reason for your request');
      return;
    }

    setState(() => _formError = null);

    List<MultipartFile>? attachments;
    if (_selectedFilePaths.isNotEmpty) {
      attachments = await Future.wait(
        _selectedFilePaths.map((path) async {
          final fileName = path.split('/').last;
          return MultipartFile.fromFile(path, filename: fileName);
        }),
      );
    }

    if (!mounted) return;

    context.read<LevelExceptionCreateCubit>().create(
      levelId: widget.levelId,
      reason: reason,
      attachments: attachments,
    );
  }

  Widget _inlineErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.redAccent.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.red.shade200,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _formError = null),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white38,
              size: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LevelExceptionCreateCubit, LevelExceptionCreateState>(
      listener: (context, state) {
        if (state is LevelExceptionCreateSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.poppins(fontSize: 13.sp),
              ),
              backgroundColor: AppColors.sky,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        } else if (state is LevelExceptionCreateFailure) {
          // Keep sheet open and show error in-form.
          setState(() => _formError = state.message);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 28.h),
              decoration: BoxDecoration(
                // نفس تدرج واجهة المستويات
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.dark.withOpacity(.95),
                    AppColors.primary.withOpacity(.55),
                    AppColors.dark.withOpacity(.92),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(.14)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sky.withOpacity(.12),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.sky.withOpacity(.5),
                              AppColors.yellow.withOpacity(.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Header
                    Row(
                          children: [
                            Container(
                              width: 50.w,
                              height: 50.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.r),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.sky.withOpacity(.30),
                                    AppColors.primary.withOpacity(.20),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.sky.withOpacity(.45),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.sky.withOpacity(.30),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.lock_open_rounded,
                                color: AppColors.sky,
                                size: 23.sp,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Request Exception',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16.sp,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.orange.withOpacity(.25),
                                          AppColors.yellow.withOpacity(.15),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: AppColors.yellow.withOpacity(
                                          .35,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      widget.levelTitle,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.yellow,
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .moveY(begin: 8, end: 0),

                    SizedBox(height: 12.h),

                    Text(
                      'Explain why you need access to this level and attach supporting documents if available.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.55),
                        fontSize: 11.5.sp,
                        height: 1.45,
                      ),
                    ).animate().fadeIn(delay: 60.ms, duration: 400.ms),

                    SizedBox(height: 20.h),

                    if (_formError != null) _inlineErrorBanner(_formError!),

                    // Reason field
                    TextField(
                      controller: _reasonCtrl,
                      maxLines: 4,
                      onChanged: (_) {
                        if (_formError != null) {
                          setState(() => _formError = null);
                        }
                      },
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.5.sp,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(.07),
                        labelText: 'Reason',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 12.sp,
                        ),
                        hintText: 'Tell us why you need this level unlocked…',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.30),
                          fontSize: 12.5.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(
                            color: AppColors.sky,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                    SizedBox(height: 18.h),

                    // Attachments label
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          color: AppColors.sky.withOpacity(.85),
                          size: 15.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Attachments',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.75),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedFilePaths.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sky.withOpacity(.18),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.sky.withOpacity(.35),
                              ),
                            ),
                            child: Text(
                              '${_selectedFilePaths.length}',
                              style: GoogleFonts.poppins(
                                color: AppColors.sky,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          'PDF / JPG / PNG',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.35),
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 140.ms, duration: 400.ms),

                    SizedBox(height: 10.h),

                    // Pick files button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _pickFiles();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.sky.withOpacity(.12),
                              AppColors.primary.withOpacity(.08),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.sky.withOpacity(.28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(7.r),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.sky.withOpacity(.30),
                                    AppColors.sky.withOpacity(.12),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_rounded,
                                color: AppColors.sky,
                                size: 18.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              _selectedFilePaths.isEmpty
                                  ? 'Add files'
                                  : 'Add more files',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 180.ms, duration: 400.ms),

                    // Selected files list
                    if (_selectedFilePaths.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      ..._selectedFilePaths.asMap().entries.map((entry) {
                        final index = entry.key;
                        final path = entry.value;
                        final name = path.split('/').last;
                        final isPdf = name.toLowerCase().endsWith('.pdf');

                        return Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 11.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.sky.withOpacity(.12),
                                    AppColors.primary.withOpacity(.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.sky.withOpacity(.28),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.sky.withOpacity(.18),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      isPdf
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.image_rounded,
                                      color: AppColors.sky,
                                      size: 16.sp,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedFilePaths.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(5.r),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(
                                          .12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Colors.redAccent,
                                        size: 15.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .moveX(begin: 10, end: 0);
                      }),
                    ],

                    SizedBox(height: 24.h),

                    // Submit button
                    BlocBuilder<
                          LevelExceptionCreateCubit,
                          LevelExceptionCreateState
                        >(
                          builder: (context, state) {
                            final isLoading =
                                state is LevelExceptionCreateLoading;

                            return GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () {
                                      HapticFeedback.mediumImpact();
                                      _submit();
                                    },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isLoading
                                        ? [
                                            AppColors.orange.withOpacity(.45),
                                            AppColors.yellow.withOpacity(.45),
                                          ]
                                        : [AppColors.orange, AppColors.yellow],
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.yellow.withOpacity(
                                        isLoading ? .15 : .40,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isLoading
                                      ? SizedBox(
                                          width: 22.sp,
                                          height: 22.sp,
                                          child:
                                              const CircularProgressIndicator(
                                                color: Colors.black,
                                                strokeWidth: 2.4,
                                              ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.send_rounded,
                                              color: Colors.black,
                                              size: 17.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Submit Request',
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14.sp,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        )
                        .animate()
                        .fadeIn(delay: 220.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
