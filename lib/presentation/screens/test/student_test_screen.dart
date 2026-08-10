import 'dart:math' as math;
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/student/attempt/student_attempt_cubit.dart';
import 'package:fluent/cubit/student/attempt/student_attempt_state.dart';
import 'package:fluent/data/models/attempt_models.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/data/models/question_type.dart';
import 'package:fluent/data/repository/attempt_repository.dart';
import 'package:fluent/data/repository/level_repository.dart';
import 'package:fluent/data/models/level_model.dart';
import 'package:fluent/presentation/widgets/app_backdrop.dart';
import 'package:fluent/presentation/widgets/fill_answer_widget.dart';
import 'package:fluent/helper/questions/answer_display_helper.dart';
import 'package:fluent/presentation/widgets/arrange_answer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Placement test — same visual language as Word Pulse quiz.
/// Flow: POST /tests/{id}/start → confirm(submit+feedback) → next → finish → review(if passed).
class StudentTestScreen extends StatelessWidget {
  final int testId;
  final String? title;

  /// XP granted by backend on pass (from lesson.xp_points).
  final int xpPoints;

  const StudentTestScreen({
    super.key,
    required this.testId,
    this.title,
    this.xpPoints = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          StudentAttemptCubit(ctx.read<AttemptRepository>())..start(testId),
      child: _StudentTestView(title: title, xpPoints: xpPoints),
    );
  }
}

class _StudentTestView extends StatefulWidget {
  final String? title;
  final int xpPoints;
  const _StudentTestView({this.title, this.xpPoints = 0});

  @override
  State<_StudentTestView> createState() => _StudentTestViewState();
}

class _StudentTestViewState extends State<_StudentTestView> {
  bool _introVisible = false;

  /// Prevents double-pop (listener + WillPop) which briefly reveals the route under the test.
  bool _isExiting = false;
  int? _selectedMcqId;
  List<int> _arrangeOrder = [];
  Map<int, int> _pairMap = {};
  final _fillKey = GlobalKey<FillAnswerWidgetState>();

