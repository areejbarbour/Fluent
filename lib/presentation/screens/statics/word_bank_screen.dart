import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/student/words_bank/words_bank_cubit.dart';
import 'package:fluent/cubit/student/words_bank/words_bank_state.dart';
import 'package:fluent/data/models/words_bank_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/data/repository/lesson_word_repository.dart';
import 'package:fluent/presentation/screens/statics/word_quiz_screen.dart';

enum WordStatus { learning, mastered }

enum WordDifficulty { easy, medium, hard }

class WordItem {
  final String id;
  final String word;
  final String translation;
  final String? pronunciation;
  final String? exampleSentence;
  final WordStatus status;
  final WordDifficulty difficulty;
  final int correctAnswers;
  final int totalAttempts;
  final DateTime addedAt;
  final String? audioUrl;

  const WordItem({
    required this.id,
    required this.word,
    required this.translation,
    this.pronunciation,
    this.exampleSentence,
    required this.status,
    this.difficulty = WordDifficulty.medium,
    this.correctAnswers = 0,
    this.totalAttempts = 0,
    required this.addedAt,
    this.audioUrl,
  });

  double get accuracy =>
      totalAttempts == 0 ? 0 : (correctAnswers / totalAttempts);

  WordItem copyWith({
    WordStatus? status,
    int? correctAnswers,
    int? totalAttempts,
    WordDifficulty? difficulty,
  }) {
    return WordItem(
      id: id,
      word: word,
      translation: translation,
      pronunciation: pronunciation,
      exampleSentence: exampleSentence,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      addedAt: addedAt,
      audioUrl: audioUrl,
    );
  }
}

class WordBankScreen extends StatefulWidget {
  const WordBankScreen({super.key});

  @override
  State<WordBankScreen> createState() => _WordBankScreenState();
}

