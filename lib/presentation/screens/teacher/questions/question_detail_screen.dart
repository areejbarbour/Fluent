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
          SafeArea(
            child: BlocListener<QuestionDeleteCubit, QuestionDeleteState>(
              listener: (context, state) {
                if (state is QuestionDeleteSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.sky,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  );
                  Navigator.pop(context, true);
                } else if (state is QuestionDeleteFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
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
                  if (state is QuestionDetailFailure) {
                    return _buildError(context, state.error);
                  }
                  if (state is QuestionDetailLoaded) {
                    return _buildLoaded(context, state.question);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, Question q) {
    return Column(
      children: [
        SizedBox(height: 12.h),
        _buildTopBar(context, q),
        SizedBox(height: 12.h),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(q),
                SizedBox(height: 18.h),
                if (q.textQuestion != null && q.textQuestion!.isNotEmpty) ...[
                  _buildTextQuestion(q),
                  SizedBox(height: 18.h),
                ],
                if (q.imageUrl != null) ...[
                  _buildImage(q.imageUrl!),
                  SizedBox(height: 18.h),
                ],
                if (q.audioUrl != null) ...[
                  _buildAudio(q.audioUrl!),
                  SizedBox(height: 18.h),
                ],
                _buildAnswers(q),
                SizedBox(height: 18.h),
                _buildMetaRow(q),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
        _buildBottomActions(context, q),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, Question q) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
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
          const Spacer(),
          if (q.previousQuestionId != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.orange.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: AppColors.orange, size: 14.sp),
                  SizedBox(width: 4.w),
                  // Text("New Version",
                  //     style: GoogleFonts.poppins(
                  //         color: AppColors.orange,
                  //         fontSize: 11.sp,
                  //         fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Question q) {
    final color = QuestionUI.typeColor(q.type.value);
    return QuestionUI.glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: color.withOpacity(0.6)),
                ),
                child: Icon(
                  QuestionUI.typeIcon(q.type.value),
                  color: color,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  QuestionUI.typeLabel(q.type.value),
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _titleLine("EN", q.titleQuestionEn, TextDirection.ltr),
          SizedBox(height: 10.h),
          _titleLine("AR", q.titleQuestionAr, TextDirection.rtl),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).moveY(begin: 16, end: 0);
  }

  Widget _titleLine(String tag, String text, TextDirection dir) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
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
                fontSize: 10.sp,
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
                fontSize: 14.sp,
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
    final text = q.textQuestion ?? '';
    final isFill = q.type == QuestionType.fill;
    final baseStyle = GoogleFonts.poppins(
      color: Colors.white,
      fontSize: 14.sp,
      height: 1.6,
    );

    return QuestionUI.glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.short_text, color: AppColors.sky, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                "Question Text",
                style: GoogleFonts.poppins(
                  color: AppColors.sky,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (isFill) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppColors.orange.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    "Fill Mode",
                    style: GoogleFonts.poppins(
                      color: AppColors.orange,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 10.h),
          if (isFill && RegExp(r'\{\d+\}').hasMatch(text))
            _renderFillRich(text, baseStyle, q.answers)
          else
            Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  /// Inlines {1} {2} ... as visual blank chips directly inside the text.
  /// Looks up the answer for each blank number from [answers] (1-based).
  Widget _renderFillRich(
    String text,
    TextStyle baseStyle,
    List<QuestionAnswer> answers,
  ) {
    final blankColor = QuestionUI.typeColor(QuestionType.fill.value);
    final regex = RegExp(r'\{(\d+)\}');
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    String? answerFor(int blankNumber) {
      for (final a in answers) {
        if ((a.blankOrder ?? 0) == blankNumber &&
            a.textAnswer != null &&
            a.textAnswer!.trim().isNotEmpty) {
          return a.textAnswer;
        }
      }
      return null;
    }

    for (final m in regex.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(
          TextSpan(text: text.substring(lastEnd, m.start), style: baseStyle),
        );
      }
      final n = int.tryParse(m.group(1) ?? '') ?? 0;
      if (n > 0) {
        final answer = answerFor(n);
        final hasAnswer = answer != null;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 10.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    constraints: BoxConstraints(minWidth: 60.w),
                    decoration: BoxDecoration(
                      color: hasAnswer
                          ? blankColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border(
                        bottom: BorderSide(color: blankColor, width: 1.6),
                      ),
                    ),
                    child: Text(
                      hasAnswer ? answer : '   ',
                      style: baseStyle.copyWith(
                        color: hasAnswer ? Colors.white : Colors.white54,
                        fontWeight: hasAnswer
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontStyle: hasAnswer
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: blankColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: blankColor.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '$n',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    );
  }

  Widget _buildImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 150.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.white.withOpacity(0.5),
              size: 32.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudio(String url) {
    return QuestionUI.glass(
      borderColor: AppColors.orange.withOpacity(0.4),
      child: AudioPreviewTile(url: url, label: "Audio File"),
    );
  }

  Widget _buildAnswers(Question q) {
    return QuestionUI.glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppColors.yellow, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                "Answers (${q.answers.length})",
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...q.answers.asMap().entries.map((e) {
            final idx = e.key;
            final a = e.value;
            return _answerTile(q.type, idx, a);
          }),
        ],
      ),
    );
  }

  Widget _answerTile(QuestionType type, int idx, QuestionAnswer a) {
    final isCorrect = a.isCorrect == true;
    final color = isCorrect
        ? Colors.greenAccent
        : Colors.white.withOpacity(0.5);
    String main;
    String? sub;
    IconData icon;
    switch (type) {
      case QuestionType.mcq:
        main = a.textAnswer ?? '—';
        sub = isCorrect ? 'Correct' : null;
        icon = isCorrect ? Icons.check_circle : Icons.radio_button_unchecked;
        break;
      case QuestionType.fill:
        main = a.textAnswer ?? '—';
        sub = 'Blank #${a.blankOrder ?? idx + 1}';
        icon = Icons.edit;
        break;
      case QuestionType.arrange:
        main = a.textAnswer ?? '—';
        sub = isCorrect ? 'Correct • Order #${a.order ?? '-'}' : 'Distractor';
        icon = isCorrect ? Icons.check_circle : Icons.shuffle;
        break;
      case QuestionType.pair:
        main = '${a.leftText ?? '—'}  ⇄  ${a.rightText ?? '—'}';
        sub = null;
        icon = Icons.compare_arrows;
        break;
    }
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.greenAccent.withOpacity(0.08)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  main,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (sub != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    sub,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(Question q) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
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
        if (q.hasNextVersion)
          _metaChip(
            icon: Icons.upgrade_rounded,
            label: 'Newer version exists',
            color: AppColors.orange,
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14.sp),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
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

  Widget _buildBottomActions(BuildContext context, Question q) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 18.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
          ),
          child: Row(
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
              SizedBox(width: 8.w),
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
              SizedBox(width: 8.w),
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
                  if (result == true && context.mounted) {
                    context.read<QuestionDetailCubit>().loadQuestion(
                      questionId,
                    );
                  }
                },
              ),
              SizedBox(width: 8.w),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(height: 2.h),
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, Question q) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
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
          "This will permanently delete this question. Are you sure?",
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
}