  /// Local confirm only — API submit happens on Next (backend forbids re-submit).
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
  }

  void _resetLocalAnswer() {
    _selectedMcqId = null;
    _arrangeOrder = [];
    _pairMap = {};
    _confirmed = false;
  }

  Future<void> _onStartPressed() async {
    setState(() => _introVisible = false);
    // already started in BlocProvider; no-op
  }

  bool _hasLocalAnswer(Question q) {
    switch (q.type) {
      case QuestionType.mcq:
        return _selectedMcqId != null;
      case QuestionType.fill:
        final fill = _fillKey.currentState;
        return fill != null && !fill.hasNoPlaceholders && fill.isComplete;
      case QuestionType.arrange:
        return _arrangeOrder.isNotEmpty;
      case QuestionType.pair:
        return _pairMap.length == q.answers.length && q.answers.isNotEmpty;
    }
  }

  /// Confirm = submit to API immediately and show correction (is_correct / score).
  /// Backend forbids re-submit — answer is locked after success.
  Future<void> _onConfirm(StudentAttemptInProgress state) async {
    if (_confirmed || state.submitting) return;

    final q = state.currentQuestion;
    if (!_hasLocalAnswer(q)) {
      switch (q.type) {
        case QuestionType.mcq:
          _snack('Select an option');
          break;
        case QuestionType.fill:
          _snack('Fill all blanks');
          break;
        case QuestionType.arrange:
          _snack('Build the correct sequence (leave extra tiles in the bank)');
          break;
        case QuestionType.pair:
          _snack('Match all pairs');
          break;
      }
      return;
    }

    HapticFeedback.selectionClick();
    final cubit = context.read<StudentAttemptCubit>();
    bool ok = false;

    switch (q.type) {
      case QuestionType.mcq:
        ok = await cubit.submitMcq(_selectedMcqId!);
        break;
      case QuestionType.fill:
        ok = await cubit.submitFill(_fillKey.currentState!.currentAnswers);
        break;
      case QuestionType.arrange:
        ok = await cubit.submitArrange(List<int>.from(_arrangeOrder));
        break;
      case QuestionType.pair:
        ok = await cubit.submitPair(Map<int, int>.from(_pairMap));
        break;
    }

    if (!ok) {
      // Stay editable so user can fix.
      return;
    }

    HapticFeedback.mediumImpact();
    if (mounted) setState(() => _confirmed = true);
  }

  /// Next = advance only after a successful confirm/submit. No re-submit.
  Future<void> _onNext(StudentAttemptInProgress state) async {
    if (!_confirmed) {
      await _onConfirm(state);
      if (!_confirmed) return;
      // After first confirm, stay so user sees the correction feedback.
      return;
    }

    HapticFeedback.selectionClick();
    _resetLocalAnswer();
    context.read<StudentAttemptCubit>().goNext();
  }

  void _goNext(StudentAttemptInProgress state) {
    _resetLocalAnswer();
    context.read<StudentAttemptCubit>().goNext();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isExiting) return false;

    final state = context.read<StudentAttemptCubit>().state;

    // Finished → single pop with result
    if (state is StudentAttemptFinished) {
      _isExiting = true;
      final r = state.result;
      Navigator.of(context).pop(<String, dynamic>{
        'completed': true,
        'passed': r.passed,
        'scorePercent': r.scorePercent,
        'attemptId': r.attemptId,
        'xpEarned': widget.xpPoints,
        'goToLessons': false,
        'goToCourses': false,
      });
      return false;
    }

    // Not in an active attempt → pop once, no intermediate UI
    if (state is! StudentAttemptInProgress) {
      _isExiting = true;
      Navigator.of(
        context,
      ).pop(<String, dynamic>{'completed': false, 'abandoned': true});
      return false;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Leave test?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'If you leave now, this attempt will end. You can try again later.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Stay',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Leave',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (leave == true) {
      _isExiting = true;
      if (mounted) setState(() {}); // empty frame immediately (no intro flash)
      final cubit = context.read<StudentAttemptCubit>();
      try {
        await cubit.leave(); // server abandon while still mounted
      } catch (_) {
        // ignore network errors on exit
      }
      if (mounted) {
        Navigator.of(
          context,
        ).pop(<String, dynamic>{'completed': false, 'abandoned': true});
      }
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.dark,
        body: Stack(
          children: [
            const AppBackdrop(),
            SafeArea(
              child: BlocConsumer<StudentAttemptCubit, StudentAttemptState>(
                listener: (context, state) {
                  void showErr(String msg) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          msg,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }

                  if (state is StudentAttemptFailure) {
                    showErr(state.message);
                  }
                  if (state is StudentAttemptInProgress &&
                      state.inlineError != null &&
                      state.inlineError!.isNotEmpty) {
                    showErr(state.inlineError!);
                  }
                  // Pop is handled by _onWillPop / explicit close — avoid double pop flash
                  if (state is StudentAttemptLeft) {
                    if (!_isExiting && Navigator.canPop(context)) {
                      _isExiting = true;
                      Navigator.pop(context, <String, dynamic>{
                        'completed': false,
                        'abandoned': true,
                      });
                    }
                  }
                },
                builder: (context, state) {
                  if (_introVisible &&
                      state is! StudentAttemptInProgress &&
                      state is! StudentAttemptFinished &&
                      state is! StudentAttemptFinishing) {
                    return _IntroView(
                      loading: state is StudentAttemptStarting,
                      blocked:
                          state is StudentAttemptFailure &&
                          state.isPlacementBlocked,
                      onStart: _onStartPressed,
                    );
                  }

                  if (state is StudentAttemptStarting ||
                      state is StudentAttemptLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.yellow),
                    );
                  }

                  if (state is StudentAttemptInProgress) {
                    return _InProgressView(
                      state: state,
                      selectedMcqId: _selectedMcqId,
                      arrangeOrder: _arrangeOrder,
                      pairMap: _pairMap,
                      fillKey: _fillKey,
                      confirmed: _confirmed,
                      onSelectMcq: (id) => setState(() {
                        _selectedMcqId = id;
                        _confirmed = false;
                      }),
                      onArrangeChanged: (ids) => setState(() {
                        _arrangeOrder = ids;
                        _confirmed = false;
                      }),
                      onPairChanged: (map) => setState(() {
                        _pairMap = map;
                        _confirmed = false;
                      }),
                      onFillChanged: (_) => setState(() => _confirmed = false),
                      onConfirm: () => _onConfirm(state),
                      onNext: () => _onNext(state),
                    );
                  }

                  if (state is StudentAttemptFinishing) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.yellow,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Calculating score...',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is StudentAttemptFinished) {
                    return _FinishedView(
                      state: state,
                      xpPoints: widget.xpPoints,
                    );
                  }

                  if (state is StudentAttemptLeft || _isExiting) {
                    // Stay on dark empty frame while route pops — no intro flash
                    return const SizedBox.expand();
                  }

                  if (state is StudentAttemptFailure) {
                    return _IntroView(
                      loading: false,
                      blocked: state.isPlacementBlocked,
                      onStart: _onStartPressed,
                    );
                  }

                  return _IntroView(loading: false, onStart: _onStartPressed);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Intro (Word Pulse style) ───────────────────────────────

class _IntroView extends StatelessWidget {
  final bool loading;
  final VoidCallback onStart;
  final bool blocked;

  const _IntroView({
    required this.loading,
    required this.onStart,
    this.blocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(<String, dynamic>{'completed': false, 'abandoned': true});
              },
              icon: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.08),
                  border: Border.all(color: Colors.white.withOpacity(.15)),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 18.sp,
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.all(22.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.yellow.withOpacity(0.25),
                  AppColors.orange.withOpacity(0.12),
                ],
              ),
              border: Border.all(color: AppColors.yellow.withOpacity(0.35)),
            ),
            child: Icon(
              Icons.school_rounded,
              color: AppColors.yellow,
              size: 48.sp,
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            'Placement Test',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Answer each question in order. Your score opens the next step on your path.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: (loading || blocked) ? null : onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.dark,
                disabledBackgroundColor: AppColors.yellow.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              child: loading
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.dark,
                      ),
                    )
                  : Text(
                      blocked ? 'Not available' : 'Start test',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── In progress ────────────────────────────────────────────

class _InProgressView extends StatelessWidget {
  final StudentAttemptInProgress state;
  final int? selectedMcqId;
  final List<int> arrangeOrder;
  final Map<int, int> pairMap;
  final GlobalKey<FillAnswerWidgetState> fillKey;
  final bool confirmed;
  final ValueChanged<int> onSelectMcq;
  final ValueChanged<List<int>> onArrangeChanged;
  final ValueChanged<Map<int, int>> onPairChanged;
  final ValueChanged<Map<int, String>>? onFillChanged;
  final VoidCallback onConfirm;
  final VoidCallback onNext;

  const _InProgressView({
    required this.state,
    required this.selectedMcqId,
    required this.arrangeOrder,
    required this.pairMap,
    required this.fillKey,
    required this.confirmed,
    required this.onSelectMcq,
    required this.onArrangeChanged,
    required this.onPairChanged,
    this.onFillChanged,
    required this.onConfirm,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final q = state.currentQuestion;
    final total = state.questions.length;
    final current = state.currentIndex;
    final locked = state.submitting || confirmed;
    final feedback = state.lastSubmit;

    return Column(
      children: [
        _TopBar(
          current: current + 1,
          total: total,
          title: state.test.title.isNotEmpty ? state.test.title : 'Test',
        ),
        SizedBox(height: 6.h),
        _SegmentProgress(
          total: total,
          currentIndex: current,
          answeredIds: state.answeredQuestionIds,
          questions: state.questions,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
            physics: const BouncingScrollPhysics(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.94,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey(q.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuestionCard(question: q),
                  SizedBox(height: 18.h),
                  _AnswerArea(
                    question: q,
                    locked: locked,
                    selectedMcqId: selectedMcqId,
                    arrangeOrder: arrangeOrder,
                    pairMap: pairMap,
                    fillKey: fillKey,
                    onSelectMcq: onSelectMcq,
                    onArrangeChanged: onArrangeChanged,
                    onPairChanged: onPairChanged,
                    onFillChanged: onFillChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 16.h),
          child: Column(
            children: [
              if (confirmed && !state.submitting && feedback != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _AnswerFeedbackBanner(result: feedback, question: q),
                ),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: state.submitting
                      ? null
                      : (confirmed ? onNext : onConfirm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.dark,
                    disabledBackgroundColor: AppColors.yellow.withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: state.submitting
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.dark,
                          ),
                        )
                      : Text(
                          confirmed
                              ? (state.isLast ? 'Finish' : 'Next')
                              : 'Confirm',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.sp,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswerFeedbackBanner extends StatelessWidget {
  final SubmitAnswerResult result;
  final Question question;

  const _AnswerFeedbackBanner({required this.result, required this.question});

  @override
  Widget build(BuildContext context) {
    final ok = result.isCorrect;
    final color = ok ? const Color(0xFF2ECC71) : AppColors.orange;
    final icon = ok ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title = ok ? 'Correct!' : 'Not quite';
    final detail = '${result.score}/${result.maxScore} pts';

    String? correctLine;
    if (!ok && result.correctAnswer != null) {
      correctLine = AnswerDisplayHelper.format(
        answer: result.correctAnswer,
        question: question,
      );
    }

    String? yoursLine;
    if (!ok && result.rawAnswer != null) {
      // rawAnswer is UserAttemptAnswer row; submitted payload is answer_json
      final aj = result.rawAnswer!['answer_json'] ?? result.rawAnswer;
      yoursLine = AnswerDisplayHelper.format(answer: aj, question: question);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      detail,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (yoursLine != null && yoursLine.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'Your answer: $yoursLine',
              style: GoogleFonts.poppins(
                color: Colors.redAccent.shade100,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (correctLine != null && correctLine.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Correct: $correctLine',
              style: GoogleFonts.poppins(
                color: Colors.greenAccent,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int current;
  final int total;
  final String title;

  const _TopBar({
    required this.current,
    required this.total,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 14.w, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.08),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 18.sp,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson Test',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.yellow.withOpacity(0.35)),
            ),
            child: Text(
              '$current / $total',
              style: GoogleFonts.poppins(
                color: AppColors.yellow,
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress like Word Pulse — no green/red (no per-question reveal).
class _SegmentProgress extends StatelessWidget {
  final int total;
  final int currentIndex;
  final Set<int> answeredIds;
  final List<Question> questions;

  const _SegmentProgress({
    required this.total,
    required this.currentIndex,
    required this.answeredIds,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: List.generate(total, (i) {
          final answered =
              i < questions.length && answeredIds.contains(questions[i].id);
          Color color;
          double height = 5.h;

          if (answered) {
            color = AppColors.sky.withOpacity(0.85);
          } else if (i == currentIndex) {
            color = AppColors.yellow;
            height = 8.h;
          } else {
            color = Colors.white.withOpacity(.12);
          }

          return Expanded(
            child: AnimatedContainer(
              duration: 280.ms,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4.r),
                boxShadow: i == currentIndex
                    ? [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(0.35),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final title = question.titleQuestionEn.isNotEmpty
        ? question.titleQuestionEn
        : question.titleQuestionAr;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 22.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.orange.withOpacity(0.35)),
            ),
            child: Text(
              question.type.name.toUpperCase(),
              style: GoogleFonts.poppins(
                color: AppColors.orange,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if ((question.textQuestion ?? '').trim().isNotEmpty &&
              question.type != QuestionType.fill) ...[
            SizedBox(height: 10.h),
            Text(
              question.textQuestion!,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerArea extends StatelessWidget {
  final Question question;
  final bool locked;
  final int? selectedMcqId;
  final List<int> arrangeOrder;
  final Map<int, int> pairMap;
  final GlobalKey<FillAnswerWidgetState> fillKey;
  final ValueChanged<int> onSelectMcq;
  final ValueChanged<List<int>> onArrangeChanged;
  final ValueChanged<Map<int, int>> onPairChanged;
  final ValueChanged<Map<int, String>>? onFillChanged;

  const _AnswerArea({
    required this.question,
    required this.locked,
    required this.selectedMcqId,
    required this.arrangeOrder,
    required this.pairMap,
    required this.fillKey,
    required this.onSelectMcq,
    required this.onArrangeChanged,
    required this.onPairChanged,
    this.onFillChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.mcq:
        return Column(
          children: [
            for (var i = 0; i < question.answers.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _OptionTile(
                  badge: String.fromCharCode(65 + i),
                  text: question.answers[i].textAnswer ?? '',
                  selected: selectedMcqId == question.answers[i].id,
                  enabled: !locked,
                  onTap: () {
                    final id = question.answers[i].id;
                    if (id != null) {
                      HapticFeedback.selectionClick();
                      onSelectMcq(id);
                    }
                  },
                ),
              ),
          ],
        );

      case QuestionType.fill:
        return FillAnswerWidget(
          key: fillKey,
          textQuestion: question.textQuestion,
          readOnly: locked,
          onChanged: onFillChanged,
        );

      case QuestionType.arrange:
        return ArrangeAnswerWidget(
          key: ValueKey('arrange-${question.id}'),
          question: question,
          initialAnswerOrder: arrangeOrder.isEmpty ? null : arrangeOrder,
          readOnly: locked,
          onChanged: onArrangeChanged,
        );

      case QuestionType.pair:
        final answers = question.answers.where((a) => a.id != null).toList();
        // Stable but strong shuffle per question — lefts and rights use different seeds
        // so matching by row order is never the correct solution.
        final lefts = List.of(answers);
        final rightOptions = List.of(answers);
        lefts.shuffle(math.Random(question.id * 7919 + 17));
        rightOptions.shuffle(math.Random(question.id * 9973 + 42));
        return Column(
          children: [
            for (final left in lefts)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          left.leftText ?? left.textAnswer ?? '',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: pairMap[left.id],
                        dropdownColor: AppColors.dark,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.07),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: Text(
                          'Match',
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 12.sp,
                          ),
                        ),
                        items: [
                          for (final r in rightOptions)
                            DropdownMenuItem(
                              value: r.id,
                              // يمنع اختيار نفس الكلمة مرتين (إلا إذا كانت هي المختارة حالياً لهذا الصف)
                              enabled:
                                  !pairMap.values.contains(r.id) ||
                                  pairMap[left.id] == r.id,
                              child: Text(
                                r.rightText ?? r.textAnswer ?? '#${r.id}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white, // كل الكلمات نفس الدرجة
                                  fontSize: 12.sp,
                                  decoration: pairMap.values.contains(r.id)
                                      ? TextDecoration
                                            .lineThrough // الكلمة المختارة تتشطب
                                      : TextDecoration.none,
                                  decorationColor: Colors.white70,
                                  decorationThickness: 1.6,
                                ),
                              ),
                            ),
                        ],
                        onChanged: locked
                            ? null
                            : (v) {
                                if (v == null || left.id == null) return;
                                final next = Map<int, int>.from(pairMap);
                                next[left.id!] = v;
                                onPairChanged(next);
                              },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }
}

class _OptionTile extends StatelessWidget {
  final String badge;
  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionTile({
    required this.badge,
    required this.text,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: selected
                ? AppColors.yellow.withOpacity(0.14)
                : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: selected
                  ? AppColors.yellow.withOpacity(0.7)
                  : Colors.white.withOpacity(0.12),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.yellow.withOpacity(0.25)
                      : Colors.white.withOpacity(0.08),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    color: selected ? AppColors.yellow : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Finished ───────────────────────────────────────────────

class _FinishedView extends StatefulWidget {
  final StudentAttemptFinished state;
  final int xpPoints;
  const _FinishedView({required this.state, this.xpPoints = 0});

  @override
  State<_FinishedView> createState() => _FinishedViewState();
}

class _FinishedViewState extends State<_FinishedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Map<String, dynamic> _resultPayload({
    bool goToLessons = false,
    bool goToCourses = false,
    bool goToLevels = false,
  }) {
    final r = widget.state.result;
    final t = widget.state.test;
    final source = t.isLevel
        ? 'level'
        : (t.isCourse ? 'course' : (t.isLesson ? 'lesson' : t.type));
    return <String, dynamic>{
      'completed': true,
      'passed': r.passed,
      'scorePercent': r.scorePercent,
      'attemptId': r.attemptId,
      'xpEarned': widget.xpPoints,
      'goToLessons': goToLessons,
      'goToCourses': goToCourses,
      'goToLevels': goToLevels,
      'source': source,
    };
  }

  void _popToLesson() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_resultPayload());
  }

  /// Passed: lesson → course lessons list; course → level courses list.
  void _onContinue() {
    HapticFeedback.lightImpact();
    final t = widget.state.test;
    Navigator.of(context).pop(
      _resultPayload(
        goToLessons: t.isLesson,
        goToCourses: t.isCourse,
        goToLevels: t.isLevel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.state.result;
    final review = widget.state.review;
    final passing = widget.state.test.passingScore;
    final passed = r.passed;

    final accent = passed ? AppColors.yellow : AppColors.orange;
    final title = passed ? 'Great job!' : 'Not this time';
    final xp = widget.xpPoints;
    final isCourse = widget.state.test.isCourse;
    final isLevel = widget.state.test.isLevel;
    final subtitle = passed
        ? (isLevel
              ? 'Level complete — higher levels can unlock based on your progress.'
              : (isCourse
                    ? 'Course complete — the next course in your level is now unlocked.'
                    : (xp > 0
                          ? 'Outstanding work — this lesson is complete and +$xp XP is now on your profile.'
                          : 'Outstanding work — this lesson is complete and your next lesson is ready.')))
        : (isLevel
              ? 'You scored below the passing mark. Review the courses in this level, then try again.'
              : (isCourse
                    ? 'You scored below the passing mark. Review the course lessons, then try the final test again.'
                    : 'You scored below the passing mark. Review the video and vocabulary, then try again when you are ready.'));

    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
        child: Column(
          children: [
            // Top bar
            Row(
              children: [
                Material(
                  color: Colors.white.withOpacity(0.08),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _popToLesson,
                    child: SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: accent.withOpacity(0.4)),
                  ),
                  child: Text(
                    passed ? 'PASSED' : 'FAILED',
                    style: GoogleFonts.poppins(
                      color: accent,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 12.h),
                    ScaleTransition(
                      scale: _scale,
                      child: _ScoreHero(
                        percent: r.scorePercent,
                        passed: passed,
                        accent: accent,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    _StatsRow(
                      score: r.scorePercent,
                      passing: passing,
                      passed: passed,
                    ),
                    if (passed) ...[
                      SizedBox(height: 16.h),
                      _SuccessBanner(
                        xpPoints: xp,
                        isCourse: isCourse,
                        isLevel: isLevel,
                      ),
                    ],

                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),

            // Dynamic CTA
            if (passed) ...[
              if (review != null && review.wrongAnswers.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton(
                    onPressed: _openReviewSheet,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.28)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      passed ? 'Review your answers' : 'Review your mistakes',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.dark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.state.test.isLevel
                            ? 'Back to levels'
                            : (widget.state.test.isCourse
                                  ? 'Continue to courses'
                                  : 'Continue learning'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_rounded, size: 20.sp),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: _popToLesson,
                child: Text(
                  widget.state.test.isLevel
                      ? 'Back to courses'
                      : (widget.state.test.isCourse
                            ? 'Back to course'
                            : 'Back to lesson'),
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: _popToLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        widget.state.test.isLevel
                            ? 'Back to courses'
                            : (widget.state.test.isCourse
                                  ? 'Back to course'
                                  : 'Back to lesson'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Retake when you are ready — your progress is saved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openReviewSheet() {
    final review = widget.state.review;
    if (review == null || review.wrongAnswers.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 8.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.state.result.passed
                                ? 'Review your answers'
                                : 'Review your mistakes',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                            size: 22.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                      itemCount: review.wrongAnswers.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (_, i) {
                        final w = review.wrongAnswers[i];
                        return _MistakeCard(
                          index: i + 1,
                          questionText: w.questionText,
                          yours: _fmtAnswer(w.questionId, w.submittedAnswer),
                          correct: _fmtAnswer(w.questionId, w.correctAnswer),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmtAnswer(int questionId, dynamic answer) {
    Question? q;
    for (final item in widget.state.test.questions) {
      if (item.id == questionId) {
        q = item;
        break;
      }
    }
    return AnswerDisplayHelper.format(answer: answer, question: q);
  }
}

class _ScoreHero extends StatelessWidget {
  final int percent;
  final bool passed;
  final Color accent;

  const _ScoreHero({
    required this.percent,
    required this.passed,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148.w,
      height: 148.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 148.w,
            height: 148.w,
            child: CircularProgressIndicator(
              value: (percent.clamp(0, 100)) / 100.0,
              strokeWidth: 8.w,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: accent,
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 112.w,
            height: 112.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent.withOpacity(0.22), accent.withOpacity(0.06)],
              ),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed
                      ? Icons.emoji_events_rounded
                      : Icons.trending_up_rounded,
                  color: accent,
                  size: 28.sp,
                ),
                SizedBox(height: 2.h),
                Text(
                  '$percent%',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
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

class _StatsRow extends StatelessWidget {
  final int score;
  final int passing;
  final bool passed;

  const _StatsRow({
    required this.score,
    required this.passing,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: 'Your score',
              value: '$score%',
              color: passed ? AppColors.yellow : AppColors.orange,
            ),
          ),
          Container(width: 1, height: 36.h, color: Colors.white12),
          Expanded(
            child: _StatCell(
              label: 'To pass',
              value: '$passing%',
              color: Colors.white70,
            ),
          ),
          Container(width: 1, height: 36.h, color: Colors.white12),
          Expanded(
            child: _StatCell(
              label: 'Status',
              value: passed ? 'Passed' : 'Failed',
              color: passed ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final int xpPoints;
  final bool isCourse;
  final bool isLevel;
  const _SuccessBanner({
    this.xpPoints = 0,
    this.isCourse = false,
    this.isLevel = false,
  });

  @override
  Widget build(BuildContext context) {
    final xpLabel = xpPoints > 0 ? '+$xpPoints XP' : 'XP';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          colors: [
            AppColors.yellow.withOpacity(0.18),
            AppColors.sky.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: AppColors.yellow.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.yellow.withOpacity(0.2),
            ),
            child: Icon(
              Icons.lock_open_rounded,
              color: AppColors.yellow,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLevel
                      ? 'Level complete'
                      : (isCourse
                            ? 'Next course unlocked'
                            : 'Next lesson unlocked'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isLevel
                      ? 'Keep going — new levels open as you progress'
                      : (isCourse
                            ? 'Great progress — the next course is ready for you'
                            : (xpPoints > 0
                                  ? '$xpLabel earned · keep your streak going'
                                  : 'Nice work · keep your streak going')),
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          if (xpPoints > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.yellow.withOpacity(0.45)),
              ),
              child: Text(
                xpLabel,
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final int index;
  final String questionText;
  final String yours;
  final String correct;

  const _MistakeCard({
    required this.index,
    required this.questionText,
    required this.yours,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q$index · $questionText',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Yours: $yours',
            style: GoogleFonts.poppins(
              color: Colors.redAccent.shade100,
              fontSize: 11.sp,
            ),
          ),
          Text(
            'Correct: $correct',
            style: GoogleFonts.poppins(
              color: Colors.greenAccent.shade200,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}