class _WordBankScreenState extends State<WordBankScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);
  final ScrollController _scrollController = ScrollController();

  List<WordItem> _words = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) HapticFeedback.selectionClick();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  List<WordItem> _mapToWordItems(
    List<WordsBankItem> learning,
    List<WordsBankItem> known,
  ) {
    WordItem toItem(WordsBankItem w, WordStatus status) {
      DateTime added;
      try {
        added = w.addedAt != null ? DateTime.parse(w.addedAt!) : DateTime.now();
      } catch (_) {
        added = DateTime.now();
      }

      String? audioUrl;
      if (w.word.hasAudio) {
        final raw = w.word.audio!;
        audioUrl = raw.startsWith('http') ? raw : '$baseUrl/$raw';
      }

      return WordItem(
        id: w.word.id.toString(),
        word: w.word.wordEn,
        translation: w.word.wordAr,
        status: status,
        addedAt: added,
        audioUrl: audioUrl,
      );
    }

    return [
      ...learning.map((w) => toItem(w, WordStatus.learning)),
      ...known.map((w) => toItem(w, WordStatus.mastered)),
    ];
  }

  Future<void> _toggleWordStatus(WordItem word) async {
    HapticFeedback.mediumImpact();

    final wordId = int.tryParse(word.id);
    if (wordId == null) return;

    final repo = context.read<LessonWordRepository>();
    final isLearning = word.status == WordStatus.learning;

    _showAppSnack(
      isLearning
          ? 'Transferring to mastered...'
          : 'Transferring to learning...',
    );

    final Map<String, dynamic> result;
    if (isLearning) {
      result = await repo.moveToKnow(wordId);
    } else {
      result = await repo.moveToLearning(wordId);
    }

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        final idx = _words.indexWhere((w) => w.id == word.id);
        if (idx == -1) return;
        _words[idx] = _words[idx].copyWith(
          status: isLearning ? WordStatus.mastered : WordStatus.learning,
        );
      });

      _showAppSnack(
        result['message'] ??
            (isLearning ? 'Moved to mastered ✨' : 'Moved to learning 📚'),
        isSuccess: true,
      );
    } else {
      _showAppSnack(result['message'] ?? 'Transfer failed', isError: true);
    }
  }

  void _showAppSnack(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: isError
                      ? [
                          const Color(0xFFFF6B6B).withOpacity(.25),
                          AppColors.dark.withOpacity(.9),
                        ]
                      : isSuccess
                      ? [
                          const Color(0xFF4ADE80).withOpacity(.22),
                          AppColors.dark.withOpacity(.9),
                        ]
                      : [
                          AppColors.sky.withOpacity(.2),
                          AppColors.dark.withOpacity(.9),
                        ],
                ),
                border: Border.all(
                  color: isError
                      ? const Color(0xFFFF6B6B).withOpacity(.45)
                      : isSuccess
                      ? const Color(0xFF4ADE80).withOpacity(.45)
                      : AppColors.sky.withOpacity(.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isError
                            ? const [Color(0xFFFF6B6B), Color(0xFFE53935)]
                            : isSuccess
                            ? const [Color(0xFF4ADE80), Color(0xFF22C55E)]
                            : const [AppColors.sky, Color(0xFFB388FF)],
                      ),
                    ),
                    child: Icon(
                      isError
                          ? Icons.error_outline_rounded
                          : isSuccess
                          ? Icons.check_rounded
                          : Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text.toLowerCase().trim();

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: BlocConsumer<WordsBankCubit, WordsBankState>(
        listener: (context, state) {
          if (state is WordsBankSuccess) {
            setState(() {
              _words = _mapToWordItems(state.learningWords, state.knownWords);
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              _buildBackground(),
              _TwinklingStars(count: 40),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    SizedBox(height: 18.h),
                    _buildSearchBar(),
                    SizedBox(height: 12.h),
                    _buildTabBar(),
                    SizedBox(height: 12.h),
                    if (state is WordsBankLoading && _words.isEmpty)
                      Expanded(child: _buildLoadingState())
                    else if (state is WordsBankFailure && _words.isEmpty)
                      Expanded(child: _buildErrorState(state.message))
                    else
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildWordsList(
                              words: _words
                                  .where(
                                    (w) =>
                                        w.status == WordStatus.learning &&
                                        (searchQuery.isEmpty ||
                                            w.word.toLowerCase().contains(
                                              searchQuery,
                                            ) ||
                                            w.translation.contains(
                                              searchQuery,
                                            )),
                                  )
                                  .toList(),
                              targetStatus: WordStatus.mastered,
                              actionLabel: "Mark as Mastered",
                              actionIcon: Icons.check_circle_rounded,
                              actionColor: const Color(0xFF4ADE80),
                            ),
                            _buildWordsList(
                              words: _words
                                  .where(
                                    (w) =>
                                        w.status == WordStatus.mastered &&
                                        (searchQuery.isEmpty ||
                                            w.word.toLowerCase().contains(
                                              searchQuery,
                                            ) ||
                                            w.translation.contains(
                                              searchQuery,
                                            )),
                                  )
                                  .toList(),
                              targetStatus: WordStatus.learning,
                              actionLabel: "Move to Learning",
                              actionIcon: Icons.replay_rounded,
                              actionColor: AppColors.yellow,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFABs(),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: AppColors.yellow));
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
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
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.read<WordsBankCubit>().fetchAll();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.yellow],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  "Retry",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
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
        _parallaxGlow(
          top: -120.h,
          right: -80.w,
          color: AppColors.yellow,
          size: 300.w,
          factor: 0.18,
          duration: 5500,
          endOffset: const Offset(-15, 10),
        ),
        _parallaxGlow(
          top: 400.h,
          left: -100.w,
          color: AppColors.sky,
          size: 260.w,
          factor: 0.12,
          duration: 6500,
          endOffset: const Offset(20, 15),
        ),
        _parallaxGlow(
          top: 800.h,
          right: -60.w,
          color: const Color(0xffB861F5),
          size: 220.w,
          factor: 0.09,
          duration: 7000,
          endOffset: const Offset(-10, -8),
        ),
      ],
    );
  }

  Widget _parallaxGlow({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
    required double factor,
    required int duration,
    required Offset endOffset,
  }) {
    Widget glow =
        Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.10),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 160,
                    spreadRadius: 40,
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: endOffset,
              duration: duration.ms,
              curve: Curves.easeInOut,
            );

    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (context, offset, child) {
        final shift = (offset * factor).clamp(-40.0, 40.0);
        return Positioned(
          top: top == null ? null : top + shift,
          bottom: bottom == null ? null : bottom - shift,
          left: left,
          right: right,
          child: glow,
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          _circleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Word Bank",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
                Text(
                  "Your personal vocabulary",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.6),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).moveY(begin: -10, end: 0);
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
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(.10),
              Colors.white.withOpacity(.04),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(.12)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
          decoration: InputDecoration(
            hintText: "Search words or translations...",
            hintStyle: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.4),
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withOpacity(.5),
              size: 20.sp,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                      HapticFeedback.selectionClick();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(.5),
                      size: 18.sp,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildTabBar() {
    final learningCount = _words
        .where((w) => w.status == WordStatus.learning)
        .length;
    final masteredCount = _words
        .where((w) => w.status == WordStatus.mastered)
        .length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(5.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.orange, AppColors.yellow],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withOpacity(.4),
                blurRadius: 12,
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white.withOpacity(.7),
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 12.sp,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_rounded, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text("Learning"),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      "$learningCount",
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text("Mastered"),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      "$masteredCount",
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }

  Widget _buildWordsList({
    required List<WordItem> words,
    required WordStatus targetStatus,
    required String actionLabel,
    required IconData actionIcon,
    required Color actionColor,
  }) {
    if (words.isEmpty) {
      return _buildEmptyState(targetStatus);
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 130.h),
      itemCount: words.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: _WordCard(
            word: words[index],
            index: index,
            onMove: () => _toggleWordStatus(words[index]),
            actionLabel: actionLabel,
            actionIcon: actionIcon,
            actionColor: actionColor,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(WordStatus status) {
    final isLearning = status == WordStatus.learning;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.sky.withOpacity(.2), Colors.transparent],
                ),
              ),
              child: Icon(
                isLearning
                    ? Icons.menu_book_rounded
                    : Icons.emoji_events_rounded,
                size: 60.sp,
                color: Colors.white.withOpacity(.3),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              isLearning ? "No words in learning" : "No mastered words yet",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              isLearning
                  ? "Start adding new words to begin your learning journey!"
                  : "Complete words in learning to see them here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(.6),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  void _openQuiz() {
    HapticFeedback.mediumImpact();
    WordQuizScreen.open(context);
  }

  Widget _buildFABs() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h, right: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Backend quiz (MCQ from /api/words/quiz)
          Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.yellow],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(.5),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30.r),
                    onTap: _openQuiz,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.quiz_rounded,
                            color: Colors.black,
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Quiz',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1,
                end: 1.04,
                duration: 1500.ms,
                curve: Curves.easeInOut,
              )
              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(.4)),
        ],
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required Color iconColor,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5.sp),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(.06),
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white.withOpacity(.55),
          fontSize: 12.sp,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.all(10.r),
          padding: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: iconColor, size: 16.sp),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.sky, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 10.sp),
      ),
    );
  }
}

