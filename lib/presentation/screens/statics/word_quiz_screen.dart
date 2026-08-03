import 'package:audioplayers/audioplayers.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/word_quiz/word_quiz_cubit.dart';
import 'package:fluent/cubit/student/word_quiz/word_quiz_state.dart';
import 'package:fluent/data/models/word_quiz_model.dart';
import 'package:fluent/data/repository/word_quiz_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen MCQ quiz powered by backend:
/// GET /api/words/quiz + POST /api/words/{id}/quiz_check
class WordQuizScreen extends StatelessWidget {
  const WordQuizScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (ctx) =>
              WordQuizCubit(ctx.read<WordQuizRepository>())..loadQuiz(),
          child: const WordQuizScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B2A3A), AppColors.dark, Color(0xFF012A3F)],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<WordQuizCubit, WordQuizState>(
            builder: (context, state) {
              if (state is WordQuizLoading || state is WordQuizInitial) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.yellow),
                );
              }
              if (state is WordQuizEmpty) {
                return _EmptyView(message: state.message);
              }
              if (state is WordQuizFailure) {
                return _ErrorView(
                  message: state.message,
                  onRetry: () => context.read<WordQuizCubit>().loadQuiz(),
                );
              }
              if (state is WordQuizFinished) {
                return _ResultsView(state: state);
              }
              if (state is WordQuizInProgress) {
                return _QuizBody(state: state);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _QuizBody extends StatelessWidget {
  final WordQuizInProgress state;
  const _QuizBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final q = state.current;
    final progress = (state.currentIndex + 1) / state.total;

    return Column(
      children: [
        _TopBar(
          current: state.currentIndex + 1,
          total: state.total,
          correct: state.correctCount,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.h,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _QuestionCard(question: q),
                SizedBox(height: 20.h),
                ...q.options.map((opt) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _OptionTile(
                      option: opt,
                      selectedId: state.selectedOptionId,
                      result: state.lastResult,
                      enabled: !state.hasAnswered && !state.isChecking,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.read<WordQuizCubit>().selectOption(opt.id);
                      },
                    ),
                  );
                }),
                if (state.lastResult != null) ...[
                  SizedBox(height: 8.h),
                  _FeedbackBanner(result: state.lastResult!),
                ],
              ],
            ),
          ),
        ),
        _BottomActions(state: state),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final int current;
  final int total;
  final int correct;

  const _TopBar({
    required this.current,
    required this.total,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 16.w, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
          Expanded(
            child: Text(
              'Word Quiz',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '$current / $total',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFF22C55E).withOpacity(0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  color: const Color(0xFF4ADE80),
                  size: 14.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  '$correct',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF86EFAC),
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
}

class _QuestionCard extends StatefulWidget {
  final WordQuizQuestion question;
  const _QuestionCard({required this.question});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final url = widget.question.audio;
    if (url == null || url.isEmpty) return;
    setState(() => _playing = true);
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
      await _player.onPlayerComplete.first;
    } catch (_) {
      // ignore play errors
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: AppColors.sky.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'What is the translation?',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            q.question,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (q.hasAudio) ...[
            SizedBox(height: 18.h),
            GestureDetector(
              onTap: _playing ? null : _play,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _playing
                          ? Icons.graphic_eq_rounded
                          : Icons.volume_up_rounded,
                      color: AppColors.orange,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _playing ? 'Playing…' : 'Listen',
                      style: GoogleFonts.poppins(
                        color: AppColors.orange,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final WordQuizOption option;
  final int? selectedId;
  final WordQuizCheckResult? result;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.selectedId,
    required this.result,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == option.id;
    final answered = result != null;

    Color border;
    Color bg;
    Color textColor = Colors.white;

    if (answered) {
      final isCorrectOption = result!.correct
          ? option.id == selectedId
          : option.id == result!.correctAnswerId;
      final isWrongSelected = !result!.correct && option.id == selectedId;

      if (isCorrectOption) {
        border = const Color(0xFF4ADE80);
        bg = const Color(0xFF22C55E).withOpacity(0.18);
        textColor = const Color(0xFF86EFAC);
      } else if (isWrongSelected) {
        border = Colors.redAccent;
        bg = Colors.redAccent.withOpacity(0.15);
        textColor = Colors.red.shade200;
      } else {
        border = Colors.white.withOpacity(0.08);
        bg = Colors.white.withOpacity(0.04);
        textColor = Colors.white38;
      }
    } else if (isSelected) {
      border = AppColors.yellow;
      bg = AppColors.yellow.withOpacity(0.14);
    } else {
      border = Colors.white.withOpacity(0.12);
      bg = Colors.white.withOpacity(0.05);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: border,
              width: isSelected || answered ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (answered &&
                  ((result!.correct && option.id == selectedId) ||
                      (!result!.correct &&
                          option.id == result!.correctAnswerId)))
                Icon(
                  Icons.check_circle_rounded,
                  color: const Color(0xFF4ADE80),
                  size: 20.sp,
                )
              else if (answered && !result!.correct && option.id == selectedId)
                Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20.sp)
              else if (isSelected)
                Icon(
                  Icons.radio_button_checked,
                  color: AppColors.yellow,
                  size: 20.sp,
                )
              else
                Icon(Icons.circle_outlined, color: Colors.white24, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final WordQuizCheckResult result;
  const _FeedbackBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final ok = result.correct;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ok
            ? const Color(0xFF22C55E).withOpacity(0.12)
            : Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ok
              ? const Color(0xFF4ADE80).withOpacity(0.4)
              : Colors.redAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.celebration_rounded : Icons.info_outline_rounded,
            color: ok ? const Color(0xFF4ADE80) : Colors.redAccent,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              result.message,
              style: GoogleFonts.poppins(
                color: ok ? const Color(0xFF86EFAC) : Colors.red.shade200,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final WordQuizInProgress state;
  const _BottomActions({required this.state});

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        state.selectedOptionId != null &&
        !state.hasAnswered &&
        !state.isChecking;
    final canNext = state.hasAnswered;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: state.isChecking
              ? null
              : canNext
              ? () {
                  HapticFeedback.lightImpact();
                  context.read<WordQuizCubit>().nextQuestion();
                }
              : canSubmit
              ? () {
                  HapticFeedback.mediumImpact();
                  context.read<WordQuizCubit>().submitAnswer();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellow,
            disabledBackgroundColor: AppColors.yellow.withOpacity(0.35),
            foregroundColor: AppColors.dark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            elevation: 0,
          ),
          child: state.isChecking
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.dark,
                  ),
                )
              : Text(
                  canNext
                      ? (state.isLast ? 'See results' : 'Next question')
                      : 'Check answer',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final WordQuizFinished state;
  const _ResultsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final pct = (state.accuracy * 100).round();
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
          ),
          const Spacer(),
          Container(
            width: 110.w,
            height: 110.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.yellow.withOpacity(0.3),
                  AppColors.orange.withOpacity(0.15),
                ],
              ),
              border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                '$pct%',
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            pct >= 80
                ? 'Excellent!'
                : pct >= 50
                ? 'Good job!'
                : 'Keep practicing!',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${state.correctCount} correct · ${state.wrongCount} wrong · ${state.total} total',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13.sp),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: () => context.read<WordQuizCubit>().restart(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'Try again',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back to Word Bank',
              style: GoogleFonts.poppins(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.white38, size: 48.sp),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 20.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Back',
                style: GoogleFonts.poppins(color: AppColors.yellow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48.sp,
            ),
            SizedBox(height: 14.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.dark,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
