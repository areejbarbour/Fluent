import 'dart:math' as math;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/levels/level_exception_details_cubit.dart';
import 'package:fluent/cubit/student/levels/level_exception_details_state.dart';
import 'package:fluent/cubit/student/levels/level_exception_update_cubit.dart';
import 'package:fluent/cubit/student/levels/level_exception_update_state.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelExceptionDetailsScreen extends StatefulWidget {
  final int exceptionId;
  const LevelExceptionDetailsScreen({super.key, required this.exceptionId});

  @override
  State<LevelExceptionDetailsScreen> createState() =>
      _LevelExceptionDetailsScreenState();
}

class _LevelExceptionDetailsScreenState
    extends State<LevelExceptionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          _buildBackground(),
          _TwinklingStars(count: 24),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: _buildTopBar(),
                ),
                Expanded(
                  child:
                      BlocBuilder<
                        LevelExceptionDetailsCubit,
                        LevelExceptionDetailsState
                      >(
                        builder: (context, state) {
                          if (state is LevelExceptionDetailsLoading) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 36.w,
                                    height: 36.w,
                                    child: const CircularProgressIndicator(
                                      color: AppColors.yellow,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(height: 14.h),
                                  Text(
                                    'Loading...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (state is LevelExceptionDetailsFailure) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(16.r),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.redAccent.withOpacity(
                                          .12,
                                        ),
                                        border: Border.all(
                                          color: Colors.redAccent.withOpacity(
                                            .25,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 32.sp,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 13.sp,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (state is LevelExceptionDetailsSuccess) {
                            return _DetailsBody(details: state.details);
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
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xff011826),
                AppColors.dark,
                AppColors.primary,
                Color(0xff01466A),
                AppColors.dark,
              ],
              stops: [0.0, 0.2, 0.55, 0.8, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -120.h,
          right: -80.w,
          child: _glowCircle(AppColors.yellow, 300.w, 160, 40)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-15, 10),
                duration: 5500.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          top: 420.h,
          left: -100.w,
          child: _glowCircle(AppColors.sky, 260.w, 150, 30)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(20, 15),
                duration: 6500.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          top: 780.h,
          right: -60.w,
          child: _glowCircle(const Color(0xffB861F5), 220.w, 140, 25)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-10, -8),
                duration: 7000.ms,
                curve: Curves.easeInOut,
              ),
        ),
      ],
    );
  }

  Widget _glowCircle(Color color, double size, double blur, double spread) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.30),
            blurRadius: blur,
            spreadRadius: spread,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Request Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  width: 28.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.yellow],
                    ),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ],
            ),
          ),
        ),
        Builder(
          builder: (context) {
            final state = context.watch<LevelExceptionDetailsCubit>().state;
            final canEdit =
                state is LevelExceptionDetailsSuccess &&
                state.details.isPending;
            if (!canEdit) {
              // Keep layout balanced when edit is hidden
              return SizedBox(width: 44.w);
            }
            return _circleIconButton(
              icon: Icons.edit_rounded,
              iconColor: AppColors.yellow,
              onTap: () {
                HapticFeedback.selectionClick();
                _showEditSheet(context, state.details);
              },
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(.14),
              Colors.white.withOpacity(.04),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 18.sp),
      ),
    );
  }

  void _showEditSheet(BuildContext context, LevelExceptionModel details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider(
          create: (ctx) =>
              LevelExceptionUpdateCubit(ctx.read<LevelExceptionRepository>()),
          child: _EditExceptionSheet(
            details: details,
            onSuccess: (_) {
              context.read<LevelExceptionDetailsCubit>().fetchDetails(
                widget.exceptionId,
              );
            },
          ),
        );
      },
    );
  }
}

// ===============================================================
//                        Details Body
// ===============================================================
class _DetailsBody extends StatelessWidget {
  final LevelExceptionModel details;
  const _DetailsBody({required this.details});

