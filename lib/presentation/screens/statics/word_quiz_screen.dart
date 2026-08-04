
import 'package:audioplayers/audioplayers.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/word_quiz/word_quiz_cubit.dart';
import 'package:fluent/cubit/student/word_quiz/word_quiz_state.dart';
import 'package:fluent/data/models/word_quiz_model.dart';
import 'package:fluent/data/repository/word_quiz_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluent/presentation/widgets/app_backdrop.dart';

class WordQuizScreen extends StatefulWidget {
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
  State<WordQuizScreen> createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen> {
  final Map<int, bool> _results = {};

  int get _streak {
    if (_results.isEmpty) return 0;
    final maxIndex = _results.keys.reduce((a, b) => a > b ? a : b);
    var streak = 0;
    var i = maxIndex;
    while (_results[i] == true) {
      streak++;
      i--;
      if (!_results.containsKey(i)) break;
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          const AppBackdrop(),
          SafeArea(
          child: BlocConsumer<WordQuizCubit, WordQuizState>(
            listener: (context, state) {
              if (state is WordQuizLoading || state is WordQuizInitial) {
                if (_results.isNotEmpty) setState(_results.clear);
              } else if (state is WordQuizInProgress &&
                  state.lastResult != null &&
                  _results[state.currentIndex] != state.lastResult!.correct) {
                setState(
                  () => _results[state.currentIndex] =
                      state.lastResult!.correct,
                );
              }
            },
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
                return _QuizBody(state: state, results: _results, streak: _streak);
              }
              return const SizedBox.shrink();
            },
          ),
          ),
        ],
      ),
    );
  }
}

class _QuizBody extends StatelessWidget {
  final WordQuizInProgress state;
  final Map<int, bool> results;
  final int streak;
  const _QuizBody({
    required this.state,
    required this.results,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final q = state.current;

    return Column(
      children: [
        _ModernTopBar(
          current: state.currentIndex + 1,
          total: state.total,
          correct: state.correctCount,
          streak: streak,
        ),
        SizedBox(height: 6.h),
        _EnergyProgressBar(
          total: state.total,
          currentIndex: state.currentIndex,
          results: results,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 20.h),
            physics: const BouncingScrollPhysics(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey(state.currentIndex),
                children: [
                  _PulseQuestionCard(question: q),
                  SizedBox(height: 22.h),
                  ...q.options.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _PulseOptionTile(
                        option: entry.value,
                        badge: String.fromCharCode(65 + entry.key),
                        selectedId: state.selectedOptionId,
                        result: state.lastResult,
                        enabled: !state.hasAnswered && !state.isChecking,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.read<WordQuizCubit>().selectOption(entry.value.id);
                        },
                      ),
                    );
                  }),
                  if (state.lastResult != null) ...[
                    SizedBox(height: 14.h),
                    _PulseFeedback(result: state.lastResult!, streak: streak),
                  ],
                ],
              ),
            ),
          ),
        ),
        _BottomActions(state: state),
      ],
    );
  }
}

class _ModernTopBar extends StatelessWidget {
  final int current;
  final int total;
  final int correct;
  final int streak;

  const _ModernTopBar({
    required this.current,
    required this.total,
    required this.correct,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 14.w, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.08),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Icon(Icons.close_rounded, color: Colors.white70, size: 18.sp),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Word Pulse',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$current / $total',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          if (streak >= 2)
            Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.orange, AppColors.yellow]),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [BoxShadow(color: AppColors.yellow.withOpacity(.5), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Colors.black, size: 15.sp),
                  SizedBox(width: 3.w),
                  Text(
                    '$streak',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.1, duration: 600.ms),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.18),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFF4ADE80).withOpacity(.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_rounded, color: const Color(0xFF4ADE80), size: 15.sp),
                SizedBox(width: 4.w),
                Text(
                  '$correct',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF86EFAC),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
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

class _EnergyProgressBar extends StatelessWidget {
  final int total;
  final int currentIndex;
  final Map<int, bool> results;

