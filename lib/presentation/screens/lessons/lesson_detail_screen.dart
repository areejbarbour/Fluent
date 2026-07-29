import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'package:fluent/cubit/student/lessons/lesson_detail_cubit.dart';
import 'package:fluent/cubit/student/lessons/lesson_detail_state.dart';
import 'package:fluent/data/models/lesson_detail_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final int? lessonId;
  final String lessonTitle;

  const LessonDetailScreen({super.key, this.lessonId, this.lessonTitle = ''});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _isSendingComment = false;
  int? _busyCommentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<LessonDetailCubit>();
      if (cubit.state is LessonDetailInitial) {
        cubit.fetchLessonDetail(widget.lessonId ?? 0);
      }
    });
  }

  Future<void> _handleAddComment(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > LessonDetailCubit.maxCommentLength) {
      _showErrorSnack(
        'Comment must not exceed ${LessonDetailCubit.maxCommentLength} characters',
      );
      return;
    }
    setState(() => _isSendingComment = true);
    final error = await context.read<LessonDetailCubit>().submitComment(
      widget.lessonId ?? 0,
      trimmed,
    );
    if (!mounted) return;
    setState(() => _isSendingComment = false);

    if (error != null) _showErrorSnack(error);
  }

  void _showErrorSnack(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCommentActions(LessonCommentModel comment, {bool canEdit = true}) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.dark.withOpacity(.97),
                    AppColors.primary.withOpacity(.9),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(.14)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.25),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  // ✅ تعديل فقط إن لم يكن الدرس archived/closed (منطق الباك)
                  if (canEdit) ...[
                    _actionTile(
                      icon: Icons.edit_rounded,
                      label: "Edit comment",
                      iconColors: const [AppColors.sky, Color(0xFFB388FF)],
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openEditDialog(comment);
                      },
                    ),
                    SizedBox(height: 10.h),
                  ],
                  _actionTile(
                    icon: Icons.delete_outline_rounded,
                    label: "Delete comment",
                    iconColors: const [Color(0xFFFF6B6B), Color(0xFFE53935)],
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmDelete(comment);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required List<Color> iconColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: iconColors),
              ),
              child: Icon(icon, color: Colors.white, size: 17.sp),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditDialog(LessonCommentModel comment) {
    final controller = TextEditingController(text: comment.comment);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.dark.withOpacity(.95),
                      AppColors.primary.withOpacity(.85),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(.16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34.w,
                          height: 34.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.sky, Color(0xFFB388FF)],
                            ),
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          "Edit Comment",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.06),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(.14),
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: LessonDetailCubit.maxCommentLength,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.5.sp,
                        ),
                        cursorColor: AppColors.yellow,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          counterStyle: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(dialogContext),
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 11.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.08),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(.14),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(.8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final newText = controller.text.trim();
                              if (newText.length >
                                  LessonDetailCubit.maxCommentLength) {
                                return;
                              }
                              Navigator.pop(dialogContext);
                              if (newText.isNotEmpty &&
                                  newText != comment.comment) {
                                _handleEditComment(comment.id, newText);
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 11.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.orange, AppColors.yellow],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.yellow.withOpacity(.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Text(
                                "Save",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(LessonCommentModel comment) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.dark.withOpacity(.95),
                      AppColors.primary.withOpacity(.85),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(.16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF6B6B).withOpacity(.15),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(.4),
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: const Color(0xFFFF6B6B),
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      "Delete this comment?",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "This can't be undone.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.6),
                        fontSize: 11.5.sp,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(dialogContext),
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 11.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.08),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(.14),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(.8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _handleDeleteComment(comment.id);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 11.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFE53935),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF6B6B,
                                    ).withOpacity(.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Text(
                                "Delete",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleEditComment(int commentId, String newText) async {
    setState(() => _busyCommentId = commentId);
    final error = await context.read<LessonDetailCubit>().editComment(
      commentId,
      newText,
    );
    if (!mounted) return;
    setState(() => _busyCommentId = null);
    if (error != null) _showErrorSnack(error);
  }

  Future<void> _handleDeleteComment(int commentId) async {
    setState(() => _busyCommentId = commentId);
    final error = await context.read<LessonDetailCubit>().removeComment(
      commentId,
    );
    if (!mounted) return;
    setState(() => _busyCommentId = null);
    if (error != null) _showErrorSnack(error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(),
          _TwinklingStars(count: 35),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: _buildTopBar(),
                ),
                Expanded(
                  child: BlocBuilder<LessonDetailCubit, LessonDetailState>(
                    builder: (context, state) {
                      if (state is LessonDetailLoading ||
                          state is LessonDetailInitial) {
                        return _loadingCard();
                      }

                      if (state is LessonDetailFailure) {
                        return _errorCard(state.message);
                      }

                      if (state is LessonDetailSuccess) {
                        return _buildContent(
                          state.data,
                          isLoadingMore: state.isLoadingMore,
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
                BlocBuilder<LessonDetailCubit, LessonDetailState>(
                  builder: (context, state) {
                    if (state is! LessonDetailSuccess) {
                      return const SizedBox.shrink();
                    }
                    // مطابق للباك: لا إنشاء تعليق إلا إذا الدرس published
                    if (!state.data.canCreateComment) {
                      return SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                          child: Text(
                            'Comments are disabled for this lesson.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      );
                    }
                    return _CommentComposer(
                      isSending: _isSendingComment,
                      onSubmit: _handleAddComment,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.yellow),
          SizedBox(height: 12.h),
          Text(
            "Loading lesson...",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.7),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(.10),
                    Colors.white.withOpacity(.04),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white.withOpacity(.7),
                    size: 30.sp,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.85),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: () => context
                        .read<LessonDetailCubit>()
                        .fetchLessonDetail(widget.lessonId ?? 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 9.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.orange, AppColors.yellow],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        "Retry",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(LessonDetailModel data, {bool isLoadingMore = false}) {
    final lesson = data.lesson;
    final comments = data.comments;
    final totalLabel = data.commentsTotal > comments.length
        ? data.commentsTotal
        : comments.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        SizedBox(height: 4.h),
        if (lesson != null && lesson.video.isNotEmpty)
          _LuxuryVideoPlayer(videoUrl: lesson.video, title: lesson.title)
        else
          _noVideoCard(),
        SizedBox(height: 16.h),
        if (lesson != null) _buildLessonInfoCard(lesson),
        SizedBox(height: 24.h),
        _buildCommentsHeader(totalLabel),
        SizedBox(height: 14.h),
        if (comments.isEmpty && !isLoadingMore)
          _emptyCommentsCard()
        else
          ...comments.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _CommentCard(
                comment: entry.value,
                index: entry.key,
                isBusy: _busyCommentId == entry.value.id,
                // isOwn من مقارنة user_id المحفوظ مع comment.user.id
                // التعديل يُخفى إذا الدرس archived/closed (منطق الباك)
                onMoreTap: entry.value.isOwn
                    ? () => _showCommentActions(
                        entry.value,
                        canEdit: data.canUpdateComments,
                      )
                    : null,
              ),
            ),
          ),
        if (isLoadingMore || data.hasMoreComments)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: isLoadingMore
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        color: AppColors.yellow,
                        strokeWidth: 2.5,
                      ),
                    )
                  : TextButton(
                      onPressed: () =>
                          context.read<LessonDetailCubit>().loadMoreComments(),
                      child: Text(
                        'Load more comments',
                        style: GoogleFonts.poppins(
                          color: AppColors.sky,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
            ),
          ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _noVideoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(.08),
                Colors.white.withOpacity(.03),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.12)),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.videocam_off_rounded,
            color: Colors.white.withOpacity(.4),
            size: 34.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildLessonInfoCard(LessonVideoModel lesson) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.sky.withOpacity(.14),
                Colors.white.withOpacity(.04),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.16)),
            boxShadow: [
              BoxShadow(
                color: AppColors.sky.withOpacity(.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.sky, Color(0xFFB388FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sky.withOpacity(.5),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "VIDEO LESSON",
                      style: GoogleFonts.poppins(
                        color: AppColors.sky.withOpacity(.85),
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.yellow],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.black, size: 13.sp),
                    SizedBox(width: 3.w),
                    Text(
                      "${lesson.xpPoints} XP",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).moveY(begin: 8, end: 0);
  }

  Widget _buildCommentsHeader(int count) {
    return Row(
      children: [
        Container(
          width: 30.w,
          height: 30.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.sky, Color(0xFFB388FF)],
            ),
          ),
          child: Icon(Icons.forum_rounded, color: Colors.white, size: 15.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          "Comments",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15.5.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(.14)),
          ),
          child: Text(
            "$count",
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.06),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort_rounded,
                color: Colors.white.withOpacity(.6),
                size: 13.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                "Newest",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.6),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyCommentsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 28.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: Colors.white.withOpacity(.05),
            border: Border.all(color: Colors.white.withOpacity(.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.06),
                  border: Border.all(color: Colors.white.withOpacity(.12)),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white.withOpacity(.4),
                  size: 22.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "No comments yet",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.65),
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                "Be the first to share your thoughts",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.4),
                  fontSize: 10.5.sp,
                ),
              ),
            ],
          ),
        ),
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
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "LESSON",
                style: GoogleFonts.poppins(
                  color: AppColors.sky.withOpacity(.85),
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                widget.lessonTitle.isNotEmpty ? widget.lessonTitle : "Lesson",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).moveY(begin: -10, end: 0);
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white.withOpacity(.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
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
                AppColors.dark,
              ],
              stops: [0.0, 0.3, 0.65, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -120.h,
          right: -80.w,
          child: _glowCircle(AppColors.yellow, 280.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-15, 10),
                duration: 5500.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          bottom: -140.h,
          left: -90.w,
          child: _glowCircle(AppColors.sky, 300.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(15, -10),
                duration: 6500.ms,
                curve: Curves.easeInOut,
              ),
        ),
      ],
    );
  }

  Widget _glowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 140,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}

