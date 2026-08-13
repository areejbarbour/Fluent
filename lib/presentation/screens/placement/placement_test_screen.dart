import 'dart:math' as math;
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/placement/placement_attempt_cubit.dart';
import 'package:fluent/cubit/placement/placement_attempt_state.dart';
import 'package:fluent/data/models/attempt_models.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/data/models/question_type.dart';
import 'package:fluent/data/repository/attempt_repository.dart';
import 'package:fluent/data/repository/level_repository.dart';
import 'package:fluent/data/models/level_model.dart';
import 'package:fluent/presentation/widgets/app_backdrop.dart';
import 'package:fluent/presentation/widgets/applogo.dart';
import 'package:fluent/presentation/widgets/arrange_answer_widget.dart';
import 'package:fluent/presentation/widgets/fill_answer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PlacementTestScreen extends StatelessWidget {
  final bool showIntro;

  const PlacementTestScreen({super.key, this.showIntro = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => PlacementAttemptCubit(ctx.read<AttemptRepository>()),
      child: _PlacementTestView(showIntro: showIntro),
    );
  }
}

class _PlacementTestView extends StatefulWidget {
  final bool showIntro;
  const _PlacementTestView({required this.showIntro});

  @override
  State<_PlacementTestView> createState() => _PlacementTestViewState();
}

class _PlacementTestViewState extends State<_PlacementTestView> {
  bool _introVisible = true;
  int? _selectedMcqId;
  List<int> _arrangeOrder = [];
  Map<int, int> _pairMap = {};
  final _fillKey = GlobalKey<FillAnswerWidgetState>();