  const _EnergyProgressBar({
    required this.total,
    required this.currentIndex,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: List.generate(total, (i) {
          Color color;
          double height = 5.h;

          if (results.containsKey(i)) {
            color = results[i]! ? const Color(0xFF4ADE80) : Colors.redAccent;
          } else if (i == currentIndex) {
            color = AppColors.yellow;
            height = 8.h;
          } else {
            color = Colors.white.withOpacity(.12);
          }

          return Expanded(
            child: AnimatedContainer(
              duration: 280.ms,
              margin: EdgeInsets.symmetric(horizontal: 2.5.w),
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: i == currentIndex
                    ? [BoxShadow(color: color.withOpacity(.7), blurRadius: 8)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PulseQuestionCard extends StatefulWidget {
  final WordQuizQuestion question;
  const _PulseQuestionCard({required this.question});

  @override
  State<_PulseQuestionCard> createState() => _PulseQuestionCardState();
}

class _PulseQuestionCardState extends State<_PulseQuestionCard> {
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
    } catch (_) {} finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Container(
  width: double.infinity,
  padding: EdgeInsets.fromLTRB(
    22.w,
    24.h,
    22.w,
    25.h,
  ),
  decoration: BoxDecoration(
    borderRadius:
        BorderRadius.circular(30.r),

    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF063A55),
        const Color(0xFF012B40),
        const Color(0xFF011E2D),
      ],
    ),

    border: Border.all(
      color:
          AppColors.yellow.withOpacity(
        0.65,
      ),
      width: 1.8,
    ),

    boxShadow: [
      BoxShadow(
        color:
            AppColors.sky.withOpacity(
          0.20,
        ),
        blurRadius: 30,
        spreadRadius: 2,
      ),

      BoxShadow(
        color:
            AppColors.yellow.withOpacity(
          0.12,
        ),
        blurRadius: 20,
      ),
    ],
  ),

  child: Column(
    children: [

      Container(
        width: 58.w,
        height: 58.w,
        alignment: Alignment.center,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: const LinearGradient(
            colors: [
              AppColors.orange,
              AppColors.yellow,
            ],
          ),

          boxShadow: [
            BoxShadow(
              color:
                  AppColors.yellow
                      .withOpacity(
                0.45,
              ),
              blurRadius: 18,
            ),
          ],
        ),

        child: Icon(
          Icons.psychology_alt_rounded,
          color: AppColors.dark,
          size: 29.sp,
        ),
      )
          .animate(
            onPlay: (controller) =>
                controller.repeat(
              reverse: true,
            ),
          )
          .scaleXY(
            begin: 1,
            end: 1.10,
            duration: 1200.ms,
          ),

      SizedBox(height: 17.h),

      Text(
        'WORD CHALLENGE',

        style:
            GoogleFonts.cinzel(
          color:
              AppColors.yellow,

          fontSize:
              12.sp,

          fontWeight:
              FontWeight.w800,

          letterSpacing:
              2.2,
        ),
      ),

      SizedBox(height: 14.h),

      Text(
        q.question,

        textAlign:
            TextAlign.center,

        style:
            GoogleFonts.cinzel(
          color:
              Colors.white,

          fontSize:
              29.sp,

          fontWeight:
              FontWeight.w900,

          height:
              1.25,

          shadows: [
            Shadow(
              color:
                  AppColors.sky
                      .withOpacity(
                0.65,
              ),

              blurRadius:
                  16,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(
            duration:
                500.ms,
          )
          .slideY(
            begin:
                0.18,

            end:
                0,

            duration:
                600.ms,

            curve:
                Curves.easeOutBack,
          ),

      SizedBox(height: 10.h),

      Text(
        'Choose the correct meaning',

        style:
            GoogleFonts.poppins(
          color:
              Colors.white54,

          fontSize:
              12.sp,

          fontWeight:
              FontWeight.w500,
        ),
      ),

      if (q.hasAudio) ...[

        SizedBox(height: 20.h),

        GestureDetector(
          onTap:
              _playing
                  ? null
                  : _play,

          child:
              AnimatedContainer(
            duration:
                220.ms,

            padding:
                EdgeInsets.symmetric(
              horizontal:
                  18.w,

              vertical:
                  11.h,
            ),

            decoration:
                BoxDecoration(

              color:
                  AppColors.sky
                      .withOpacity(
                0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                25.r,
              ),

              border:
                  Border.all(
                color:
                    AppColors.sky
                        .withOpacity(
                  0.65,
                ),
              ),
            ),

            child:
                Row(
              mainAxisSize:
                  MainAxisSize.min,

              children: [

                Icon(
                  _playing
                      ? Icons
                          .graphic_eq_rounded
                      : Icons
                          .volume_up_rounded,

                  color:
                      AppColors.sky,

                  size:
                      21.sp,
                ),

                SizedBox(
                  width:
                      8.w,
                ),

                Text(
                  _playing
                      ? 'Playing...'
                      : 'Listen',

                  style:
                      GoogleFonts
                          .poppins(
                    color:
                        AppColors.sky,

                    fontSize:
                        13.sp,

                    fontWeight:
                        FontWeight.w800,
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

class _AnimatedAnswerBorder extends StatelessWidget {
  final Color color;
  final BorderRadius borderRadius;
  final Widget child;

  const _AnimatedAnswerBorder({
    required this.color,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,

        // البوردر هو الملون
        border: Border.all(
          color: color.withOpacity(0.95),
          width: 2.3,
        ),

        // إضاءة خفيفة حول البوردر
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: 13,
            spreadRadius: 0.5,
          ),
        ],
      ),

      child: child,
    )
        .animate(
          onPlay: (controller) =>
              controller.repeat(
            reverse: true,
          ),
        )
        .shimmer(
          duration: 1800.ms,
          color: color.withOpacity(0.45),
        );
  }
}

class _PulseOptionTile extends StatelessWidget {
  final WordQuizOption option;
  final String badge;
  final int? selectedId;
  final WordQuizCheckResult? result;
  final bool enabled;
  final VoidCallback onTap;

  const _PulseOptionTile({
    required this.option,
    required this.badge,
    required this.selectedId,
    required this.result,
    required this.enabled,
    required this.onTap,
  });

  Color _answerColor() {
    switch (badge) {
      case 'A':
        return const Color(0xFF38BDF8); 
      case 'B':
        return const Color(0xFFA78BFA); 
      case 'C':
        return const Color(0xFFF97316); 
      case 'D':
        return const Color(0xFF2DD4BF); 
      default:
        return AppColors.sky;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == option.id;
    final answered = result != null;

    final answerColor = _answerColor();

    Color borderColor = answerColor;
    Color backgroundColor = const Color(0xFF0B2E42);
    //Color backgroundColor = answerColor.withOpacity(0.08);
    Color textColor = Colors.white;
    Color badgeBackground = answerColor.withOpacity(0.22);
    Color badgeTextColor = answerColor;

    if (answered) {
      final isCorrectOption = result!.correct
          ? option.id == selectedId
          : option.id == result!.correctAnswerId;

      final isWrongSelected =
          !result!.correct && option.id == selectedId;

      if (isCorrectOption) {
        borderColor = const Color(0xFF4ADE80);
        backgroundColor =
            const Color(0xFF22C55E).withOpacity(0.20);

        textColor = const Color(0xFFBBF7D0);

        badgeBackground =
            const Color(0xFF4ADE80);

        badgeTextColor = Colors.black;
      } else if (isWrongSelected) {
        borderColor = Colors.redAccent;

        backgroundColor =
            Colors.redAccent.withOpacity(0.18);

        textColor = Colors.red.shade100;

        badgeBackground = Colors.redAccent;

        badgeTextColor = Colors.white;
      } else {
        borderColor =
            Colors.white.withOpacity(0.10);

        backgroundColor =
            Colors.white.withOpacity(0.025);

        textColor =
            Colors.white.withOpacity(0.30);

        badgeBackground =
            Colors.white.withOpacity(0.05);

        badgeTextColor =
            Colors.white.withOpacity(0.30);
      }
    } else if (isSelected) {
      borderColor = AppColors.yellow;

      backgroundColor =
          AppColors.yellow.withOpacity(0.15);

      badgeBackground = AppColors.yellow;

      badgeTextColor = Colors.black;
    }

    final borderRadius =
        BorderRadius.circular(20.r);

    Widget answerCard = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: borderRadius,
        splashColor:
            answerColor.withOpacity(0.20),
        highlightColor:
            answerColor.withOpacity(0.08),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 17.w,
            vertical: 16.h,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: 250.ms,
                width: 34.w,
                height: 34.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          borderColor.withOpacity(
                        0.40,
                      ),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    color: badgeTextColor,
                    fontSize: 14.sp,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),

              SizedBox(width: 14.w),

              Expanded(
                child: Text(
                  option.text,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 15.sp,
                    fontWeight:
                        FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),

              if (answered &&
                  ((result!.correct &&
                          option.id ==
                              selectedId) ||
                      (!result!.correct &&
                          option.id ==
                              result!
                                  .correctAnswerId)))
                Icon(
                  Icons.check_circle_rounded,
                  color:
                      const Color(0xFF4ADE80),
                  size: 23.sp,
                )
                    .animate()
                    .scale(
                      begin:
                          const Offset(
                        0.2,
                        0.2,
                      ),
                      end:
                          const Offset(
                        1,
                        1,
                      ),
                      curve:
                          Curves.elasticOut,
                      duration: 600.ms,
                    )

              else if (answered &&
                  !result!.correct &&
                  option.id == selectedId)
                Icon(
                  Icons.cancel_rounded,
                  color: Colors.redAccent,
                  size: 23.sp,
                )
                    .animate()
                    .shake(
                      duration: 450.ms,
                      hz: 4,
                    )

              else if (isSelected)
                Icon(
                  Icons.radio_button_checked,
                  color:
                      AppColors.yellow,
                  size: 22.sp,
                )

              else
                Icon(
                  Icons.circle_outlined,
                  color:
                      answerColor.withOpacity(
                    0.75,
                  ),
                  size: 21.sp,
                ),
            ],
          ),
        ),
      ),
    );

    if (!answered) {
      answerCard = _AnimatedAnswerBorder(
        color: answerColor,
        borderRadius: borderRadius,
        child: answerCard,
      );
    } else {
      answerCard = Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  borderColor.withOpacity(
                0.25,
              ),
              blurRadius: 15,
            ),
          ],
        ),
        child: answerCard,
      );
    }

    return answerCard
    .animate(
      onPlay: (controller) =>
          controller.repeat(
        reverse: true,
      ),
    )
    .scaleXY(
      begin: 1.0,
      end: isSelected ? 1.025 : 1.012,
      duration: isSelected
          ? 700.ms
          : 1400.ms,
      curve: Curves.easeInOut,
    );
  }
}

class _PulseFeedback extends StatelessWidget {
  final WordQuizCheckResult result;
  final int streak;

  const _PulseFeedback({required this.result, required this.streak});

  @override
  Widget build(BuildContext context) {
    final ok = result.correct;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ok
              ? [const Color(0xFF22C55E).withOpacity(0.2), const Color(0xFF16A34A).withOpacity(0.1)]
              : [Colors.redAccent.withOpacity(0.18), Colors.red.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: ok ? const Color(0xFF4ADE80).withOpacity(0.5) : Colors.redAccent.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? const Color(0xFF4ADE80).withOpacity(.25) : Colors.redAccent.withOpacity(.25),
            ),
            child: Icon(
              ok ? Icons.celebration_rounded : Icons.lightbulb_outline_rounded,
              color: ok ? const Color(0xFF4ADE80) : Colors.redAccent,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              ok && streak >= 3
                  ? '${result.message} · $streak in a row! 🔥'
                  : result.message,
              style: GoogleFonts.poppins(
                color: ok ? const Color(0xFF86EFAC) : Colors.red.shade200,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutBack).fadeIn();
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
        height: 52.h,
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
              borderRadius: BorderRadius.circular(16.r),
            ),
            elevation: canSubmit || canNext ? 6 : 0,
            shadowColor: AppColors.yellow.withOpacity(.5),
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      canNext
                          ? (state.isLast ? 'See results' : 'Next question')
                          : 'Check answer',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (canNext) ...[
                      SizedBox(width: 6.w),
                      Icon(Icons.arrow_forward_rounded, size: 18.sp),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final WordQuizFinished state;
  const _ResultsView({required this.state});

  ({IconData icon, Color color, String tier}) _tier(int pct) {
    if (pct >= 90) {
      return (icon: Icons.workspace_premium_rounded, color: const Color(0xFFFFD700), tier: 'Outstanding!');
    } else if (pct >= 70) {
      return (icon: Icons.emoji_events_rounded, color: AppColors.yellow, tier: 'Great work!');
    } else if (pct >= 50) {
      return (icon: Icons.thumb_up_rounded, color: AppColors.sky, tier: 'Good job!');
    }
    return (icon: Icons.self_improvement_rounded, color: Colors.white70, tier: 'Keep practicing!');
  }

  @override
  Widget build(BuildContext context) {
    final pct = (state.accuracy * 100).round();
    final tier = _tier(pct);

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
          Icon(tier.icon, color: tier.color, size: 40.sp)
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 700.ms,
              )
              .then(delay: 200.ms)
              .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(.5)),
          SizedBox(height: 14.h),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: state.accuracy.clamp(0, 1)),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Container(
                width: 130.w,
                height: 130.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      tier.color.withOpacity(0.28),
                      AppColors.orange.withOpacity(0.12),
                    ],
                  ),
                  border: Border.all(color: tier.color.withOpacity(0.55), width: 2),
                  boxShadow: [
                    BoxShadow(color: tier.color.withOpacity(.25), blurRadius: 24),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${(value * 100).round()}%',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20.h),
          Text(
            tier.tier,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _resultChip(
                icon: Icons.check_rounded,
                label: '${state.correctCount} correct',
                color: const Color(0xFF4ADE80),
              ),
              SizedBox(width: 8.w),
              _resultChip(
                icon: Icons.close_rounded,
                label: '${state.wrongCount} wrong',
                color: Colors.redAccent,
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<WordQuizCubit>().restart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 6,
                shadowColor: AppColors.yellow.withOpacity(.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Try again',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
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

  Widget _resultChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14.sp),
          SizedBox(width: 5.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
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