import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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

  late List<WordItem> _words;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    _words = _generateSampleWords();
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

  List<WordItem> _generateSampleWords() {
    final now = DateTime.now();
    return [
      WordItem(
        id: '1',
        word: 'Serendipity',
        translation: 'مصادفة سعيدة',
        pronunciation: '/ˌsɛrənˈdɪpɪti/',
        exampleSentence: 'Finding that book was pure serendipity.',
        status: WordStatus.learning,
        difficulty: WordDifficulty.hard,
        totalAttempts: 4,
        correctAnswers: 1,
        addedAt: now.subtract(const Duration(days: 2)),
      ),
      WordItem(
        id: '2',
        word: 'Ephemeral',
        translation: 'زائل، قصير الأمد',
        pronunciation: '/ɪˈfɛmərəl/',
        status: WordStatus.learning,
        difficulty: WordDifficulty.hard,
        addedAt: now.subtract(const Duration(days: 1)),
      ),
      WordItem(
        id: '3',
        word: 'Hello',
        translation: 'مرحبا',
        status: WordStatus.mastered,
        difficulty: WordDifficulty.easy,
        totalAttempts: 5,
        correctAnswers: 5,
        addedAt: now.subtract(const Duration(days: 30)),
      ),
      WordItem(
        id: '4',
        word: 'Beautiful',
        translation: 'جميل',
        status: WordStatus.mastered,
        difficulty: WordDifficulty.easy,
        totalAttempts: 8,
        correctAnswers: 8,
        addedAt: now.subtract(const Duration(days: 45)),
      ),
      WordItem(
        id: '5',
        word: 'Courage',
        translation: 'شجاعة',
        exampleSentence: 'She showed great courage.',
        status: WordStatus.learning,
        difficulty: WordDifficulty.medium,
        totalAttempts: 3,
        correctAnswers: 2,
        addedAt: now.subtract(const Duration(days: 3)),
      ),
      WordItem(
        id: '6',
        word: 'Adventure',
        translation: 'مغامرة',
        exampleSentence: 'Life is a great adventure.',
        status: WordStatus.mastered,
        difficulty: WordDifficulty.medium,
        totalAttempts: 6,
        correctAnswers: 6,
        addedAt: now.subtract(const Duration(days: 20)),
      ),
      WordItem(
        id: '7',
        word: 'Knowledge',
        translation: 'معرفة',
        status: WordStatus.mastered,
        difficulty: WordDifficulty.medium,
        totalAttempts: 4,
        correctAnswers: 4,
        addedAt: now.subtract(const Duration(days: 15)),
      ),
      WordItem(
        id: '8',
        word: 'Perseverance',
        translation: 'مثابرة',
        exampleSentence: 'Perseverance leads to success.',
        status: WordStatus.learning,
        difficulty: WordDifficulty.hard,
        totalAttempts: 5,
        correctAnswers: 2,
        addedAt: now.subtract(const Duration(days: 4)),
      ),
      WordItem(
        id: '9',
        word: 'Wisdom',
        translation: 'حكمة',
        status: WordStatus.mastered,
        difficulty: WordDifficulty.medium,
        totalAttempts: 7,
        correctAnswers: 7,
        addedAt: now.subtract(const Duration(days: 25)),
      ),
      WordItem(
        id: '10',
        word: 'Tranquility',
        translation: 'هدوء، سكينة',
        pronunciation: '/træŋˈkwɪlɪti/',
        status: WordStatus.learning,
        difficulty: WordDifficulty.hard,
        totalAttempts: 2,
        correctAnswers: 0,
        addedAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }

  void _toggleWordStatus(WordItem word) {
    HapticFeedback.mediumImpact();
    setState(() {
      final idx = _words.indexWhere((w) => w.id == word.id);
      if (idx == -1) return;
      _words[idx] = _words[idx].copyWith(
        status: _words[idx].status == WordStatus.learning
            ? WordStatus.mastered
            : WordStatus.learning,
      );
    });
  }

  void _deleteWord(WordItem word) {
    HapticFeedback.mediumImpact();
    setState(() {
      _words.removeWhere((w) => w.id == word.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 18),
            SizedBox(width: 8.w),
            Expanded(child: Text("'${word.word}' removed")),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _openPractice() {
    final learningWords =
        _words.where((w) => w.status == WordStatus.learning).toList();
    if (learningWords.isEmpty) {
      _showNoWordsToPracticeDialog();
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: 500.ms,
        pageBuilder: (_, __, ___) => FlashcardPracticeScreen(
          words: learningWords,
          onUpdateWord: _updateWord,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _updateWord(WordItem word) {
    setState(() {
      final idx = _words.indexWhere((w) => w.id == word.id);
      if (idx != -1) _words[idx] = word;
    });
  }

  void _showNoWordsToPracticeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.all(22.w),
              decoration: BoxDecoration(
                color: AppColors.dark.withOpacity(.92),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.yellow.withOpacity(.15),
                    ),
                    child: Icon(Icons.menu_book_rounded,
                        color: AppColors.yellow, size: 26.sp),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    "No words to practice!",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "Add some words to your learning list to start practicing.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.65),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 32.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.orange, AppColors.yellow],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(
                        "OK",
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
      body: Stack(
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
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildWordsList(
                        words: _words
                            .where((w) =>
                                w.status == WordStatus.learning &&
                                (searchQuery.isEmpty ||
                                    w.word.toLowerCase().contains(searchQuery) ||
                                    w.translation.contains(searchQuery)))
                            .toList(),
                        targetStatus: WordStatus.mastered,
                        actionLabel: "Mark as Mastered",
                        actionIcon: Icons.check_circle_rounded,
                        actionColor: const Color(0xFF4ADE80),
                      ),
                      _buildWordsList(
                        words: _words
                            .where((w) =>
                                w.status == WordStatus.mastered &&
                                (searchQuery.isEmpty ||
                                    w.word.toLowerCase().contains(searchQuery) ||
                                    w.translation.contains(searchQuery)))
                            .toList(),
                        targetStatus: WordStatus.learning,
                        actionLabel: "Practice Again",
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
      ),
      floatingActionButton: _buildFABs(),
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
    Widget glow = Container(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
                Text(
                  "Your personal vocabulary",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.6),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _circleIconButton(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showAddWordSheet();
            },
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
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildTabBar() {
    final learningCount =
        _words.where((w) => w.status == WordStatus.learning).length;
    final masteredCount =
        _words.where((w) => w.status == WordStatus.mastered).length;

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
                        horizontal: 6.w, vertical: 1.h),
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
                        horizontal: 6.w, vertical: 1.h),
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
            onDelete: () => _deleteWord(words[index]),
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
                  colors: [
                    AppColors.sky.withOpacity(.2),
                    Colors.transparent,
                  ],
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
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: () => _showAddWordSheet(),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.yellow],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.black, size: 18.sp),
                    SizedBox(width: 6.w),
                    Text(
                      "Add Word",
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
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildFABs() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h, right: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
                onTap: _openPractice,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          color: Colors.black, size: 18.sp),
                      SizedBox(width: 6.w),
                      Text(
                        "Practice",
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
              .shimmer(
                duration: 2000.ms,
                color: Colors.white.withOpacity(.4),
              ),
        ],
      ),
    );
  }

  void _showAddWordSheet() {
    final wordCtrl = TextEditingController();
    final translationCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    WordDifficulty selectedDifficulty = WordDifficulty.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28.r)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
                    decoration: BoxDecoration(
                      color: AppColors.dark.withOpacity(.92),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28.r)),
                      border: Border(
                        top: BorderSide(
                            color: Colors.white.withOpacity(.12)),
                      ),
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.25),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "Add New Word",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 18.h),
                          _sheetField(
                            ctrl: wordCtrl,
                            label: "Word (English)",
                            icon: Icons.translate_rounded,
                            iconColor: AppColors.sky,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? "Enter the word"
                                    : null,
                          ),
                          SizedBox(height: 14.h),
                          _sheetField(
                            ctrl: translationCtrl,
                            label: "Translation",
                            icon: Icons.language_rounded,
                            iconColor: AppColors.yellow,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? "Enter the translation"
                                    : null,
                          ),
                          SizedBox(height: 18.h),
                          Text(
                            "Difficulty",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(.6),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: WordDifficulty.values.map((difficulty) {
                              final isSelected = selectedDifficulty == difficulty;
                              Color color;
                              String label;
                              switch (difficulty) {
                                case WordDifficulty.easy:
                                  color = const Color(0xFF4ADE80);
                                  label = "Easy";
                                  break;
                                case WordDifficulty.medium:
                                  color = AppColors.yellow;
                                  label = "Medium";
                                  break;
                                case WordDifficulty.hard:
                                  color = Colors.redAccent;
                                  label = "Hard";
                                  break;
                              }
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      right: difficulty ==
                                              WordDifficulty.values.last
                                          ? 0
                                          : 8.w),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setSheetState(() =>
                                          selectedDifficulty = difficulty);
                                    },
                                    child: AnimatedContainer(
                                      duration: 200.ms,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12.h),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? LinearGradient(colors: [
                                                color.withOpacity(.4),
                                                color.withOpacity(.15),
                                              ])
                                            : null,
                                        color: isSelected
                                            ? null
                                            : Colors.white.withOpacity(.06),
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        border: Border.all(
                                          color: isSelected
                                              ? color.withOpacity(.7)
                                              : Colors.white.withOpacity(.12),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        label,
                                        style: GoogleFonts.poppins(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(.6),
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 22.h),
                          GestureDetector(
                            onTap: () {
                              if (formKey.currentState?.validate() ?? false) {
                                setState(() {
                                  _words.insert(
                                    0,
                                    WordItem(
                                      id: DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString(),
                                      word: wordCtrl.text.trim(),
                                      translation:
                                          translationCtrl.text.trim(),
                                      status: WordStatus.learning,
                                      difficulty: selectedDifficulty,
                                      addedAt: DateTime.now(),
                                    ),
                                  );
                                });
                                Navigator.pop(context);
                                HapticFeedback.mediumImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.white, size: 18),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                            child: Text(
                                                "Word added to learning!")),
                                      ],
                                    ),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 15.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.orange, AppColors.yellow],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.yellow.withOpacity(.5),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Text(
                                "Add to Learning",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.sp,
                                  letterSpacing: .3,
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
          },
        );
      },
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
  final VoidCallback onDelete;
  final String actionLabel;
  final IconData actionIcon;
  final Color actionColor;

  const _WordCard({
    required this.word,
    required this.index,
    required this.onMove,
    required this.onDelete,
    required this.actionLabel,
    required this.actionIcon,
    required this.actionColor,
  });

  @override
  State<_WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<_WordCard> {
  double _dragOffset = 0;
  bool _isExpanded = false;

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _dragOffset += d.delta.dx;
      _dragOffset = _dragOffset.clamp(-120.0, 120.0);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_dragOffset > 80 || _dragOffset < -80) {
      widget.onMove();
    }
    setState(() => _dragOffset = 0);
  }

  Color _difficultyColor(WordDifficulty d) {
    switch (d) {
      case WordDifficulty.easy:
        return const Color(0xFF4ADE80);
      case WordDifficulty.medium:
        return AppColors.yellow;
      case WordDifficulty.hard:
        return Colors.redAccent;
    }
  }

  String _difficultyLabel(WordDifficulty d) {
    switch (d) {
      case WordDifficulty.easy:
        return "Easy";
      case WordDifficulty.medium:
        return "Medium";
      case WordDifficulty.hard:
        return "Hard";
    }
  }

  @override
  Widget build(BuildContext context) {
    final swipeColor = _dragOffset > 0
        ? const Color(0xFF4ADE80)
        : (widget.word.status == WordStatus.learning
            ? const Color(0xFF4ADE80)
            : AppColors.yellow);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            alignment: _dragOffset > 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            decoration: BoxDecoration(
              color: swipeColor.withOpacity(.20),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: swipeColor.withOpacity(.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_dragOffset > 0) ...[
                  Icon(widget.actionIcon, color: swipeColor, size: 22.sp),
                  SizedBox(width: 8.w),
                  Text(
                    widget.actionLabel,
                    style: GoogleFonts.poppins(
                      color: swipeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
                if (_dragOffset <= 0) ...[
                  Text(
                    widget.actionLabel,
                    style: GoogleFonts.poppins(
                      color: swipeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(widget.actionIcon, color: swipeColor, size: 22.sp),
                ],
              ],
            ),
          ),
        ),
        GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
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
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _difficultyColor(widget.word.difficulty)
                              .withOpacity(.15),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: _difficultyColor(widget.word.difficulty)
                                .withOpacity(.4),
                          ),
                        ),
                        child: Text(
                          _difficultyLabel(widget.word.difficulty),
                          style: GoogleFonts.poppins(
                            color: _difficultyColor(widget.word.difficulty),
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                      if (widget.word.totalAttempts > 0) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.sky.withOpacity(.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.percent_rounded,
                                  color: AppColors.sky, size: 9.sp),
                              SizedBox(width: 2.w),
                              Text(
                                "${(widget.word.accuracy * 100).toStringAsFixed(0)}%",
                                style: GoogleFonts.poppins(
                                  color: AppColors.sky,
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onDelete();
                        },
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    widget.word.word,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    widget.word.translation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: AppColors.yellow,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.word.pronunciation != null) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.volume_up_rounded,
                            color: Colors.white.withOpacity(.5), size: 11.sp),
                        SizedBox(width: 3.w),
                        Text(
                          widget.word.pronunciation!,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.5),
                            fontSize: 10.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                  AnimatedSize(
                    duration: 250.ms,
                    curve: Curves.easeOut,
                    child: _isExpanded
                        ? Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.word.exampleSentence != null) ...[
                                  Container(
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.sky.withOpacity(.10),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: AppColors.sky.withOpacity(.25),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.format_quote_rounded,
                                            color: AppColors.sky, size: 14.sp),
                                        SizedBox(width: 6.w),
                                        Expanded(
                                          child: Text(
                                            widget.word.exampleSentence!,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white
                                                  .withOpacity(.85),
                                              fontSize: 10.5.sp,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: widget.onMove,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 7.h),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              widget.actionColor
                                                  .withOpacity(.4),
                                              widget.actionColor
                                                  .withOpacity(.15),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: widget.actionColor
                                                .withOpacity(.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(widget.actionIcon,
                                                color: widget.actionColor,
                                                size: 12.sp),
                                            SizedBox(width: 4.w),
                                            Text(
                                              widget.actionLabel,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 7.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(.06),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            color: Colors.white.withOpacity(.5),
                                            size: 11.sp,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            _timeAgo(widget.word.addedAt),
                                            style: GoogleFonts.poppins(
                                              color: Colors.white
                                                  .withOpacity(.5),
                                              fontSize: 9.5.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (!_isExpanded) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onMove,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.actionColor.withOpacity(.4),
                                      widget.actionColor.withOpacity(.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(widget.actionIcon,
                                        color: widget.actionColor,
                                        size: 11.sp),
                                    SizedBox(width: 3.w),
                                    Text(
                                      widget.actionLabel,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Colors.white.withOpacity(.4),
                              size: 10.sp,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              _timeAgo(widget.word.addedAt),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(.4),
                                fontSize: 9.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    )
        .animate(delay: (50 * widget.index).ms)
        .fadeIn(duration: 400.ms)
        .moveY(begin: 12, end: 0);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 30) return "${diff.inDays}d ago";
    return "${(diff.inDays / 30).floor()}mo ago";
  }
}
class FlashcardPracticeScreen extends StatefulWidget {
  final List<WordItem> words;
  final void Function(WordItem) onUpdateWord;

  const FlashcardPracticeScreen({
    super.key,
    required this.words,
    required this.onUpdateWord,
  });

  @override
  State<FlashcardPracticeScreen> createState() =>
      _FlashcardPracticeScreenState();
}

class _FlashcardPracticeScreenState extends State<FlashcardPracticeScreen>
    with TickerProviderStateMixin {
  late List<WordItem> _queue;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _totalAnswered = 0;
  bool _showAnswer = false;
  late AnimationController _flipController;
  late AnimationController _slideController;
  Offset _slideOffset = Offset.zero;
  bool _isAnimating = false;
  Offset _targetSlide = Offset.zero;

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.words)..shuffle();
    _flipController = AnimationController(
      vsync: this,
      duration: 500.ms,
    );
    _slideController = AnimationController(
      vsync: this,
      duration: 400.ms,
    )..addListener(() {
        setState(() {
          _slideOffset = Offset.lerp(
            const Offset(0, 0),
            _targetSlide,
            _slideController.value,
          )!;
        });
      });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showAnswer) return;
    HapticFeedback.selectionClick();
    setState(() => _showAnswer = true);
    _flipController.forward();
  }

  void _answer(bool knowsIt) {
    if (_isAnimating) return;
    _isAnimating = true;
    HapticFeedback.mediumImpact();

    final word = _queue[_currentIndex];
    final updated = word.copyWith(
      totalAttempts: word.totalAttempts + 1,
      correctAnswers: word.correctAnswers + (knowsIt ? 1 : 0),
      status: knowsIt ? WordStatus.mastered : WordStatus.learning,
    );
    widget.onUpdateWord(updated);

    setState(() {
      _correctCount += knowsIt ? 1 : 0;
      _totalAnswered += 1;
    });

    _targetSlide = knowsIt
        ? const Offset(1.5, 0)
        : const Offset(-1.5, 0);

    _slideController.forward(from: 0).then((_) {
      _flipController.reset();
      setState(() {
        _showAnswer = false;
        _currentIndex++;
        _slideOffset = Offset.zero;
        _isAnimating = false;
      });
      if (_currentIndex >= _queue.length) {
        _showResults();
      }
    });
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PracticeResultsDialog(
        correct: _correctCount,
        total: _totalAnswered,
        onClose: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _queue.length) {
      return const SizedBox.shrink();
    }

    final word = _queue[_currentIndex];
    final progress = (_currentIndex + 1) / _queue.length;

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          _buildBackground(),
          _TwinklingStars(count: 30),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(progress),
                SizedBox(height: 16.h),
                _buildProgressBar(progress),
                SizedBox(height: 20.h),

                SizedBox(
                  height: 340.h,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Transform.translate(
                        offset: Offset(
                          _slideOffset.dx * 180.w,
                          _slideOffset.dy * 80.h,
                        ),
                        child: Transform.rotate(
                          angle: _slideOffset.dx * 0.25,
                          child: _Flashcard(
                            word: word,
                            showAnswer: _showAnswer,
                            flipController: _flipController,
                            onTap: _flipCard,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Spacer(),
                _buildAnswerButtons(),

                SizedBox(height: 10.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    _showAnswer
                        ? "Tap a button to continue"
                        : "Tap the card to reveal the answer",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.4),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
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
          top: -100.h,
          right: -80.w,
          child: Container(
            width: 280.w,
            height: 280.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.yellow.withOpacity(0.10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(.3),
                  blurRadius: 160,
                  spreadRadius: 40,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1,
                end: 1.1,
                duration: 5000.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          bottom: 100.h,
          left: -80.w,
          child: Container(
            width: 240.w,
            height: 240.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sky.withOpacity(0.10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sky.withOpacity(.3),
                  blurRadius: 160,
                  spreadRadius: 40,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1,
                end: 1.12,
                duration: 6000.ms,
                curve: Curves.easeInOut,
              ),
        ),
      ],
    );
  }

  Widget _buildTopBar(double progress) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _showExitConfirm();
            },
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.10),
                border: Border.all(color: Colors.white.withOpacity(.20)),
              ),
              child:
                  Icon(Icons.close_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Practice",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "${_currentIndex + 1} of ${_queue.length} • $_correctCount correct",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.6),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.orange, AppColors.yellow],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: Colors.black, size: 13.sp),
                SizedBox(width: 3.w),
                Text(
                  "${(_correctCount * 10)}",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildProgressBar(double progress) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        height: 8.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.10),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: 400.ms,
              curve: Curves.easeOutCubic,
              width: MediaQuery.of(context).size.width * 0.9 * progress,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.yellow],
                ),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: _answerButton(
              label: "Still Learning",
              icon: Icons.replay_rounded,
              gradient: const [Colors.redAccent, Color(0xFFFF6B6B)],
              onTap: () => _answer(false),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _answerButton(
              label: "I Know It",
              icon: Icons.check_rounded,
              gradient: const [Color(0xFF4ADE80), Color(0xFF22C55E)],
              onTap: () => _answer(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerButton({
  required String label,
  required IconData icon,
  required List<Color> gradient,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 15.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(.5),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: .3,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  void _showExitConfirm() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.all(22.w),
              decoration: BoxDecoration(
                color: AppColors.dark.withOpacity(.92),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withOpacity(.15),
                    ),
                    child: Icon(Icons.exit_to_app_rounded,
                        color: Colors.redAccent, size: 26.sp),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    "Exit Practice?",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "Your progress will be lost.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.65),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.08),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                  color: Colors.white.withOpacity(.15)),
                            ),
                            child: Text(
                              "Continue",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.redAccent, Color(0xFFFF6B6B)],
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Text(
                              "Exit",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
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
      ),
    );
  }
}
class _Flashcard extends StatelessWidget {
  final WordItem word;
  final bool showAnswer;
  final AnimationController flipController;
  final VoidCallback onTap;

  const _Flashcard({
    required this.word,
    required this.showAnswer,
    required this.flipController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: flipController,
        builder: (context, _) {
          final value = flipController.value;
          final isFront = value < 0.5;
          final rotation = value * math.pi;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotation),
            child: isFront
                ? _cardFront(word)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _cardBack(word),
                  ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scaleXY(
          begin: 0.95,
          end: 1,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _cardFront(WordItem word) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 280.h, maxHeight: 340.h),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(.12),
            Colors.white.withOpacity(.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(.20), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withOpacity(.25),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.sky.withOpacity(.35),
                  AppColors.sky.withOpacity(.05),
                ],
              ),
            ),
            child: Icon(
              Icons.translate_rounded,
              color: AppColors.sky,
              size: 22.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            "What does this mean?",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.55),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: .5,
            ),
          ),
          SizedBox(height: 10.h),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                word.word,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                  height: 1.15,
                ),
              ),
            ),
          ),
          if (word.pronunciation != null) ...[
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up_rounded,
                    color: Colors.white.withOpacity(.5), size: 13.sp),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    word.pronunciation!,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.5),
                      fontSize: 11.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 14.h),
          if (!showAnswer)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.08),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded,
                      color: Colors.white.withOpacity(.7), size: 12.sp),
                  SizedBox(width: 5.w),
                  Text(
                    "Tap to reveal",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.7),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1, end: 1.05, duration: 1200.ms),
        ],
      ),
    );
  }

  Widget _cardBack(WordItem word) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 280.h, maxHeight: 340.h),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.yellow.withOpacity(.30),
            AppColors.orange.withOpacity(.15),
          ],
        ),
        border:
            Border.all(color: AppColors.yellow.withOpacity(.50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellow.withOpacity(.35),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.yellow.withOpacity(.40),
                  AppColors.yellow.withOpacity(.05),
                ],
              ),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: AppColors.yellow,
              size: 22.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            "The translation is",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.7),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: .5,
            ),
          ),
          SizedBox(height: 10.h),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                word.translation,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                  height: 1.2,
                ),
              ),
            ),
          ),
          if (word.exampleSentence != null) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.30),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.format_quote_rounded,
                          color: AppColors.yellow, size: 12.sp),
                      SizedBox(width: 4.w),
                      Text(
                        "Example",
                        style: GoogleFonts.poppins(
                          color: AppColors.yellow,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    word.exampleSentence!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.9),
                      fontSize: 10.5.sp,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _PracticeResultsDialog extends StatefulWidget {
  final int correct;
  final int total;
  final VoidCallback onClose;

  const _PracticeResultsDialog({
    required this.correct,
    required this.total,
    required this.onClose,
  });

  @override
  State<_PracticeResultsDialog> createState() => _PracticeResultsDialogState();
}

class _PracticeResultsDialogState extends State<_PracticeResultsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: 1500.ms,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent =
        widget.total == 0 ? 0 : (widget.correct * 100 ~/ widget.total);
    final xp = widget.correct * 10;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.dark.withOpacity(.92),
                  AppColors.primary.withOpacity(.60),
                ],
              ),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(color: Colors.white.withOpacity(.20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120.w,
                  height: 120.w,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(120.w, 120.w),
                            painter: _CircularPercentPainter(
                              percent: percent / 100,
                              animationValue: _controller.value,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$percent%",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24.sp,
                                ),
                              ),
                              Text(
                                "Score",
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(.7),
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  _getMessage(percent),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20.sp,
                    letterSpacing: .2,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "${widget.correct} of ${widget.total} correct answers",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.7),
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: _resultStat(
                        icon: Icons.star_rounded,
                        value: "+$xp",
                        label: "XP Earned",
                        color: AppColors.yellow,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _resultStat(
                        icon: Icons.local_fire_department_rounded,
                        value: "${widget.correct}",
                        label: "Streak +",
                        color: AppColors.orange,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _resultStat(
                        icon: Icons.check_circle_rounded,
                        value: "${widget.total - widget.correct}",
                        label: "To Review",
                        color: AppColors.sky,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.10),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                                color: Colors.white.withOpacity(.15)),
                          ),
                          child: Text(
                            "Done",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.sp,
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
  }

  String _getMessage(int percent) {
    if (percent == 100) return "🏆 Perfect!";
    if (percent >= 80) return "🌟 Excellent!";
    if (percent >= 60) return "👏 Great Job!";
    if (percent >= 40) return "💪 Keep Going!";
    return "📚 Keep Practicing!";
  }

  Widget _resultStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(.20),
            color.withOpacity(.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14.sp,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.6),
              fontSize: 8.5.sp,
            ),
          ),
        ],
      ),
    );
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
            child: Container(
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