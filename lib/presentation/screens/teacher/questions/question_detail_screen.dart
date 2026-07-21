import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/teacher/questions/delete/question_delete_cubit.dart';
import 'package:fluent/cubit/teacher/questions/delete/question_delete_state.dart';
import 'package:fluent/cubit/teacher/questions/detail/question_detail_cubit.dart';
import 'package:fluent/cubit/teacher/questions/detail/question_detail_state.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/data/models/question_type.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:fluent/presentation/widgets/audio_preview_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'blocking_tests_screen.dart';
import 'question_form_screen.dart';
import 'question_status_screen.dart';

class QuestionDetailScreen extends StatelessWidget {
  final int questionId;
  const QuestionDetailScreen({super.key, required this.questionId});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) =>
              QuestionDetailCubit(ctx.read<QuestionRepository>())
                ..loadQuestion(questionId),
        ),
        BlocProvider(
          create: (ctx) => QuestionDeleteCubit(ctx.read<QuestionRepository>()),
        ),
      ],
      child: _QuestionDetailView(questionId: questionId),
    );
  }
}

class _QuestionDetailView extends StatelessWidget {
  final int questionId;
  const _QuestionDetailView({required this.questionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: BlocListener<QuestionDeleteCubit, QuestionDeleteState>(
              listener: (context, state) {
                if (state is QuestionDeleteSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.sky,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context, true);
                } else if (state is QuestionDeleteFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: BlocBuilder<QuestionDetailCubit, QuestionDetailState>(
                builder: (context, state) {
                  if (state is QuestionDetailLoading ||
                      state is QuestionDetailInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.yellow),
                    );
                  }
                  if (state is QuestionDetailFailure)
                    return _buildError(context, state.error);
                  if (state is QuestionDetailLoaded)
                    return _buildLoaded(context, state.question);
                  return const SizedBox.shrink();
                },
              ),
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
        child: QuestionUI.glowingCircle(AppColors.sky, 300.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(-20, 10),
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
              end: const Offset(15, -15),
              duration: 6000.ms,
            ),
      ),
    ],
  );

  Widget _buildLoaded(BuildContext context, Question q) {
    return Column(
      children: [
        SizedBox(height: 10.h),
        _buildTopBar(context),
        SizedBox(height: 10.h),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(q),
                SizedBox(height: 14.h),
                if (q.textQuestion != null && q.textQuestion!.isNotEmpty) ...[
                  _buildTextQuestion(q),
                  SizedBox(height: 14.h),
                ],
                if (q.imageUrl != null) ...[
                  _buildImage(q.imageUrl!),
                  SizedBox(height: 14.h),
                ],
                if (q.audioUrl != null) ...[
                  _buildAudio(q.audioUrl!),
                  SizedBox(height: 14.h),
                ],
                _buildAnswers(q),
                SizedBox(height: 14.h),
                _buildMetaRow(q),
                SizedBox(height: 90.h),
              ],
            ),
          ),
        ),
        _buildBottomActions(context, q),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: AppColors.yellow.withOpacity(0.25),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
          ),
          child: Icon(
            Icons.quiz_outlined,
            color: AppColors.yellow,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              "Question Details",
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: AppColors.sky.withOpacity(0.7), blurRadius: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildHeader(Question q) {
    final color = QuestionUI.typeColor(q.type.value);
    return QuestionUI.glass(
      radius: 16,
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: color.withOpacity(0.6)),
                ),
                child: Icon(
                  QuestionUI.typeIcon(q.type.value),
                  color: color,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  QuestionUI.typeLabel(q.type.value),
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _titleLine("EN", q.titleQuestionEn, TextDirection.ltr),
          SizedBox(height: 8.h),
          _titleLine("AR", q.titleQuestionAr, TextDirection.rtl),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).moveY(begin: 16, end: 0);
  }

  Widget _titleLine(String tag, String text, TextDirection dir) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.25),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              tag,
              style: GoogleFonts.poppins(
                color: AppColors.yellow,
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textDirection: dir,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextQuestion(Question q) {
    return QuestionUI.glass(
      radius: 16,
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.short_text, color: AppColors.sky, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                "Question Text",
                style: GoogleFonts.poppins(
                  color: AppColors.sky,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            q.textQuestion ?? '',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) => ClipRRect(
    borderRadius: BorderRadius.circular(16.r),
    child: Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 130.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          Icons.broken_image,
          color: Colors.white.withOpacity(0.5),
          size: 28.sp,
        ),
      ),
    ),
  );

  Widget _buildAudio(String url) => QuestionUI.glass(
    radius: 16,
    borderColor: AppColors.orange.withOpacity(0.4),
    child: AudioPreviewTile(url: url, label: "Audio File"),
  );

  Widget _buildAnswers(Question q) {
    return QuestionUI.glass(
      radius: 16,
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppColors.yellow, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                "Answers (${q.answers.length})",
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...q.answers.asMap().entries.map(
            (e) => _answerTile(q.type, e.key, e.value),
          ),
        ],
      ),
    );
  }

  Widget _answerTile(QuestionType type, int idx, QuestionAnswer a) {
    final isCorrect = a.isCorrect == true;
    final color = isCorrect
        ? Colors.greenAccent
        : Colors.white.withOpacity(0.5);
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.greenAccent.withOpacity(0.08)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              a.textAnswer ?? '—',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(Question q) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: [
        _metaChip(
          icon: Icons.signal_cellular_alt,
          label: q.difficulty.value,
          color: QuestionUI.difficultyColor(q.difficulty.value),
        ),
        _metaChip(
          icon: Icons.star_rounded,
          label: '${q.score} points',
          color: AppColors.yellow,
        ),
      ],
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13.sp),
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

  // ✅ استخدام Wrap بدلاً من Row لمنع التداخل
  Widget _buildBottomActions(BuildContext context, Question q) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
          ),
          child: Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              _actionBtn(
                icon: Icons.bolt,
                label: 'Status',
                color: AppColors.sky,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuestionStatusScreen(questionId: q.id),
                  ),
                ),
              ),
              _actionBtn(
                icon: Icons.block,
                label: 'Blocking',
                color: AppColors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlockingTestsScreen(questionId: q.id),
                  ),
                ),
              ),
              _actionBtn(
                icon: Icons.edit,
                label: 'Edit',
                color: AppColors.yellow,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionFormScreen(questionId: q.id),
                    ),
                  );
                  if (result == true && context.mounted)
                    context.read<QuestionDetailCubit>().loadQuestion(
                      questionId,
                    );
                },
              ),
              _actionBtn(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Colors.redAccent,
                onTap: () => _confirmDelete(context, q),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15.sp),
            SizedBox(width: 5.w),
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, Question q) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          "Delete Question?",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          "This will permanently delete this question.",
          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: AppColors.sky),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<QuestionDeleteCubit>().deleteQuestion(q.id);
            },
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ],
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
            onPressed: () =>
                context.read<QuestionDetailCubit>().loadQuestion(questionId),
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