  /// Local confirm only — API submit happens on Next (backend forbids re-submit).
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _introVisible = widget.showIntro;
  }

  void _resetLocalAnswer() {
    _selectedMcqId = null;
    _arrangeOrder = [];
    _pairMap = {};
    _confirmed = false;
  }

  Future<void> _onStartPressed() async {
    setState(() => _introVisible = false);
    await context.read<PlacementAttemptCubit>().startPlacement();
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

  void _onConfirm(PlacementAttemptInProgress state) {
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
          _snack('Build the correct sequence');
          break;
        case QuestionType.pair:
          _snack('Match all pairs');
          break;
      }
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _confirmed = true);
  }

  Future<void> _onNext(PlacementAttemptInProgress state) async {
    if (!_confirmed) {
      _onConfirm(state);
      if (!_confirmed) return;
    }

    final cubit = context.read<PlacementAttemptCubit>();
    final q = state.currentQuestion;
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
      setState(() => _confirmed = false);
      return;
    }

    HapticFeedback.mediumImpact();
    _resetLocalAnswer();
    cubit.goNext();
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

  Future<void> _goAfterLeave(BuildContext context) async {
    try {
      final repo = context.read<LevelRepository>();
      final res = await repo.getStudentLevels();
      if (!context.mounted) return;
      if (res['success'] == true && res['data'] is StudentLevelsModel) {
        final data = res['data'] as StudentLevelsModel;
        final alreadyPlaced =
            data.currentLevel != null ||
            data.completedLevels.isNotEmpty ||
            data.availableLevels.isNotEmpty;
        if (alreadyPlaced) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(studentHomeRoute, (route) => false);
          return;
        }
      }
    } catch (_) {}
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(placementTestDialogRoute, (route) => false);
  }

  Future<bool> _onWillPop() async {
    final state = context.read<PlacementAttemptCubit>().state;
    if (state is! PlacementAttemptInProgress) return true;

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
          'Leaving abandons this attempt. Retake follows server cooldown rules.',
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
      await context.read<PlacementAttemptCubit>().leave();
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
              child: BlocConsumer<PlacementAttemptCubit, PlacementAttemptState>(
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

                  if (state is PlacementAttemptFailure) {
                    showErr(state.message);
                  }
                  if (state is PlacementAttemptInProgress &&
                      state.inlineError != null &&
                      state.inlineError!.isNotEmpty) {
                    showErr(state.inlineError!);
                  }
                  if (state is PlacementAttemptLeft) {
                    _goAfterLeave(context);
                  }
                },
                builder: (context, state) {
                  if (_introVisible &&
                      state is! PlacementAttemptInProgress &&
                      state is! PlacementAttemptFinished &&
                      state is! PlacementAttemptFinishing) {
                    return _IntroView(
                      loading: state is PlacementAttemptStarting,
                      blocked:
                          state is PlacementAttemptFailure &&
                          state.isPlacementBlocked,
                      onStart: _onStartPressed,
                    );
                  }

                  if (state is PlacementAttemptStarting ||
                      state is PlacementAttemptLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.yellow),
                    );
                  }

                  if (state is PlacementAttemptInProgress) {
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

                  if (state is PlacementAttemptFinishing) {
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

                  if (state is PlacementAttemptFinished) {
                    return _FinishedView(state: state);
                  }

                  if (state is PlacementAttemptFailure) {
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                  placementTestDialogRoute,
                  (route) => false,
                );
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
          AppLogo(size: 120.r),
          SizedBox(height: 24.h),
          Text(
            'Placement Test',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Welcome! A short assessment to discover your level and unlock the learning path that fits you best.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 13.5.sp,
              height: 1.55,
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
  final PlacementAttemptInProgress state;
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
    final locked = state.submitting;

    return Column(
      children: [
        _TopBar(
          current: current + 1,
          total: total,
          title: state.test.title.isNotEmpty ? state.test.title : 'Placement',
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
              if (confirmed && !state.submitting)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    'You can still change your answer, then press Next.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11.sp,
                    ),
                  ),
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
                  'Placement Pulse',
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
                        selectedItemBuilder: (context) {
                          return [
                            for (final r in rightOptions)
                              Text(
                                r.rightText ?? r.textAnswer ?? '#${r.id}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ];
                        },
                        items: [
                          for (final r in rightOptions)
                            DropdownMenuItem(
                              value: r.id,
                              enabled:
                                  !pairMap.values.contains(r.id) ||
                                  pairMap[left.id] == r.id,
                              child: Text(
                                r.rightText ?? r.textAnswer ?? '#${r.id}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  decoration: pairMap.values.contains(r.id)
                                      ? TextDecoration.lineThrough
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
  final PlacementAttemptFinished state;
  const _FinishedView({required this.state});

  @override
  State<_FinishedView> createState() => _FinishedViewState();
}

class _FinishedViewState extends State<_FinishedView> {
  String? _levelName;
  bool _loadingLevel = true;

  @override
  void initState() {
    super.initState();
    _resolveLevel();
  }

  Future<void> _resolveLevel() async {
    final score = widget.state.result.scorePercent;
    try {
      final repo = context.read<LevelRepository>();
      final res = await repo.getStudentLevels();
      if (!mounted) return;
      if (res['success'] == true && res['data'] is StudentLevelsModel) {
        final data = res['data'] as StudentLevelsModel;
        final all = [
          ...data.availableLevels,
          ...data.lockedLevels,
          ...data.completedLevels,
          if (data.currentLevel != null) data.currentLevel!,
        ];
        LevelModel? match;
        for (final l in all) {
          if (score >= l.minimumScore &&
              score <= l.maximumScore &&
              (match == null || l.order > match.order)) {
            match = l;
          }
        }
        setState(() {
          _levelName = match?.name;
          _loadingLevel = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingLevel = false);
  }

  String get _headline {
    final s = widget.state.result.scorePercent;
    if (s >= 90) return 'Outstanding!';
    if (s >= 75) return 'Great job!';
    if (s >= 60) return 'Well done!';
    if (s >= 40) return 'Nice work!';
    if (s >= 20) return 'Good start!';
    return 'Keep going!';
  }

  String get _subtitle {
    final s = widget.state.result.scorePercent;
    if (s >= 90) return 'You crushed it — your path is unlocked.';
    if (s >= 75) return 'Strong result. You are ready for the next step.';
    if (s >= 60) return 'Solid progress. Your learning path is set.';
    if (s >= 40) return 'You are on your way. Levels are ready for you.';
    if (s >= 20) return 'Every step counts. Your journey starts here.';
    return 'Practice makes progress. Your path is ready.';
  }

  IconData get _resultIcon {
    final s = widget.state.result.scorePercent;
    if (s >= 90) return Icons.auto_awesome_rounded;
    if (s >= 75) return Icons.star_rounded;
    if (s >= 60) return Icons.trending_up_rounded;
    if (s >= 40) return Icons.rocket_launch_rounded;
    if (s >= 20) return Icons.flag_rounded;
    return Icons.explore_rounded;
  }

  Color get _resultIconColor {
    final s = widget.state.result.scorePercent;
    if (s >= 75) return AppColors.yellow;
    if (s >= 40) return AppColors.sky;
    return AppColors.orange;
  }

  Question? _findQuestion(int id) {
    for (final q in widget.state.test.questions) {
      if (q.id == id) return q;
    }
    return null;
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
                            'Review your answers',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17.sp,
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Take a moment to learn from these questions.',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                      itemCount: review.wrongAnswers.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (_, i) {
                        final w = review.wrongAnswers[i];
                        return _ReviewCard(
                          index: i + 1,
                          wrong: w,
                          question: _findQuestion(w.questionId),
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

  @override
  Widget build(BuildContext context) {
    final r = widget.state.result;
    final review = widget.state.review;
    final hasMistakes = review != null && review.wrongAnswers.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(studentHomeRoute, (route) => false);
              },
              icon: Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 22.sp,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _resultIconColor.withOpacity(0.22),
                  _resultIconColor.withOpacity(0.06),
                ],
              ),
              border: Border.all(color: _resultIconColor.withOpacity(0.35)),
            ),
            child: Icon(_resultIcon, color: _resultIconColor, size: 48.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            _headline,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 13.sp,
              height: 1.45,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            '${r.scorePercent}%',
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 44.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_loadingLevel)
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.sky,
                ),
              ),
            )
          else if (_levelName != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.sky.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.sky.withOpacity(0.4)),
              ),
              child: Text(
                'Your level: $_levelName',
                style: GoogleFonts.poppins(
                  color: AppColors.sky,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (hasMistakes) ...[
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
                  'Review your mistakes',
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
            height: 52.h,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(studentHomeRoute, (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue to levels',
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

class _ReviewCard extends StatelessWidget {
  final int index;
  final ReviewWrongAnswer wrong;
  final Question? question;

  const _ReviewCard({
    required this.index,
    required this.wrong,
    required this.question,
  });

  String _labelForId(int? id) {
    if (id == null || question == null) return id?.toString() ?? '—';
    for (final a in question!.answers) {
      if (a.id == id) {
        final t = (a.textAnswer ?? a.leftText ?? a.rightText ?? '').trim();
        if (t.isNotEmpty) return t;
      }
    }
    return '#$id';
  }

  String _pairSideLabel(int? id, {required bool leftSide}) {
    if (id == null || question == null) return id?.toString() ?? '—';
    for (final a in question!.answers) {
      if (a.id == id) {
        if (leftSide) {
          final t = (a.leftText ?? a.textAnswer ?? '').trim();
          if (t.isNotEmpty) return t;
        } else {
          final t = (a.rightText ?? a.textAnswer ?? '').trim();
          if (t.isNotEmpty) return t;
        }
      }
    }
    return _labelForId(id);
  }

  String _fmtSubmitted() {
    final answer = wrong.submittedAnswer;
    if (answer == null) return '—';
    if (answer is String) return answer;
    if (answer is! Map) return answer.toString();
    final map = Map<String, dynamic>.from(answer);

    if (map.containsKey('selected_answer_id')) {
      final id = map['selected_answer_id'];
      final parsed = id is int ? id : int.tryParse(id?.toString() ?? '');
      return _labelForId(parsed);
    }

    if (map.containsKey('answers')) {
      final a = map['answers'];
      if (a is Map) {
        final entries = a.entries.toList()
          ..sort((x, y) {
            final xi = int.tryParse(x.key.toString()) ?? 0;
            final yi = int.tryParse(y.key.toString()) ?? 0;
            return xi.compareTo(yi);
          });
        return entries
            .map((e) => '${e.value}'.trim())
            .where((s) => s.isNotEmpty)
            .join(' · ');
      }
    }

    if (map.containsKey('ordered_ids')) {
      final raw = map['ordered_ids'];
      if (raw is List) {
        return raw
            .map((item) {
              final id = item is int ? item : int.tryParse(item.toString());
              return _labelForId(id);
            })
            .join(' → ');
      }
    }

    if (map.containsKey('pairs')) {
      final p = map['pairs'];
      if (p is Map) {
        return p.entries
            .map((e) {
              final left = int.tryParse(e.key.toString());
              final right = e.value is int
                  ? e.value as int
                  : int.tryParse(e.value.toString());
              return '${_pairSideLabel(left, leftSide: true)} → ${_pairSideLabel(right, leftSide: false)}';
            })
            .join(' · ');
      }
    }

    return map.toString();
  }

  String _fmtCorrect() {
    final answer = wrong.correctAnswer;
    if (answer == null) return '—';
    if (answer is String) return answer;
    if (answer is! Map) return answer.toString();
    final map = Map<String, dynamic>.from(answer);

    if (map.containsKey('selected_answer_id')) {
      final id = map['selected_answer_id'];
      final parsed = id is int ? id : int.tryParse(id?.toString() ?? '');
      return _labelForId(parsed);
    }

    if (map.containsKey('answers')) {
      final a = map['answers'];
      if (a is Map) {
        final parts = <String>[];
        final keys = a.keys.toList()
          ..sort((x, y) {
            final xi = int.tryParse(x.toString()) ?? 0;
            final yi = int.tryParse(y.toString()) ?? 0;
            return xi.compareTo(yi);
          });
        for (final k in keys) {
          final v = a[k];
          if (v is List) {
            parts.add(v.map((e) => e.toString()).join(' / '));
          } else {
            parts.add(v.toString());
          }
        }
        return parts.join(' · ');
      }
    }

    if (map.containsKey('ordered_ids')) {
      final raw = map['ordered_ids'];
      if (raw is List) {
        return raw
            .map((item) {
              final id = item is int ? item : int.tryParse(item.toString());
              return _labelForId(id);
            })
            .join(' → ');
      }
    }

    if (map.containsKey('pairs')) {
      final p = map['pairs'];
      if (p is Map) {
        return p.entries
            .map((e) {
              final left = int.tryParse(e.key.toString());
              final right = e.value is int
                  ? e.value as int
                  : int.tryParse(e.value.toString());
              return '${_pairSideLabel(left, leftSide: true)} → ${_pairSideLabel(right, leftSide: false)}';
            })
            .join(' · ');
      }
    }

    return map.toString();
  }

  @override
  Widget build(BuildContext context) {
    final type = wrong.type.toUpperCase();
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$index · $type',
                  style: GoogleFonts.poppins(
                    color: AppColors.orange,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${wrong.score}/${wrong.maxScore}',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            wrong.questionText.isNotEmpty
                ? wrong.questionText
                : (question?.titleQuestionEn ?? 'Question'),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          SizedBox(height: 10.h),
          _AnswerLine(
            label: 'Your answer',
            value: _fmtSubmitted(),
            color: const Color(0xFFFF8A80),
          ),
          SizedBox(height: 6.h),
          _AnswerLine(
            label: 'Correct answer',
            value: _fmtCorrect(),
            color: const Color(0xFF69F0AE),
          ),
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnswerLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white38,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