  /// Colors / icons aligned with teacher StatusUI + Status Board.
  Color get statusColor {
    switch (details.status?.toLowerCase()) {
      case 'in_review':
        return AppColors.sky;
      case 'approved':
        return const Color(0xFF69F0AE); // greenAccent
      case 'rejected':
        return Colors.redAccent;
      default: // pending → StatusUI lightOrange
        return AppColors.lightOrange;
    }
  }

  IconData get statusIcon {
    switch (details.status?.toLowerCase()) {
      case 'in_review':
        return Icons.rate_review_outlined;
      case 'approved':
        return Icons.verified_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      default: // pending
        return Icons.hourglass_top_rounded;
    }
  }

  String get statusLabel {
    switch (details.status?.toLowerCase()) {
      case 'in_review':
        return 'In Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Hero ──
          Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(.20),
                        statusColor.withOpacity(.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: statusColor.withOpacity(.40)),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(.20),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          color: statusColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 450.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

          SizedBox(height: 24.h),

          // ── Request Info (only when level name is available)
          if (details.requestedLevelName != null) ...[
            _sectionCard(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.sky,
                  title: 'Request Info',
                  children: [
                    _infoTile(
                      icon: Icons.school_rounded,
                      label: 'Requested Level',
                      value: details.requestedLevelName!,
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: 80.ms, duration: 450.ms)
                .moveY(begin: 12, end: 0),
            SizedBox(height: 14.h),
          ],

          // ── Reason ──
          if (details.reason != null && details.reason!.isNotEmpty)
            _sectionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: AppColors.yellow,
                  title: 'Reason',
                  children: [
                    Text(
                      details.reason!,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.90),
                        fontSize: 13.sp,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: 140.ms, duration: 450.ms)
                .moveY(begin: 12, end: 0),

          if (details.reason != null && details.reason!.isNotEmpty)
            SizedBox(height: 14.h),

          // ── Admin Note ──
          if (details.reviewNote != null && details.reviewNote!.isNotEmpty)
            _sectionCard(
                  icon: Icons.admin_panel_settings_rounded,
                  iconColor: const Color(0xffB388FF),
                  title: 'Admin Note',
                  children: [
                    Text(
                      details.reviewNote!,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.80),
                        fontSize: 13.sp,
                        height: 1.6,
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 450.ms)
                .moveY(begin: 12, end: 0),

          if (details.reviewNote != null && details.reviewNote!.isNotEmpty)
            SizedBox(height: 14.h),

          // ── Attachments ──
          if (details.attachments.isNotEmpty)
            _sectionCard(
                  icon: Icons.attach_file_rounded,
                  iconColor: AppColors.orange,
                  title: 'Attachments (${details.attachments.length})',
                  children: details.attachments.asMap().entries.map((entry) {
                    final i = entry.key;
                    final attachment = entry.value;
                    final fileName = attachment.fileName;
                    final isPdf = attachment.isPdf;
                    final canDelete =
                        details.canManageAttachments && attachment.canDelete;

                    return BlocBuilder<
                      LevelExceptionDetailsCubit,
                      LevelExceptionDetailsState
                    >(
                      buildWhen: (prev, curr) {
                        final prevId = prev is LevelExceptionDetailsSuccess
                            ? prev.deletingMediaId
                            : null;
                        final currId = curr is LevelExceptionDetailsSuccess
                            ? curr.deletingMediaId
                            : null;
                        return prevId != currId;
                      },
                      builder: (context, state) {
                        final deletingId = state is LevelExceptionDetailsSuccess
                            ? state.deletingMediaId
                            : null;
                        final isDeletingThis = deletingId == attachment.id;

                        return Container(
                          margin: EdgeInsets.only(
                            bottom: i == details.attachments.length - 1
                                ? 0
                                : 10.h,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.05),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(.10),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: AppColors.sky.withOpacity(.15),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  isPdf
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_rounded,
                                  color: AppColors.sky,
                                  size: 18.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (canDelete)
                                GestureDetector(
                                  onTap: isDeletingThis
                                      ? null
                                      : () => _confirmDeleteAttachment(
                                          context,
                                          details.id,
                                          attachment,
                                        ),
                                  child: Container(
                                    width: 34.w,
                                    height: 34.w,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(.12),
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(
                                        color: Colors.redAccent.withOpacity(
                                          .28,
                                        ),
                                      ),
                                    ),
                                    child: isDeletingThis
                                        ? SizedBox(
                                            width: 16.w,
                                            height: 16.w,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.redAccent,
                                                ),
                                          )
                                        : Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 17.sp,
                                          ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white.withOpacity(.35),
                                  size: 18.sp,
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                )
                .animate()
                .fadeIn(delay: 260.ms, duration: 450.ms)
                .moveY(begin: 12, end: 0),
        ],
      ),
    );
  }


  Future<void> _confirmDeleteAttachment(
    BuildContext context,
    int exceptionId,
    LevelExceptionAttachment attachment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Remove attachment?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
        content: Text(
          '“${attachment.fileName}” will be permanently removed from this request.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
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

    HapticFeedback.mediumImpact();
    final error = await context
        .read<LevelExceptionDetailsCubit>()
        .deleteAttachment(exceptionId: exceptionId, mediaId: attachment.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(.15),
          ),
          child: Icon(
            error == null
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: error == null
                ? const Color(0xFF4ADE80)
                : Colors.redAccent,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            error ?? 'Attachment deleted successfully.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5.sp,
            ),
          ),
        ),
      ],
    ),
    backgroundColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14.r),
    ),
    margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
    duration: const Duration(seconds: 3),
  ),
);

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       error ?? 'Attachment deleted successfully.',
    //       style: GoogleFonts.poppins(fontSize: 13.sp),
    //     ),
    //     backgroundColor: error == null ? AppColors.sky : Colors.redAccent,
    //     behavior: SnackBarBehavior.floating,
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(10.r),
    //     ),
    //   ),
    // );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(.10),
            Colors.white.withOpacity(.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: iconColor.withOpacity(.25)),
                ),
                child: Icon(icon, color: iconColor, size: 15.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(.40), size: 15.sp),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.50),
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tileDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0),
              Colors.white.withOpacity(.10),
              Colors.white.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditExceptionSheet extends StatefulWidget {
  final LevelExceptionModel details;
  final Function(LevelExceptionModel?) onSuccess;

  const _EditExceptionSheet({required this.details, required this.onSuccess});

  @override
  State<_EditExceptionSheet> createState() => _EditExceptionSheetState();
}

