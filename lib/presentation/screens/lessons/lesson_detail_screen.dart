import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/student/lesson_words/lesson_words_cubit.dart';
import 'package:fluent/cubit/student/lesson_words/lesson_words_state.dart';
import 'package:fluent/cubit/student/lessons/lesson_detail_cubit.dart';
import 'package:fluent/cubit/student/lessons/lesson_detail_state.dart';
import 'package:fluent/data/models/lesson_detail_model.dart';
import 'package:fluent/data/models/lesson_word_model.dart';
import 'package:fluent/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

enum _LessonStep { video, words, test }

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = d.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

class LessonDetailScreen extends StatefulWidget {
  final int? lessonId;
  final String lessonTitle;

  const LessonDetailScreen({super.key, this.lessonId, this.lessonTitle = ''});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  _LessonStep _step = _LessonStep.video;
  bool _isSendingComment = false;
  int? _busyCommentId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _wordsRequested = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _playWordAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.trim().isEmpty) {
      showAppSnackBar(
        context,
        'No audio for this word',
        type: AppSnackType.warning,
      );
      return;
    }
    try {
      var url = audioUrl;
      if (!url.startsWith('http')) url = '$baseUrl$audioUrl';
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Failed to play audio',
        type: AppSnackType.error,
      );
    }
  }

  void _goNext() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_step == _LessonStep.video) {
        _step = _LessonStep.words;
        _ensureWordsLoaded();
      } else if (_step == _LessonStep.words) {
        _step = _LessonStep.test;
      }
    });
  }

  void _goBackStep() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_step == _LessonStep.test) {
        _step = _LessonStep.words;
      } else if (_step == _LessonStep.words) {
        _step = _LessonStep.video;
      } else {
        Navigator.of(context).maybePop();
      }
    });
  }

  void _ensureWordsLoaded() {
    final id = widget.lessonId;
    if (id == null || _wordsRequested) return;
    _wordsRequested = true;
    context.read<LessonWordsCubit>().fetchLessonWords(id);
  }

  void _openComments(LessonDetailModel data) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<LessonDetailCubit>(),
          child: _CommentsSheet(
            data: data,
            isSending: _isSendingComment,
            busyCommentId: _busyCommentId,
            onAdd: _handleAddComment,
            onEdit: _handleEditComment,
            onDelete: _handleDeleteComment,
            onLoadMore: () =>
                context.read<LessonDetailCubit>().loadMoreComments(),
            onShowActions: (comment, {required bool canEdit}) {
              _showCommentActions(comment, canEdit: canEdit);
            },
          ),
        );
      },
    );
  }

  Future<String?> _handleAddComment(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Comment cannot be empty';
    if (trimmed.length > LessonDetailCubit.maxCommentLength) {
      return 'Comment must not exceed ${LessonDetailCubit.maxCommentLength} characters';
    }
    final lessonId = widget.lessonId;
    if (lessonId == null) return 'Invalid lesson';
    setState(() => _isSendingComment = true);
    final error = await context.read<LessonDetailCubit>().submitComment(
      lessonId,
      trimmed,
    );
    if (mounted) setState(() => _isSendingComment = false);
    return error;
  }

  Future<String?> _handleEditComment(int commentId, String newText) async {
    setState(() => _busyCommentId = commentId);
    final error = await context.read<LessonDetailCubit>().editComment(
      commentId,
      newText,
    );
    if (mounted) setState(() => _busyCommentId = null);
    return error;
  }

  Future<String?> _handleDeleteComment(int commentId) async {
    setState(() => _busyCommentId = commentId);
    final error = await context.read<LessonDetailCubit>().removeComment(
      commentId,
    );
    if (mounted) setState(() => _busyCommentId = null);
    return error;
  }

  void _showErrorSnack(String message) {
    showAppSnackBar(context, message, type: AppSnackType.error);
  }

  void _showCommentActions(LessonCommentModel comment, {bool canEdit = true}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B2A3A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                if (canEdit)
                  ListTile(
                    leading: Icon(
                      Icons.edit_rounded,
                      color: AppColors.sky,
                      size: 22.sp,
                    ),
                    title: Text(
                      'Edit comment',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEditDialog(comment);
                    },
                  ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 22.sp,
                  ),
                  title: Text(
                    'Delete comment',
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(comment);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEditDialog(LessonCommentModel comment) {
    final controller = TextEditingController(text: comment.comment);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.dark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          title: Text(
            'Edit Comment',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            maxLength: LessonDetailCubit.maxCommentLength,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14.sp),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx);
                final err = await _handleEditComment(comment.id, text);
                if (err != null && mounted) _showErrorSnack(err);
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(LessonCommentModel comment) {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.dark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          title: Text(
            'Delete comment?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          content: Text(
            'This action cannot be undone.',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    ).then((ok) async {
      if (ok == true) {
        final err = await _handleDeleteComment(comment.id);
        if (err != null && mounted) _showErrorSnack(err);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          const _LessonBackdrop(),
          SafeArea(
            child: Column(
              children: [
                BlocBuilder<LessonDetailCubit, LessonDetailState>(
                  builder: (context, state) {
                    final data = state is LessonDetailSuccess
                        ? state.data
                        : null;
                    final commentsCount = data?.commentsTotal ?? 0;
                    return _TopBar(
                      step: _step,
                      title: widget.lessonTitle.isNotEmpty
                          ? widget.lessonTitle
                          : (data?.lesson?.title ?? 'Lesson'),
                      commentsCount: commentsCount,
                      onBack: _goBackStep,
                      onComments: data == null
                          ? null
                          : () => _openComments(data),
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<LessonDetailCubit, LessonDetailState>(
                    builder: (context, state) {
                      if (state is LessonDetailLoading ||
                          state is LessonDetailInitial) {
                        return const _CenteredLoader();
                      }
                      if (state is LessonDetailFailure) {
                        return _ErrorView(
                          message: state.message,
                          onRetry: () {
                            if (widget.lessonId != null) {
                              context
                                  .read<LessonDetailCubit>()
                                  .fetchLessonDetail(widget.lessonId!);
                            }
                          },
                        );
                      }
                      if (state is LessonDetailSuccess) {
                        return _StepBody(
                          step: _step,
                          data: state.data,
                          onNext: _goNext,
                          onPlayAudio: _playWordAudio,
                          onStartTest: () async {
                            final testId = state.data.lesson?.testId;
                            if (testId == null) return;
                            final result = await Navigator.pushNamed(
                              context,
                              studentTestRoute,
                              arguments: {
                                'testId': testId,
                                'title':
                                    state.data.lesson?.title ??
                                    widget.lessonTitle,
                                'xpPoints': state.data.lesson?.xpPoints ?? 0,
                              },
                            );
                            if (!context.mounted) return;

                            if (result is Map) {
                              final completed = result['completed'] == true;
                              final passed = result['passed'] == true;
                              final goToLessons = result['goToLessons'] == true;

                              if (completed && passed && goToLessons) {
                                Navigator.of(context).pop(true);
                                return;
                              }

                              if (widget.lessonId != null) {
                                context
                                    .read<LessonDetailCubit>()
                                    .fetchLessonDetail(widget.lessonId!);
                              }
                              if (completed && !passed) {
                                setState(() => _step = _LessonStep.video);
                              }
                            }
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
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

class _TopBar extends StatelessWidget {
  final _LessonStep step;
  final String title;
  final int commentsCount;
  final VoidCallback onBack;
  final VoidCallback? onComments;

  const _TopBar({
    required this.step,
    required this.title,
    required this.commentsCount,
    required this.onBack,
    required this.onComments,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
      child: Column(
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzelDecorative(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _CommentIconButton(count: commentsCount, onTap: onComments),
            ],
          ),
          SizedBox(height: 14.h),
          _StepIndicator(step: step),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final _LessonStep step;
  const _StepIndicator({required this.step});

  int get _index {
    switch (step) {
      case _LessonStep.video:
        return 0;
      case _LessonStep.words:
        return 1;
      case _LessonStep.test:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Video', 'Words', 'Test'];
    return Row(
      children: List.generate(3, (i) {
        final active = i == _index;
        final done = i < _index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: 280.ms,
                  height: 4.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                    color: done || active
                        ? (active ? AppColors.yellow : AppColors.sky)
                        : Colors.white.withOpacity(0.12),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.yellow.withOpacity(0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  labels[i],
                  style: GoogleFonts.poppins(
                    color: active
                        ? AppColors.yellow
                        : done
                        ? AppColors.sky
                        : Colors.white38,
                    fontSize: 10.sp,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: Icon(icon, color: Colors.white, size: 18.sp),
        ),
      ),
    );
  }
}

class _CommentIconButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _CommentIconButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.sky,
                size: 18.sp,
              ),
              if (count > 0) ...[
                SizedBox(width: 6.w),
                Text(
                  count > 99 ? '99+' : '$count',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final _LessonStep step;
  final LessonDetailModel data;
  final VoidCallback onNext;
  final Future<void> Function(String?) onPlayAudio;
  final VoidCallback onStartTest;

  const _StepBody({
    required this.step,
    required this.data,
    required this.onNext,
    required this.onPlayAudio,
    required this.onStartTest,
  });

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case _LessonStep.video:
        return _VideoStep(data: data, onNext: onNext);
      case _LessonStep.words:
        return _WordsStep(onNext: onNext, onPlayAudio: onPlayAudio);
      case _LessonStep.test:
        return _TestStep(data: data, onStartTest: onStartTest);
    }
  }
}

class _VideoStep extends StatelessWidget {
  final LessonDetailModel data;
  final VoidCallback onNext;
  const _VideoStep({required this.data, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final lesson = data.lesson;
    final title = lesson?.title ?? 'Lesson';
    final xp = lesson?.xpPoints ?? 0;
    final videoUrl = lesson?.video ?? '';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LessonHeroCard(title: title, xp: xp)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                SizedBox(height: 16.h),
                if (videoUrl.trim().isEmpty)
                  const _EmptyVideoCard()
                else
                  _LessonVideoPlayer(
                    videoUrl: videoUrl,
                    title: title,
                  ).animate().fadeIn(delay: 80.ms, duration: 450.ms),
                SizedBox(height: 12.h),
                Text(
                  'Watch the lesson, then continue to vocabulary and the quiz.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12.sp,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomCta(
          label: 'Next · Words',
          icon: Icons.arrow_forward_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _LessonHeroCard extends StatelessWidget {
  final String title;
  final int xp;
  const _LessonHeroCard({required this.title, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
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
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              gradient: LinearGradient(
                colors: [
                  AppColors.yellow.withOpacity(0.9),
                  AppColors.orange.withOpacity(0.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.play_lesson_rounded,
              color: AppColors.dark,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.yellow.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: AppColors.yellow,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '+$xp XP',
                        style: GoogleFonts.poppins(
                          color: AppColors.yellow,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _EmptyVideoCard extends StatelessWidget {
  const _EmptyVideoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 36.sp),
          SizedBox(height: 8.h),
          Text(
            'No video available',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}

class _WordsStep extends StatelessWidget {
  final VoidCallback onNext;
  final Future<void> Function(String?) onPlayAudio;
  const _WordsStep({required this.onNext, required this.onPlayAudio});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
          child: Row(
            children: [
              Icon(Icons.menu_book_rounded, color: AppColors.sky, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Lesson vocabulary',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<LessonWordsCubit, LessonWordsState>(
            listener: (context, state) {
              if (state is LessonWordsActionSuccess) {
                showAppSnackBar(
                  context,
                  state.message,
                  type: AppSnackType.success,
                );
              } else if (state is LessonWordsFailure) {
                showAppSnackBar(
                  context,
                  state.message,
                  type: AppSnackType.error,
                );
              }
            },
            builder: (context, state) {
              if (state is LessonWordsLoading || state is LessonWordsInitial) {
                return const _CenteredLoader();
              }

              List<LessonWordModel> words = const [];
              int? busyId;
              if (state is LessonWordsSuccess) {
                words = state.words;
                busyId = state.busyWordId;
              } else if (state is LessonWordsActionSuccess) {
                words = state.words;
              } else if (state is LessonWordsFailure) {
                return Center(
                  child: Text(
                    state.message,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13.sp,
                    ),
                  ),
                );
              }

              if (words.isEmpty) {
                return Center(
                  child: Text(
                    'No words in this lesson yet.',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13.sp,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                itemCount: words.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, i) {
                  final w = words[i];
                  return _WordCard(
                    word: w,
                    busy: busyId == w.id,
                    onPlay: () => onPlayAudio(w.audio),
                    onLearning: () =>
                        context.read<LessonWordsCubit>().moveToLearning(w.id),
                    onKnow: () =>
                        context.read<LessonWordsCubit>().moveToKnow(w.id),
                  );
                },
              );
            },
          ),
        ),
        _BottomCta(
          label: 'Next · Lesson test',
          icon: Icons.arrow_forward_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  final LessonWordModel word;
  final bool busy;
  final VoidCallback onPlay;
  final VoidCallback onLearning;
  final VoidCallback onKnow;

  const _WordCard({
    required this.word,
    required this.busy,
    required this.onPlay,
    required this.onLearning,
    required this.onKnow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: word.hasAudio ? onPlay : null,
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withOpacity(0.18),
                border: Border.all(color: AppColors.orange.withOpacity(0.45)),
              ),
              child: Icon(
                word.hasAudio
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: AppColors.orange,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.wordEn,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (word.wordAr.isNotEmpty)
                  Text(
                    word.wordAr,
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 12.sp,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
              ],
            ),
          ),
          if (busy)
            SizedBox(
              width: 22.w,
              height: 22.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.yellow,
              ),
            )
          else ...[
            _MiniChip(label: 'Learn', color: AppColors.sky, onTap: onLearning),
            SizedBox(width: 6.w),
            _MiniChip(label: 'Know', color: AppColors.yellow, onTap: onKnow),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MiniChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TestStep extends StatelessWidget {
  final LessonDetailModel data;
  final VoidCallback onStartTest;
  const _TestStep({required this.data, required this.onStartTest});

  @override
  Widget build(BuildContext context) {
    final hasTest = data.lesson?.testId != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 88.w,
            height: 88.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.yellow.withOpacity(0.25),
                  AppColors.orange.withOpacity(0.15),
                ],
              ),
              border: Border.all(color: AppColors.yellow.withOpacity(0.45)),
            ),
            child: Icon(
              hasTest ? Icons.quiz_rounded : Icons.hourglass_empty_rounded,
              color: AppColors.yellow,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            hasTest ? 'Ready for the lesson test?' : 'No test available yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            hasTest
                ? 'Answer the questions in order. Passing unlocks the next lesson and earns XP.'
                : 'Your teacher has not published a test for this lesson yet. You can still review the video and words.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          const Spacer(),
          if (hasTest)
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: onStartTest,
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
                    Icon(Icons.play_arrow_rounded, size: 24.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'Start lesson test',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'Back to course',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? title;
  const _LessonVideoPlayer({required this.videoUrl, this.title});

  @override
  State<_LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<_LessonVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initializing = true;
  String? _error;
  bool _isMuted = false;
  double _speed = 1.0;
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      var url = widget.videoUrl;
      if (!url.startsWith('http')) url = '$baseUrl$url';
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      c.setLooping(false);
      c.addListener(() {
        if (mounted) setState(() {});
      });
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load video';
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openFullscreen() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    HapticFeedback.selectionClick();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => _FullscreenVideoPage(
          controller: c,
          title: widget.title,
          isMuted: _isMuted,
          speed: _speed,
          speeds: _speeds,
          onMuteChanged: (m) {
            _isMuted = m;
            c.setVolume(m ? 0 : 1);
          },
          onSpeedChanged: (s) {
            _speed = s;
            c.setPlaybackSpeed(s);
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) setState(() {});
  }

  void _cycleSpeed() {
    final i = _speeds.indexOf(_speed);
    final next = _speeds[(i + 1) % _speeds.length];
    setState(() {
      _speed = next;
      _controller?.setPlaybackSpeed(next);
    });
    HapticFeedback.selectionClick();
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      _isMuted = !_isMuted;
      c.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Container(
        height: 210.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: const CircularProgressIndicator(color: AppColors.yellow),
      );
    }
    if (_error != null || _controller == null) {
      return Container(
        height: 210.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Text(
          _error ?? 'Video unavailable',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    final c = _controller!;
    final ar = c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: AspectRatio(
        aspectRatio: ar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(onTap: _togglePlay, child: VideoPlayer(c)),
            _InlineControls(
              controller: c,
              isMuted: _isMuted,
              speed: _speed,
              onTogglePlay: _togglePlay,
              onToggleMute: _toggleMute,
              onCycleSpeed: _cycleSpeed,
              onFullscreen: _openFullscreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineControls extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isMuted;
  final double speed;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;
  final VoidCallback onCycleSpeed;
  final VoidCallback onFullscreen;

  const _InlineControls({
    required this.controller,
    required this.isMuted,
    required this.speed,
    required this.onTogglePlay,
    required this.onToggleMute,
    required this.onCycleSpeed,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    final pos = v.position;
    final dur = v.duration;
    final progress = dur.inMilliseconds == 0
        ? 0.0
        : pos.inMilliseconds / dur.inMilliseconds;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.35),
            Colors.transparent,
            Colors.black.withOpacity(0.65),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
            child: Row(
              children: [
                const Spacer(),
                _CtrlChip(label: '${speed}x', onTap: onCycleSpeed),
                SizedBox(width: 6.w),
                _CtrlIcon(
                  icon: isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  onTap: onToggleMute,
                ),
                SizedBox(width: 4.w),
                _CtrlIcon(icon: Icons.fullscreen_rounded, onTap: onFullscreen),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: GestureDetector(
              onTap: onTogglePlay,
              child: Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellow,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(0.35),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(
                  v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppColors.dark,
                  size: 30.sp,
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
            child: Row(
              children: [
                Text(
                  _formatDuration(pos),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.h,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 6.r,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: 12.r,
                      ),
                      activeTrackColor: AppColors.yellow,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.yellow,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (x) {
                        final ms = (dur.inMilliseconds * x).round();
                        controller.seekTo(Duration(milliseconds: ms));
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(dur),
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

class _CtrlChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CtrlChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CtrlIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CtrlIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Icon(icon, color: Colors.white, size: 18.sp),
        ),
      ),
    );
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String? title;
  final bool isMuted;
  final double speed;
  final List<double> speeds;
  final ValueChanged<bool> onMuteChanged;
  final ValueChanged<double> onSpeedChanged;

  const _FullscreenVideoPage({
    required this.controller,
    required this.title,
    required this.isMuted,
    required this.speed,
    required this.speeds,
    required this.onMuteChanged,
    required this.onSpeedChanged,
  });

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late bool _muted;
  late double _speed;
  bool _showControls = true;
  Timer? _hideTimer;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _muted = widget.isMuted;
    _speed = widget.speed;
    widget.controller.addListener(_tick);
    _scheduleHide();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  Future<void> _exit() async {
    if (_exiting) return;
    _exiting = true;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_tick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final v = c.value;
    final pos = v.position;
    final dur = v.duration;
    final progress = dur.inMilliseconds == 0
        ? 0.0
        : pos.inMilliseconds / dur.inMilliseconds;

    return WillPopScope(
      onWillPop: () async {
        await _exit();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() => _showControls = !_showControls);
            if (_showControls) _scheduleHide();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: v.aspectRatio == 0 ? 16 / 9 : v.aspectRatio,
                  child: VideoPlayer(c),
                ),
              ),
              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: 200.ms,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
                          child: Row(
                            children: [
                              _CtrlIcon(
                                icon: Icons.close_rounded,
                                onTap: _exit,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  widget.title ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                              _CtrlChip(
                                label: '${_speed}x',
                                onTap: () {
                                  final i = widget.speeds.indexOf(_speed);
                                  final next = widget
                                      .speeds[(i + 1) % widget.speeds.length];
                                  setState(() => _speed = next);
                                  widget.onSpeedChanged(next);
                                  c.setPlaybackSpeed(next);
                                  _scheduleHide();
                                },
                              ),
                              SizedBox(width: 6.w),
                              _CtrlIcon(
                                icon: _muted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                onTap: () {
                                  setState(() => _muted = !_muted);
                                  widget.onMuteChanged(_muted);
                                  c.setVolume(_muted ? 0 : 1);
                                  _scheduleHide();
                                },
                              ),
                              SizedBox(width: 4.w),
                              _CtrlIcon(
                                icon: Icons.screen_rotation_rounded,
                                onTap: () async {
                                  final orient = MediaQuery.of(
                                    context,
                                  ).orientation;
                                  if (orient == Orientation.portrait) {
                                    await SystemChrome.setPreferredOrientations(
                                      [
                                        DeviceOrientation.landscapeLeft,
                                        DeviceOrientation.landscapeRight,
                                      ],
                                    );
                                  } else {
                                    await SystemChrome.setPreferredOrientations(
                                      [
                                        DeviceOrientation.portraitUp,
                                        DeviceOrientation.portraitDown,
                                      ],
                                    );
                                  }
                                  _scheduleHide();
                                },
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (c.value.isPlaying) {
                              c.pause();
                            } else {
                              c.play();
                              _scheduleHide();
                            }
                          },
                          child: Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.yellow,
                            ),
                            child: Icon(
                              v.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppColors.dark,
                              size: 34.sp,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                          child: Row(
                            children: [
                              Text(
                                _formatDuration(pos),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3.5.h,
                                    thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 7.r,
                                    ),
                                    activeTrackColor: AppColors.yellow,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: AppColors.yellow,
                                  ),
                                  child: Slider(
                                    value: progress.clamp(0.0, 1.0),
                                    onChanged: (x) {
                                      final ms = (dur.inMilliseconds * x)
                                          .round();
                                      c.seekTo(Duration(milliseconds: ms));
                                    },
                                    onChangeStart: (_) => _hideTimer?.cancel(),
                                    onChangeEnd: (_) => _scheduleHide(),
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(dur),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

class _CommentsSheet extends StatefulWidget {
  final LessonDetailModel data;
  final bool isSending;
  final int? busyCommentId;
  final Future<String?> Function(String text) onAdd;
  final Future<String?> Function(int id, String text) onEdit;
  final Future<String?> Function(int id) onDelete;
  final Future<void> Function() onLoadMore;
  final void Function(LessonCommentModel comment, {required bool canEdit})
  onShowActions;

  const _CommentsSheet({
    required this.data,
    required this.isSending,
    required this.busyCommentId,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onLoadMore,
    required this.onShowActions,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 80) {
        final state = context.read<LessonDetailCubit>().state;
        if (state is LessonDetailSuccess &&
            state.data.hasMoreComments &&
            !state.isLoadingMore) {
          widget.onLoadMore();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final err = await widget.onAdd(text);
    if (!mounted) return;
    if (err != null) {
      showAppSnackBar(context, err, type: AppSnackType.error);
    } else {
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return BlocBuilder<LessonDetailCubit, LessonDetailState>(
      builder: (context, state) {
        final data = state is LessonDetailSuccess ? state.data : widget.data;
        final loadingMore = state is LessonDetailSuccess
            ? state.isLoadingMore
            : false;
        final comments = data.comments;

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B2A3A), Color(0xFF013C58)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border.all(color: AppColors.sky.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 14.h, 12.w, 8.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_rounded,
                        color: AppColors.sky,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Comments',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sky.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '${data.commentsTotal}',
                          style: GoogleFonts.poppins(
                            color: AppColors.sky,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
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
                  child: comments.isEmpty
                      ? Center(
                          child: Text(
                            'No comments yet. Be the first!',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 13.sp,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scroll,
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                          itemCount: comments.length + (loadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
                          itemBuilder: (context, i) {
                            if (i >= comments.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: SizedBox(
                                    width: 22.w,
                                    height: 22.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.yellow,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final c = comments[i];
                            return _CommentTile(
                              comment: c,
                              busy: widget.busyCommentId == c.id,
                              onMore: c.isOwn
                                  ? () => widget.onShowActions(
                                      c,
                                      canEdit: data.canUpdateComments,
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
                if (data.canCreateComment)
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: 1,
                            maxLength: LessonDetailCubit.maxCommentLength,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13.sp,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Write a comment…',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: 13.sp,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.07),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Material(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(14.r),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14.r),
                            onTap: widget.isSending ? null : _submit,
                            child: SizedBox(
                              width: 46.w,
                              height: 46.w,
                              child: widget.isSending
                                  ? Padding(
                                      padding: EdgeInsets.all(12.w),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.dark,
                                      ),
                                    )
                                  : Icon(
                                      Icons.send_rounded,
                                      color: AppColors.dark,
                                      size: 20.sp,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.all(14.w),
                    child: Text(
                      'Comments are disabled for this lesson.',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final LessonCommentModel comment;
  final bool busy;
  final VoidCallback? onMore;

  const _CommentTile({required this.comment, required this.busy, this.onMore});

  @override
  Widget build(BuildContext context) {
    final name = comment.user?.fullName.isNotEmpty == true
        ? comment.user!.fullName
        : 'Student';
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: AppColors.sky.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                color: AppColors.sky,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (comment.isOwn && onMore != null)
                      busy
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.yellow,
                              ),
                            )
                          : GestureDetector(
                              onTap: onMore,
                              child: Icon(
                                Icons.more_horiz_rounded,
                                color: Colors.white54,
                                size: 18.sp,
                              ),
                            ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  comment.comment,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13.sp,
                    height: 1.4,
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

class _BottomCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _BottomCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: onTap,
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
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(icon, size: 20.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.yellow),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 40.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonBackdrop extends StatelessWidget {
  const _LessonBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff020B18),
            Color(0xff072238),
            AppColors.primary,
            Color(0xff01344F),
            Color(0xff020B18),
          ],
          stops: [0.0, 0.22, 0.55, 0.8, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80.h,
            right: -40.w,
            child: _GlowBlob(color: AppColors.yellow, size: 220.w),
          ),
          Positioned(
            bottom: 120.h,
            left: -60.w,
            child: _GlowBlob(color: AppColors.sky, size: 200.w),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 120,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}