class _WordCard extends StatefulWidget {
  final WordItem word;
  final int index;
  final VoidCallback onMove;
  final String actionLabel;
  final IconData actionIcon;
  final Color actionColor;

  const _WordCard({
    required this.word,
    required this.index,
    required this.onMove,
    required this.actionLabel,
    required this.actionIcon,
    required this.actionColor,
  });

  @override
  State<_WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<_WordCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  bool get _hasAudio =>
      widget.word.audioUrl != null && widget.word.audioUrl!.trim().isNotEmpty;

  Future<void> _playAudio() async {
    if (!_hasAudio) return;
    try {
      HapticFeedback.selectionClick();
      setState(() => _isPlaying = true);
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(widget.word.audioUrl!));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLearning = widget.word.status == WordStatus.learning;
    final accent = isLearning ? AppColors.sky : const Color(0xFF4ADE80);

    return ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(.12),
                    Colors.white.withOpacity(.04),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(.14)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // شريط جانبي
                    Container(
                      width: 4.5.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isLearning
                              ? [AppColors.sky, const Color(0xFFB388FF)]
                              : [const Color(0xFF4ADE80), AppColors.yellow],
                        ),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(22.r),
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
                              children: [
                                Container(
                                  width: 42.w,
                                  height: 42.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14.r),
                                    gradient: LinearGradient(
                                      colors: isLearning
                                          ? [
                                              AppColors.sky.withOpacity(.35),
                                              AppColors.sky.withOpacity(.12),
                                            ]
                                          : [
                                              const Color(
                                                0xFF4ADE80,
                                              ).withOpacity(.35),
                                              const Color(
                                                0xFF4ADE80,
                                              ).withOpacity(.12),
                                            ],
                                    ),
                                    border: Border.all(
                                      color: accent.withOpacity(.4),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.word.word.isNotEmpty
                                          ? widget.word.word[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.poppins(
                                        color: accent,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17.sp,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 11.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.word.word,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        widget.word.translation,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(.65),
                                          fontSize: 12.5.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ===== زر الصوت =====
                                GestureDetector(
                                  onTap: _hasAudio ? _playAudio : null,
                                  child: Container(
                                    width: 34.w,
                                    height: 34.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: _hasAudio
                                          ? LinearGradient(
                                              colors: [
                                                AppColors.yellow.withOpacity(
                                                  .9,
                                                ),
                                                AppColors.orange.withOpacity(
                                                  .85,
                                                ),
                                              ],
                                            )
                                          : null,
                                      color: _hasAudio
                                          ? null
                                          : Colors.white.withOpacity(.06),
                                      border: Border.all(
                                        color: _hasAudio
                                            ? AppColors.yellow.withOpacity(.5)
                                            : Colors.white.withOpacity(.1),
                                      ),
                                      boxShadow: _hasAudio
                                          ? [
                                              BoxShadow(
                                                color: AppColors.yellow
                                                    .withOpacity(.35),
                                                blurRadius: 10,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      _isPlaying
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_up_rounded,
                                      color: _hasAudio
                                          ? Colors.black
                                          : Colors.white.withOpacity(.28),
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                              ],
                            ),

                            SizedBox(height: 12.h),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(.07),
                            ),
                            SizedBox(height: 10.h),

                            // بادج + زر النقل
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 9.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    color: accent.withOpacity(.12),
                                    border: Border.all(
                                      color: accent.withOpacity(.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isLearning
                                            ? Icons.school_rounded
                                            : Icons.verified_rounded,
                                        size: 11.sp,
                                        color: accent,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        isLearning ? 'Learning' : 'Mastered',
                                        style: GoogleFonts.poppins(
                                          color: accent,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: widget.onMove,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 7.h,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14.r),
                                      gradient: LinearGradient(
                                        colors: isLearning
                                            ? const [
                                                Color(0xFF4ADE80),
                                                Color(0xFF22C55E),
                                              ]
                                            : const [
                                                AppColors.orange,
                                                AppColors.yellow,
                                              ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isLearning
                                                      ? const Color(0xFF4ADE80)
                                                      : AppColors.yellow)
                                                  .withOpacity(.4),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.actionIcon,
                                          color: isLearning
                                              ? Colors.white
                                              : Colors.black,
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 5.w),
                                        Text(
                                          widget.actionLabel,
                                          style: GoogleFonts.poppins(
                                            color: isLearning
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
        .fadeIn(delay: (40 * widget.index).ms, duration: 350.ms)
        .moveY(begin: 12, end: 0, curve: Curves.easeOutCubic);
  }
}

class _CircularPercentPainter extends CustomPainter {
  final double percent;
  final double animationValue;

  _CircularPercentPainter({
    required this.percent,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white.withOpacity(.10);
    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [AppColors.orange, AppColors.yellow, AppColors.sky],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * percent * animationValue,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularPercentPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.animationValue != animationValue;
}

class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 40});

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