class _EditExceptionSheetState extends State<_EditExceptionSheet> {
  late TextEditingController _reasonCtrl;
  late List<LevelExceptionAttachment> _existingAttachments;
  final List<String> _newFilePaths = [];

  /// Inline form error (shown inside the sheet — no need to go back).
  String? _formError;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController(text: widget.details.reason ?? '');
    _existingAttachments = List.from(widget.details.attachments);
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await fp.FilePicker.pickFiles(
        allowMultiple: true,
        type: fp.FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null && !_newFilePaths.contains(file.path)) {
              _newFilePaths.add(file.path!);
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

    if (_newFilePaths.isNotEmpty) {
      attachments = await Future.wait(
        _newFilePaths.map((path) async {
          final fileName = path.split('/').last;
          return MultipartFile.fromFile(path, filename: fileName);
        }),
      );
    }

    if (!mounted) return;

    context.read<LevelExceptionUpdateCubit>().update(
      id: widget.details.id,
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
    return BlocListener<LevelExceptionUpdateCubit, LevelExceptionUpdateState>(
      listener: (context, state) {
  if (state is LevelExceptionUpdateSuccess) {
    Navigator.pop(context);

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.15),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF4ADE80),
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                state.message ?? 'Request updated successfully.',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5.sp,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        duration: const Duration(seconds: 3),
      ),
    );
    widget.onSuccess(state.updated);
  } else if (state is LevelExceptionUpdateFailure) {
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

                    // Header (Icon + Title + ID Tag)
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
                                Icons.edit_rounded,
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
                                    'Edit Request',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16.sp,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  if (widget.details.requestedLevelName !=
                                      null) ...[
                                    SizedBox(height: 3.h),
                                    Text(
                                      widget.details.requestedLevelName!,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.yellow.withOpacity(
                                          .85,
                                        ),
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
                      'Modify your request reason or update your supporting documents below.',
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

                    // Current attachments section
                    if (_existingAttachments.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            color: AppColors.sky.withOpacity(.85),
                            size: 15.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Current Attachments',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(.75),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                              '${_existingAttachments.length}',
                              style: GoogleFonts.poppins(
                                color: AppColors.sky,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 140.ms, duration: 400.ms),
                      SizedBox(height: 10.h),
                      ..._existingAttachments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final attachment = entry.value;
                        final name = attachment.fileName;
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
                                Colors.white.withOpacity(.07),
                                Colors.white.withOpacity(.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(.12),
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
                                onTap: () async {
                                  HapticFeedback.selectionClick();
                                  final item = _existingAttachments[index];
                                  // If we have a real media id and request is pending,
                                  // delete on the server immediately.
                                  if (item.canDelete &&
                                      widget.details.canManageAttachments) {
                                    final repo = context
                                        .read<LevelExceptionRepository>();
                                    final result = await repo.deleteAttachment(
                                      exceptionId: widget.details.id,
                                      mediaId: item.id,
                                    );
                                    if (!mounted) return;
                                    if (result['success'] != true) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['message']?.toString() ??
                                                'Failed to delete attachment',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  setState(() {
                                    _existingAttachments.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(5.r),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 15.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms).moveX(begin: 10, end: 0);
                      }),
                      SizedBox(height: 14.h),
                    ],

                    // Add new files label
                    Row(
                      children: [
                        Icon(
                          Icons.note_add_rounded,
                          color: AppColors.yellow.withOpacity(.85),
                          size: 15.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Add New Attachments',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.75),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_newFilePaths.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.yellow.withOpacity(.18),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.yellow.withOpacity(.35),
                              ),
                            ),
                            child: Text(
                              '${_newFilePaths.length}',
                              style: GoogleFonts.poppins(
                                color: AppColors.yellow,
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
                    ).animate().fadeIn(delay: 160.ms, duration: 400.ms),

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
                              _newFilePaths.isEmpty
                                  ? 'Choose files'
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

                    // Selected new files list
                    if (_newFilePaths.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      ..._newFilePaths.asMap().entries.map((entry) {
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
                                    AppColors.yellow.withOpacity(.12),
                                    AppColors.orange.withOpacity(.06),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.yellow.withOpacity(.28),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.yellow.withOpacity(.18),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      isPdf
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.image_rounded,
                                      color: AppColors.yellow,
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
                                        _newFilePaths.removeAt(index);
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

                    // Save changes button
                    BlocBuilder<
                          LevelExceptionUpdateCubit,
                          LevelExceptionUpdateState
                        >(
                          builder: (context, state) {
                            final isLoading =
                                state is LevelExceptionUpdateLoading;

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
                                              Icons.save_rounded,
                                              color: Colors.black,
                                              size: 17.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Save Changes',
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
class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 40});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(13);
    return IgnorePointer(
      child: Stack(
        children: List.generate(count, (i) {
          final left = rng.nextDouble();
          final top = rng.nextDouble();
          final size = rng.nextDouble() * 2 + 1;
          final delay = rng.nextInt(3000);
          final duration = 1500 + rng.nextInt(2500);
          final maxOpacity = rng.nextDouble() * 0.6 + 0.3;
          final hasGlow = rng.nextBool();

          return Positioned(
            left: left * 1.sw,
            top: top * 1.sh,
            child:
                Container(
                      width: size.w,
                      height: size.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: hasGlow
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.7),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : null,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(
                      begin: 0,
                      end: maxOpacity,
                      duration: duration.ms,
                      delay: delay.ms,
                    )
                    .then()
                    .fade(begin: maxOpacity, end: 0, duration: duration.ms),
          );
        }),
      ),
    );
  }
}
