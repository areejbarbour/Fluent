import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/data/models/placement_question_model.dart';
import 'package:fluent/presentation/widgets/applogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// شاشات الاختبار
enum _PlacementPhase { intro, inProgress, finished }

/// نتيجة الاختبار
class PlacementResult {
  final PlacementDifficulty recommendedLevel;
  final int correctAnswers;
  final int totalQuestions;
  final int xpEarned;

  const PlacementResult({
    required this.recommendedLevel,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.xpEarned,
  });

  double get percentage => correctAnswers / totalQuestions;
}

class PlacementTestScreen extends StatefulWidget {
  /// لو true يفتح من البداية (intro)، لو false يفتح على طول بالأسئلة
  final bool showIntro;

  const PlacementTestScreen({super.key, this.showIntro = true});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen>
    with TickerProviderStateMixin {
  _PlacementPhase _phase = _PlacementPhase.intro;
  int _currentIndex = 0;
  int? _selectedOption;
  int _correctCount = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;

  // Timer
  Timer? _timer;
  int _secondsRemaining = 15 * 60; // 15 دقيقة
  late final AnimationController _progressAnimController;
  late final AnimationController _resultAnimController;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.showIntro) {
      _phase = _PlacementPhase.intro;
    } else {
      _phase = _PlacementPhase.inProgress;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressAnimController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) _secondsRemaining--;
      });
    });
  }

  void _startTest() {
    setState(() {
      _phase = _PlacementPhase.inProgress;
      _currentIndex = 0;
      _correctCount = 0;
      _selectedOption = null;
      _showFeedback = false;
      _secondsRemaining = 15 * 60;
    });
    _startTimer();
  }

  void _onSelectOption(int index) {
    if (_showFeedback) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOption = index;
    });
  }

  void _onSubmit() {
    if (_selectedOption == null) return;
    final question = kPlacementQuestions[_currentIndex];
    final correct = _selectedOption == question.correctIndex;
    HapticFeedback.mediumImpact();

    setState(() {
      _showFeedback = true;
      _isCorrect = correct;
      if (correct) _correctCount++;
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _goNext();
    });
  }

  void _goNext() {
    _progressAnimController.forward(from: 0);
    if (_currentIndex < kPlacementQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _showFeedback = false;
      });
    } else {
      _timer?.cancel();
      setState(() {
        _phase = _PlacementPhase.finished;
      });
      _resultAnimController.forward(from: 0);
    }
  }

  /// حساب المستوى الموصى به بناءً على الإجابات الصحيحة
  PlacementResult _calculateResult() {
    final total = kPlacementQuestions.length;
    final correct = _correctCount;
    final pct = correct / total;

    PlacementDifficulty level;
    if (pct >= 0.95) {
      level = PlacementDifficulty.advanced; // C2
    } else if (pct >= 0.83) {
      level = PlacementDifficulty.upperIntermediate; // C1
    } else if (pct >= 0.66) {
      level = PlacementDifficulty.intermediate; // B2
    } else if (pct >= 0.50) {
      level = PlacementDifficulty.preIntermediate; // B1
    } else if (pct >= 0.33) {
      level = PlacementDifficulty.elementary; // A2
    } else {
      level = PlacementDifficulty.beginner; // A1
    }

    final xp = correct * 50;
    return PlacementResult(
      recommendedLevel: level,
      correctAnswers: correct,
      totalQuestions: total,
      xpEarned: xp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: 400.ms,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _buildCurrentPhase(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_phase) {
      case _PlacementPhase.intro:
        return const _IntroView(key: ValueKey('intro'));
      case _PlacementPhase.inProgress:
        return _QuizView(
          key: ValueKey('quiz-$_currentIndex'),
          question: kPlacementQuestions[_currentIndex],
          currentIndex: _currentIndex,
          total: kPlacementQuestions.length,
          secondsRemaining: _secondsRemaining,
          selectedOption: _selectedOption,
          showFeedback: _showFeedback,
          isCorrect: _isCorrect,
          onSelect: _onSelectOption,
          onSubmit: _onSubmit,
        );
      case _PlacementPhase.finished:
        final result = _calculateResult();
        return _ResultView(
          key: const ValueKey('result'),
          result: result,
          controller: _resultAnimController,
          onContinue: () => Navigator.of(context).pop(result),
          onRetake: _startTest,
        );
    }
  }

  // =================== BACKGROUND ===================
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
              ],
              stops: [0.0, 0.25, 0.65, 1.0],
            ),
          ),
        ),
        // Twinkling stars
        IgnorePointer(
          child: Stack(
            children: List.generate(35, (i) {
              final rng = math.Random(i * 13);
              final left = rng.nextDouble();
              final top = rng.nextDouble();
              final size = rng.nextDouble() * 1.8 + 0.8;
              return Positioned(
                left: left * 1.sw,
                top: top * 1.sh,
                child: Container(
                  width: size.w,
                  height: size.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(
                      begin: 0,
                      end: 0.8,
                      duration: (1500 + rng.nextInt(2000)).ms,
                      delay: (rng.nextInt(2000)).ms,
                    ),
              );
            }),
          ),
        ),
        // Glow blobs
        Positioned(
          top: -100.h,
          right: -80.w,
          child: _glowBlob(AppColors.yellow, 280.w, 0.10),
        ),
        Positioned(
          top: 400.h,
          left: -90.w,
          child: _glowBlob(AppColors.sky, 240.w, 0.08),
        ),
        Positioned(
          bottom: 50.h,
          right: -50.w,
          child: _glowBlob(AppColors.orange, 220.w, 0.08),
        ),
      ],
    );
  }

  Widget _glowBlob(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
        boxShadow: [
          BoxShadow(color: color.withOpacity(opacity * 3), blurRadius: 60),
        ],
      ),
    );
  }
}