class _LuxuryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? title;
  const _LuxuryVideoPlayer({required this.videoUrl, this.title});

  @override
  State<_LuxuryVideoPlayer> createState() => _LuxuryVideoPlayerState();
}

class _LuxuryVideoPlayerState extends State<_LuxuryVideoPlayer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isMuted = false;
  Timer? _hideTimer;
  late final AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();
      controller.addListener(_onControllerUpdate);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    HapticFeedback.lightImpact();
    if (controller.value.isPlaying) {
      controller.pause();
      _cancelHideTimer();
      setState(() => _showControls = true);
    } else {
      controller.play();
      _scheduleHideControls();
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _scheduleHideControls() {
    _cancelHideTimer();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _onTapVideo() {
    setState(() => _showControls = !_showControls);
    if (_showControls && (_controller?.value.isPlaying ?? false)) {
      _scheduleHideControls();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  @override
  void dispose() {
    _cancelHideTimer();
    _borderController.dispose();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
          animation: _borderController,
          builder: (context, _) {
            return CustomPaint(
              foregroundPainter: _AnimatedBorderPainter(
                animationValue: _borderController.value,
                radius: 24.r,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sky.withOpacity(.18),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: _isInitialized
                        ? _controller!.value.aspectRatio
                        : 16 / 9,
                    child: _hasError
                        ? _buildErrorPlaceholder()
                        : !_isInitialized
                        ? _buildLoadingPlaceholder()
                        : GestureDetector(
                            onTap: _onTapVideo,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                VideoPlayer(_controller!),
                                AnimatedOpacity(
                                  opacity: _showControls ? 1 : 0,
                                  duration: 220.ms,
                                  child: IgnorePointer(
                                    ignoring: !_showControls,
                                    child: _buildControlsOverlay(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(.97, .97),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black.withOpacity(.35),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.yellow),
          SizedBox(height: 10.h),
          Text(
            "Loading video...",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.7),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.black.withOpacity(.35),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.white.withOpacity(.6),
            size: 30.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            "Couldn't load the video",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.75),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final controller = _controller!;
    final value = controller.value;
    final position = value.position;
    final duration = value.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(.45),
            Colors.transparent,
            Colors.black.withOpacity(.6),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 0),
            child: Row(
              children: [
                if (widget.title != null && widget.title!.isNotEmpty)
                  Expanded(
                    child: Text(
                      widget.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.92),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(.4),
                      border: Border.all(color: Colors.white.withOpacity(.2)),
                    ),
                    child: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 15.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.yellow],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(.6),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 32.sp,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Text(
                  _formatDuration(position),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5.h,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 6.r,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: 12.r,
                      ),
                      activeTrackColor: AppColors.yellow,
                      inactiveTrackColor: Colors.white.withOpacity(.25),
                      thumbColor: AppColors.yellow,
                      overlayColor: AppColors.yellow.withOpacity(.25),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (v) {
                        final newPosition = Duration(
                          milliseconds: (duration.inMilliseconds * v).round(),
                        );
                        controller.seekTo(newPosition);
                      },
                      onChangeStart: (_) => _cancelHideTimer(),
                      onChangeEnd: (_) {
                        if (value.isPlaying) _scheduleHideControls();
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDuration(duration),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================== كرت التعليق (تصميم فخم أكتر) ==================

class _CommentCard extends StatelessWidget {
  final LessonCommentModel comment;
  final int index;
  final VoidCallback? onMoreTap;
  final bool isBusy;

  const _CommentCard({
    required this.comment,
    required this.index,
    this.onMoreTap,
    this.isBusy = false,
  });

  static const List<List<Color>> _avatarGradients = [
    [AppColors.sky, Color(0xFFB388FF)],
    [AppColors.orange, AppColors.yellow],
    [Color(0xFF4ADE80), Color(0xFF22C55E)],
    [Color(0xFFFF6FB5), Color(0xFFB861F5)],
  ];

  List<Color> _gradientForUser(int seed) =>
      _avatarGradients[seed % _avatarGradients.length];

  String _timeAgo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return "";
    final date = DateTime.tryParse(isoDate);
    if (date == null) return "";
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${(diff.inDays / 7).floor()}w ago";
  }

  @override
  Widget build(BuildContext context) {
    final user = comment.user;
    final isOwn = comment.isOwn;
    final name = isOwn
        ? (user != null && user.fullName.isNotEmpty ? user.fullName : "You")
        : (user != null && user.fullName.isNotEmpty
              ? user.fullName
              : "Fluent User");
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final gradient = isOwn
        ? const [AppColors.orange, AppColors.yellow]
        : _gradientForUser(user?.id ?? comment.id);

    return ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isOwn
                      ? [
                          AppColors.yellow.withOpacity(.14),
                          AppColors.orange.withOpacity(.05),
                        ]
                      : [
                          Colors.white.withOpacity(.09),
                          Colors.white.withOpacity(.03),
                        ],
                ),
                border: Border.all(
                  color: isOwn
                      ? AppColors.yellow.withOpacity(.35)
                      : Colors.white.withOpacity(.13),
                ),
                boxShadow: isOwn
                    ? [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(.15),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // شريط لوني جانبي مطابق للون الأفاتار
                    Container(
                      width: 4.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(20.r),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12.w, 12.h, 10.w, 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: gradient),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(.5),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gradient.first.withOpacity(.45),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5.sp,
                                              ),
                                            ),
                                          ),
                                          if (isOwn) ...[
                                            SizedBox(width: 6.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6.w,
                                                vertical: 1.5.h,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    AppColors.orange,
                                                    AppColors.yellow,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20.r),
                                              ),
                                              child: Text(
                                                "You",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 8.5.sp,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: 1.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 9.sp,
                                            color: Colors.white.withOpacity(.4),
                                          ),
                                          SizedBox(width: 3.w),
                                          Text(
                                            _timeAgo(comment.createdAt),
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withOpacity(
                                                .45,
                                              ),
                                              fontSize: 9.5.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (onMoreTap != null)
                                  GestureDetector(
                                    onTap: isBusy ? null : onMoreTap,
                                    child: Container(
                                      width: 28.w,
                                      height: 28.w,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(.06),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(.10),
                                        ),
                                      ),
                                      child: isBusy
                                          ? SizedBox(
                                              width: 12.w,
                                              height: 12.w,
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 1.6,
                                                    color: AppColors.yellow,
                                                  ),
                                            )
                                          : Icon(
                                              Icons.more_vert_rounded,
                                              color: Colors.white.withOpacity(
                                                .55,
                                              ),
                                              size: 16.sp,
                                            ),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.format_quote_rounded,
                                    color: Colors.white.withOpacity(.10),
                                    size: 22.sp,
                                  ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(.06),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              comment.comment,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(.85),
                                fontSize: 12.sp,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (100 + index * 60).ms, duration: 350.ms)
        .moveX(begin: 10, end: 0, curve: Curves.easeOutCubic);
  }
}

class _CommentComposer extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final bool isSending;

  const _CommentComposer({required this.onSubmit, this.isSending = false});

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _borderController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _borderController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (widget.isSending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 14.h),
      child: AnimatedBuilder(
        animation: _borderController,
        builder: (context, _) {
          return CustomPaint(
            foregroundPainter: _AnimatedBorderPainter(
              animationValue: _borderController.value,
              radius: 26.r,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.dark.withOpacity(.55),
                        AppColors.primary.withOpacity(.35),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.sky, Color(0xFFB388FF)],
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: LessonDetailCubit.maxCommentLength,
                          textCapitalization: TextCapitalization.sentences,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.5.sp,
                          ),
                          cursorColor: AppColors.yellow,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            counterText: '',
                            hintText: "Write a comment...",
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(.4),
                              fontSize: 12.5.sp,
                            ),
                          ),
                          onSubmitted: (_) => _handleSubmit(),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: _handleSubmit,
                        child: AnimatedContainer(
                          duration: 200.ms,
                          width: 38.w,
                          height: 38.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _hasText
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.orange,
                                      AppColors.yellow,
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(.14),
                                      Colors.white.withOpacity(.08),
                                    ],
                                  ),
                            boxShadow: _hasText
                                ? [
                                    BoxShadow(
                                      color: AppColors.yellow.withOpacity(.5),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : [],
                          ),
                          child: widget.isSending
                              ? Padding(
                                  padding: EdgeInsets.all(9.r),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: _hasText
                                      ? Colors.black
                                      : Colors.white38,
                                  size: 17.sp,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedBorderPainter extends CustomPainter {
  final double animationValue;
  final double radius;

  _AnimatedBorderPainter({required this.animationValue, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final startAngle = animationValue * math.pi * 2;

    final glowPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        colors: const [
          Color(0x00FFD35B),
          Color(0x88FFD35B),
          Color(0x00F5A201),
          Color(0x88A8E8F9),
          Color(0x00B388FF),
          Color(0x88FF6FB5),
          Color(0x00FFD35B),
        ],
        stops: const [0.0, 0.14, 0.32, 0.5, 0.68, 0.86, 1.0],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawRRect(rect.deflate(3.5), glowPaint);

    final borderPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        colors: const [
          Color(0xffA8E8F9),
          Color(0xffFFD35B),
          Color(0xffF5A201),
          Color(0xffB388FF),
          Color(0xffA8E8F9),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(rect.deflate(0.5), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 35});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(7);
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