// =================================================================
// ========================== INTRO VIEW ===========================
// =================================================================

class _IntroView extends StatelessWidget {
  const _IntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 10.h),
          _buildTopBar(context),
          SizedBox(height: 30.h),
          Center(
            child: const AppLogo(size: 110)
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
          ),
          SizedBox(height: 28.h),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, AppColors.sky],
            ).createShader(bounds),
            child: Text(
              'Placement Test',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 32.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
          SizedBox(height: 12.h),
          Text(
            'Let\'s find the perfect level for you!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: AppColors.lightOrange.withOpacity(0.85),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(delay: 350.ms),
          SizedBox(height: 30.h),
          _infoCards(),
          SizedBox(height: 36.h),
          _startButton(context),
          SizedBox(height: 18.h),
          Text(
            '* You can retake this test anytime from Settings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: AppColors.sky.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _circleIcon(
          icon: Icons.close_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        Text(
          'STEP 0 / 3',
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        SizedBox(width: 44.w),
      ],
    );
  }

  Widget _circleIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.14),
              Colors.white.withOpacity(0.06),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }

  Widget _infoCards() {
    final items = [
      (
        icon: Icons.timer_rounded,
        title: '~ 15 min',
        subtitle: 'Take your time',
        color: AppColors.yellow,
      ),
      (
        icon: Icons.quiz_rounded,
        title: '${kPlacementQuestions.length} Questions',
        subtitle: 'Mixed difficulty',
        color: AppColors.orange,
      ),
      (
        icon: Icons.workspace_premium_rounded,
        title: 'Earn 50 XP',
        subtitle: 'Per correct answer',
        color: AppColors.sky,
      ),
    ];
    return Column(
      children: List.generate(items.length, (i) {
        final it = items[i];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _glassCard(
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        it.color.withOpacity(0.35),
                        it.color.withOpacity(0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: it.color.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(it.icon, color: it.color, size: 22.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        it.subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (450 + i * 100).ms).moveX(begin: 20, end: 0);
      }),
    );
  }

  Widget _startButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final state = context.findAncestorStateOfType<
            _PlacementTestScreenState>();
        state?._startTest();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: const LinearGradient(
            colors: [AppColors.orange, AppColors.lightOrange],
          ),
          border: Border.all(
            color: AppColors.yellow.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              color: AppColors.dark,
              size: 22.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              'Start Test',
              style: GoogleFonts.poppins(
                color: AppColors.dark,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0);
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =================================================================
// ========================== QUIZ VIEW ============================
// =================================================================

class _QuizView extends StatelessWidget {
  final PlacementQuestion question;
  final int currentIndex;
  final int total;
  final int secondsRemaining;
  final int? selectedOption;
  final bool showFeedback;
  final bool isCorrect;
  final ValueChanged<int> onSelect;
  final VoidCallback onSubmit;

  const _QuizView({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.total,
    required this.secondsRemaining,
    required this.selectedOption,
    required this.showFeedback,
    required this.isCorrect,
    required this.onSelect,
    required this.onSubmit,
  });

  String get _timerText {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final diffInfo = PlacementQuestion.getLevelInfo(question.difficulty);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(context),
          SizedBox(height: 18.h),
          _progressBar(),
          SizedBox(height: 16.h),
          _difficultyChip(diffInfo.title, diffInfo.code, diffInfo.color),
          SizedBox(height: 20.h),
          if (question.passage != null) ...[
            _passageCard(question.passage!),
            SizedBox(height: 18.h),
          ],
          _questionCard(question.question, question.type),
          SizedBox(height: 22.h),
          ...List.generate(question.options.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _OptionTile(
                index: i,
                label: question.options[i],
                selected: selectedOption == i,
                showFeedback: showFeedback,
                isCorrectAnswer: question.correctIndex == i,
                isUserWrong:
                    showFeedback && selectedOption == i && !isCorrect,
                onTap: () => onSelect(i),
              )
                  .animate(key: ValueKey('opt-$currentIndex-$i'))
                  .fadeIn(delay: (50 * i).ms, duration: 300.ms)
                  .moveX(begin: 16, end: 0),
            );
          }),
          SizedBox(height: 8.h),
          if (showFeedback)
            _feedbackBox(question.explanation, isCorrect)
                .animate()
                .fadeIn(duration: 250.ms)
                .moveY(begin: 8, end: 0)
          else
            _submitButton(context),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showExitDialog(context),
          child: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.14),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(Icons.close_rounded,
                color: Colors.white, size: 20.sp),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLACEMENT TEST',
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Question ${currentIndex + 1} of $total',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _timerPill(),
      ],
    );
  }

  Widget _timerPill() {
    final isLow = secondsRemaining < 60;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: isLow
              ? [
                  Colors.redAccent.withOpacity(0.25),
                  Colors.redAccent.withOpacity(0.10),
                ]
              : [
                  Colors.white.withOpacity(0.14),
                  Colors.white.withOpacity(0.06),
                ],
        ),
        border: Border.all(
          color: isLow
              ? Colors.redAccent.withOpacity(0.6)
              : Colors.white.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: isLow ? Colors.redAccent : AppColors.sky,
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            _timerText,
            style: GoogleFonts.poppins(
              color: isLow ? Colors.redAccent : Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final pct = (currentIndex + 1) / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Stack(
        children: [
          Container(
            height: 8.h,
            color: Colors.white.withOpacity(0.10),
          ),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              height: 8.h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.sky, AppColors.yellow],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
        ],
      ),
    );
  }

  Widget _difficultyChip(String title, String code, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.30),
              color.withOpacity(0.10),
            ],
          ),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.w,
              height: 6.w,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            SizedBox(width: 8.w),
            Text(
              '$code · $title',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passageCard(String passage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.sky.withOpacity(0.18),
                Colors.white.withOpacity(0.04),
              ],
            ),
            border: Border.all(color: AppColors.sky.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: AppColors.sky,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  passage,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13.sp,
                    height: 1.65,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionCard(String question, PlacementQuestionType type) {
    IconData icon;
    String label;
    switch (type) {
      case PlacementQuestionType.vocabulary:
        icon = Icons.translate_rounded;
        label = 'VOCABULARY';
        break;
      case PlacementQuestionType.grammar:
        icon = Icons.spellcheck_rounded;
        label = 'GRAMMAR';
        break;
      case PlacementQuestionType.reading:
        icon = Icons.article_rounded;
        label = 'READING COMPREHENSION';
        break;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.14),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 14,
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
                      shape: BoxShape.circle,
                      color: AppColors.yellow.withOpacity(0.20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: AppColors.yellow, size: 16.sp),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11.sp,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(
                question,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18.sp,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    final enabled = selectedOption != null;
    return GestureDetector(
      onTap: enabled ? onSubmit : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.orange, AppColors.lightOrange],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.10),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
          border: Border.all(
            color: enabled
                ? AppColors.yellow.withOpacity(0.5)
                : Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.35),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            'Submit Answer',
            style: GoogleFonts.poppins(
              color: enabled ? AppColors.dark : Colors.white.withOpacity(0.4),
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _feedbackBox(String explanation, bool correct) {
    final color = correct ? AppColors.sky : Colors.redAccent;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: color,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'Excellent! 🎉' : 'Not quite right',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  explanation,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12.sp,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.85),
                    AppColors.dark.withOpacity(0.95),
                  ],
                ),
                border: Border.all(color: AppColors.sky.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.yellow,
                    size: 48,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Exit Test?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your progress will be lost.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogButton(
                          label: 'Continue',
                          onTap: () => Navigator.pop(ctx),
                          filled: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dialogButton(
                          label: 'Exit',
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogButton({
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: filled
              ? const LinearGradient(
                  colors: [AppColors.orange, AppColors.lightOrange],
                )
              : null,
          color: filled ? null : Colors.white.withOpacity(0.10),
          border: Border.all(
            color: filled
                ? AppColors.yellow.withOpacity(0.5)
                : Colors.white.withOpacity(0.25),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: filled ? AppColors.dark : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// ======================== OPTION TILE ============================
// =================================================================

class _OptionTile extends StatelessWidget {
  final int index;
  final String label;
  final bool selected;
  final bool showFeedback;
  final bool isCorrectAnswer;
  final bool isUserWrong;
  final VoidCallback onTap;

  const _OptionTile({
    required this.index,
    required this.label,
    required this.selected,
    required this.showFeedback,
    required this.isCorrectAnswer,
    required this.isUserWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.white.withOpacity(0.18);
    Color bgTop = Colors.white.withOpacity(0.10);
    Color bgBot = Colors.white.withOpacity(0.04);
    Color textColor = Colors.white.withOpacity(0.85);
    Widget? trailing;

    if (showFeedback) {
      if (isCorrectAnswer) {
        borderColor = AppColors.sky;
        bgTop = AppColors.sky.withOpacity(0.25);
        bgBot = AppColors.sky.withOpacity(0.08);
        textColor = Colors.white;
        trailing = _statusDot(AppColors.sky, Icons.check_rounded);
      } else if (isUserWrong) {
        borderColor = Colors.redAccent;
        bgTop = Colors.redAccent.withOpacity(0.20);
        bgBot = Colors.redAccent.withOpacity(0.06);
        textColor = Colors.white;
        trailing = _statusDot(Colors.redAccent, Icons.close_rounded);
      }
    } else if (selected) {
      borderColor = AppColors.yellow;
      bgTop = AppColors.yellow.withOpacity(0.22);
      bgBot = AppColors.yellow.withOpacity(0.06);
      textColor = Colors.white;
      trailing = _statusDot(AppColors.yellow, Icons.circle_rounded);
    }

    final letter = String.fromCharCode(65 + index); // A, B, C, D

    return GestureDetector(
      onTap: showFeedback ? null : onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        curve: Curves.easeOut,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBot],
          ),
          border: Border.all(
            color: borderColor,
            width: selected || showFeedback ? 1.6 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    borderColor.withOpacity(0.35),
                    borderColor.withOpacity(0.10),
                  ],
                ),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14.sp,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _statusDot(Color color, IconData icon) {
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.25),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: color, size: 16.sp),
    );
  }
}

// =================================================================
// ========================== RESULT VIEW ==========================
// =================================================================

class _ResultView extends StatelessWidget {
  final PlacementResult result;
  final AnimationController controller;
  final VoidCallback onContinue;
  final VoidCallback onRetake;

  const _ResultView({
    super.key,
    required this.result,
    required this.controller,
    required this.onContinue,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final info = PlacementQuestion.getLevelInfo(result.recommendedLevel);
    final pct = (result.percentage * 100).round();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 6.h),
          // top close
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(result),
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white, size: 20.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          // celebration
          Center(
            child: Container(
              width: 130.w,
              height: 130.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    info.color.withOpacity(0.45),
                    info.color.withOpacity(0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: info.color.withOpacity(0.6),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: controller,
                builder: (_, __) {
                  final scale = 0.6 +
                      (Curves.easeOutBack.transform(controller.value) * 0.4);
                  return Transform.scale(
                    scale: scale.clamp(0.6, 1.0),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: info.color,
                      size: 70.sp,
                      shadows: [
                        Shadow(color: info.color, blurRadius: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Test Complete!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
          SizedBox(height: 8.h),
          Text(
            'You\'re at the perfect starting point',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.lightOrange.withOpacity(0.85),
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(delay: 350.ms),
          SizedBox(height: 28.h),
          _recommendedLevelCard(info.title, info.code, info.color),
          SizedBox(height: 14.h),
          _statsRow(),
          SizedBox(height: 28.h),
          _continueButton(context),
          SizedBox(height: 10.h),
          _retakeButton(),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _recommendedLevelCard(String title, String code, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.30),
                color.withOpacity(0.06),
              ],
            ),
            border: Border.all(color: color.withOpacity(0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'RECOMMENDED LEVEL',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11.sp,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14.h),
              ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: [color, Colors.white])
                        .createShader(bounds),
                child: Text(
                  code,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 72.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _statsRow() {
    final stats = [
      (
        icon: Icons.check_circle_rounded,
        color: AppColors.sky,
        value: '${result.correctAnswers}/${result.totalQuestions}',
        label: 'Correct',
      ),
      (
        icon: Icons.percent_rounded,
        color: AppColors.orange,
        value: '${(result.percentage * 100).round()}%',
        label: 'Score',
      ),
      (
        icon: Icons.star_rounded,
        color: AppColors.yellow,
        value: '+${result.xpEarned}',
        label: 'XP earned',
      ),
    ];

    return Row(
      children: List.generate(stats.length, (i) {
        final s = stats[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: i == stats.length - 1 ? 0 : 10.w,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.10),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Icon(s.icon, color: s.color, size: 22.sp),
                  SizedBox(height: 6.h),
                  Text(
                    s.value,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    s.label,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (700 + i * 100).ms).moveY(begin: 14, end: 0),
        );
      }),
    );
  }

  Widget _continueButton(BuildContext context) {
    return GestureDetector(
      onTap: onContinue,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: const LinearGradient(
            colors: [AppColors.orange, AppColors.lightOrange],
          ),
          border: Border.all(
            color: AppColors.yellow.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start My Journey',
              style: GoogleFonts.poppins(
                color: AppColors.dark,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(width: 10.w),
            Icon(Icons.arrow_forward_rounded,
                color: AppColors.dark, size: 22.sp),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms).moveY(begin: 16, end: 0);
  }

  Widget _retakeButton() {
    return GestureDetector(
      onTap: onRetake,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: AppColors.sky.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded,
                color: AppColors.sky, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'Retake Test',
              style: GoogleFonts.poppins(
                color: AppColors.sky,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}