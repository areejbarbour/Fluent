import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_cubit.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_state.dart';
import 'package:fluent/cubit/teacher/lessons/lesson_detail_cubit.dart';
import 'package:fluent/cubit/teacher/lessons/lesson_detail_state.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/models/word_model.dart';
import 'package:fluent/presentation/widgets/audio_preview_tile.dart';
import 'package:fluent/data/models/lesson_detail_model.dart';
import 'package:fluent/helper/lessons/lesson_helpers.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class LessonDetailScreen extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoError = false;
  bool _isPlaying = false;
  String? _currentVideoUrl;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isSendingComment = false;
  int? _busyCommentId;

  // ─── Expand / Collapse ───
  bool _wordsExpanded = false;
  bool _testsExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<LessonDetailCubit>().loadLessonDetails(widget.lessonId);
  }

  @override
  void dispose() {
    _disposeVideo();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    _videoController = null;
    _videoReady = false;
    _videoError = false;
    _isPlaying = false;
  }

  void _onVideoTick() {
    if (!mounted || _videoController == null) return;
    final playing = _videoController!.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    } else {
      setState(() {}); // progress bar
    }
  }

  Future<void> _initVideo(String? url) async {
    if (url == null || url.trim().isEmpty) {
      _disposeVideo();
      if (mounted) setState(() {});
      return;
    }
    if (_currentVideoUrl == url && _videoReady) return;

    _disposeVideo();
    _currentVideoUrl = url;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.addListener(_onVideoTick);
      setState(() {
        _videoReady = true;
        _videoError = false;
      });
    } catch (e) {
      print('_initVideo error: $e');
      if (mounted) {
        setState(() {
          _videoReady = false;
          _videoError = true;
        });
      }
    }
  }

  void _togglePlay() {
    final c = _videoController;
    if (c == null || !_videoReady) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  // ─── Status rules (حالة الدرس فقط) ───
  bool _canEditLesson(String status) {
    final s = status.toLowerCase();
    return !{'closed', 'archived', 'approved', 'in_review'}.contains(s);
  }

  bool _canDeleteLesson(String status) {
    final s = status.toLowerCase();
    return {'draft', 'pending', 'changes_requested'}.contains(s);
  }

  String _extractVideoUrl(dynamic lesson) {
    if (lesson is Map) {
      final v = lesson['video']?.toString();
      if (v != null && v.trim().isNotEmpty) return v;
    }
    if (lesson is LessonModel &&
        lesson.videoUrl != null &&
        lesson.videoUrl!.trim().isNotEmpty) {
      return lesson.videoUrl!;
    }
    return '';
  }

  String _lessonField(dynamic lesson, String key, [String fallback = '—']) {
    if (lesson is Map) {
      final v = lesson[key];
      if (v == null) return fallback;
      final s = v.toString().trim();
      return s.isEmpty ? fallback : s;
    }
    return fallback;
  }

  int _lessonInt(dynamic lesson, String key, [int fallback = 0]) {
    if (lesson is Map) {
      final v = lesson[key];
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }
    return fallback;
  }

  void _goEditLesson(BuildContext context, dynamic lesson) {
    final status = _lessonField(lesson, 'status', 'draft');
    final lessonModel = lesson is LessonModel
        ? lesson
        : LessonModel(
            id: _lessonInt(lesson, 'id', widget.lessonId),
            titleEn: _lessonField(lesson, 'title_en', ''),
            titleAr: _lessonField(lesson, 'title_ar', ''),
            courseId: lesson is Map && lesson['course'] is Map
                ? (lesson['course']['id'] is int
                      ? lesson['course']['id']
                      : int.tryParse('${lesson['course']['id']}') ?? 0)
                : _lessonInt(lesson, 'course_id'),
            status: status,
            order: _lessonInt(lesson, 'order', 1),
            xpPoints: _lessonInt(lesson, 'xp_points', 20),
            videoUrl: _extractVideoUrl(lesson).isEmpty
                ? null
                : _extractVideoUrl(lesson),
          );

    String? courseStatus;
    if (lesson is Map && lesson['course'] is Map) {
      courseStatus = lesson['course']['status']?.toString();
    }

    Navigator.pushNamed(
      context,
      lessonFormRoute,
      arguments: {'lesson': lessonModel, 'courseStatus': courseStatus},
    ).then((result) {
      if (result == true && context.mounted) {
        context.read<LessonDetailCubit>().loadLessonDetails(widget.lessonId);
      }
    });
  }

  void _confirmDeleteLesson(BuildContext context, dynamic lesson) {
    final id = _lessonInt(lesson, 'id', widget.lessonId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: Text(
          'Delete Lesson?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete the lesson with all its tests and details. This cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LessonDeleteCubit>().deleteLesson(id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LessonDeleteCubit, LessonDeleteState>(
          listener: (context, state) {
            if (state is LessonDeleteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.greenAccent,
                ),
              );
              Navigator.pop(context, true);
            }
            if (state is LessonDeleteFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  _buildTopBar(context),
                  Expanded(
                    child: BlocConsumer<LessonDetailCubit, LessonDetailState>(
                      listener: (context, state) {
                        if (state is LessonDetailLoaded) {
                          final url = _extractVideoUrl(state.lesson);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _initVideo(url.isEmpty ? null : url);
                          });
                        }
                      },
                      builder: (context, state) {
                        if (state is LessonDetailLoading ||
                            state is LessonDetailInitial) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.yellow,
                            ),
                          );
                        }

                        if (state is LessonDetailError) {
                          return _buildError(context, state.message);
                        }

                        if (state is LessonDetailLoaded) {
                          return RefreshIndicator(
                            color: AppColors.yellow,
                            onRefresh: () async {
                              await context
                                  .read<LessonDetailCubit>()
                                  .loadLessonDetails(widget.lessonId);
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLessonInfo(state.lesson),
                                  SizedBox(height: 16.h),
                                  _buildVideoSection(),

                                  SizedBox(height: 20.h),
                                  _buildWordsSection(context, state),
                                  SizedBox(height: 20.h),
                                  _buildTestsSection(context, state.tests),
                                  SizedBox(height: 20.h),
                                  _buildCommentsSection(context, state),
                                  SizedBox(height: 16.h),
                                  _buildActionButtons(context, state.lesson),
                                  SizedBox(height: 32.h),
                                ],
                              ),
                            ),
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
      ),
    );
  }

  // ─── Background ───
  Widget _buildBackground() => Stack(
    children: [
      Container(decoration: QuestionUI.backgroundGradient()),
      Positioned(
        top: -120.h,
        right: -100.w,
        child: QuestionUI.glowingCircle(AppColors.yellow, 320.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(-15, 10),
              duration: 5000.ms,
            ),
      ),
      Positioned(
        bottom: -160.h,
        left: -110.w,
        child: QuestionUI.glowingCircle(AppColors.sky, 380.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(20, -15),
              duration: 6000.ms,
            ),
      ),
    ],
  );

  // ─── Top bar ───
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _disposeVideo();
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
            ),
            child: const Icon(
              Icons.play_lesson_rounded,
              color: AppColors.yellow,
              size: 20,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              widget.lessonTitle,
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: AppColors.sky.withOpacity(0.7), blurRadius: 10),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ───
  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<LessonDetailCubit>()
                  .loadLessonDetails(widget.lessonId),
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

  // ─── Lesson info ───
  Widget _buildLessonInfo(dynamic lesson) {
    final titleEn = _lessonField(lesson, 'title_en');
    final titleAr = _lessonField(lesson, 'title_ar');
    final status = _lessonField(lesson, 'status', 'draft');
    final order = _lessonInt(lesson, 'order', 1);
    final xp = _lessonInt(lesson, 'xp_points', 20);
    final statusColor = StatusUI.statusColor(status);

    String? courseName;
    if (lesson is Map && lesson['course'] is Map) {
      courseName = lesson['course']['name']?.toString();
    }

    return QuestionUI.glass(
      padding: EdgeInsets.all(14.w),
      borderColor: statusColor.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (titleEn != '—')
                      Text(
                        titleEn,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (titleAr != '—') ...[
                      SizedBox(height: 4.h),
                      Text(
                        titleAr,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13.sp,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ],
                ),
              ),
              _statusBadge(status, statusColor),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              if (courseName != null && courseName.isNotEmpty)
                _miniChip(Icons.menu_book_outlined, courseName, AppColors.sky),
              _miniChip(
                Icons.low_priority_rounded,
                'Order $order',
                Colors.white70,
              ),
              _miniChip(Icons.star_rounded, '$xp XP', AppColors.yellow),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Video ───
  Widget _buildVideoSection() {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      borderColor: AppColors.sky.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videocam_rounded, color: AppColors.sky, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'Lesson Video',
                style: GoogleFonts.poppins(
                  color: AppColors.sky,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_videoError)
            _videoPlaceholder(
              icon: Icons.error_outline,
              text: 'Failed to load video',
              action: 'Retry',
              onAction: () {
                if (_currentVideoUrl != null) {
                  final url = _currentVideoUrl;
                  _currentVideoUrl = null;
                  _initVideo(url);
                }
              },
            )
          else if (_videoReady && _videoController != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio == 0
                    ? 16 / 9
                    : _videoController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController!),
                    // Play / Pause overlay
                    GestureDetector(
                      onTap: _togglePlay,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedOpacity(
                        opacity: _isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          color: Colors.black38,
                          child: Center(
                            child: Container(
                              width: 56.w,
                              height: 56.w,
                              decoration: BoxDecoration(
                                color: AppColors.yellow.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.dark,
                                size: 36.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Progress
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        _videoController!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: AppColors.yellow,
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white12,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 6.h,
                          horizontal: 8.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_currentVideoUrl != null && _currentVideoUrl!.isNotEmpty)
            _videoPlaceholder(
              icon: Icons.hourglass_top_rounded,
              text: 'Loading video...',
            )
          else
            _videoPlaceholder(
              icon: Icons.videocam_off_outlined,
              text: 'No video attached',
            ),
        ],
      ),
    );
  }

  Widget _videoPlaceholder({
    required IconData icon,
    required String text,
    String? action,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white38, size: 36.sp),
          SizedBox(height: 8.h),
          Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12.sp),
          ),
          if (action != null && onAction != null) ...[
            SizedBox(height: 10.h),
            TextButton(
              onPressed: onAction,
              child: Text(
                action,
                style: GoogleFonts.poppins(color: AppColors.yellow),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Action buttons (Edit / Delete حسب حالة الدرس) ───
  Widget _buildActionButtons(BuildContext context, dynamic lesson) {
    final status = _lessonField(lesson, 'status', 'draft');
    final canEdit = _canEditLesson(status);
    final canDelete = _canDeleteLesson(status);

    if (!canEdit && !canDelete) return const SizedBox.shrink();

    return Row(
      children: [
        if (canEdit)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _goEditLesson(context, lesson),
              icon: Icon(Icons.edit_rounded, size: 16.sp),
              label: Text(
                'Edit Lesson',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sky.withOpacity(0.2),
                foregroundColor: AppColors.sky,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        if (canEdit && canDelete) SizedBox(width: 10.w),
        if (canDelete)
          Expanded(
            child: BlocBuilder<LessonDeleteCubit, LessonDeleteState>(
              builder: (context, state) {
                final loading = state is LessonDeleteLoading;
                return ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () => _confirmDeleteLesson(context, lesson),
                  icon: loading
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                      : Icon(Icons.delete_outline, size: 16.sp),
                  label: Text(
                    'Delete',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                    foregroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ─── Words (Vocabulary) — display only; manage in Lesson Form ───
  Widget _buildWordsSection(BuildContext context, LessonDetailLoaded state) {
    final words = state.words;

    return QuestionUI.glass(
      padding: EdgeInsets.all(14.w),
      borderColor: AppColors.orange.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand arrow
          GestureDetector(
            onTap: () => setState(() => _wordsExpanded = !_wordsExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.translate_rounded,
                  color: AppColors.orange,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Words (${words.length})',
                    style: GoogleFonts.poppins(
                      color: AppColors.orange,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _wordsExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.orange,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),

          // Collapsible content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                if (words.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Center(
                      child: Text(
                        'No words for this lesson yet',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  )
                else
                  ...words.map(
                    (w) => Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34.w,
                            height: 34.w,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.abc,
                              color: AppColors.orange,
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.wordEn,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  w.wordAr,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                          if (w.hasAudio) ...[
                            SizedBox(width: 8.w),
                            AudioPreviewTile(url: w.audio!, compact: true),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            crossFadeState: _wordsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildTestsSection(BuildContext context, List<TestModel> tests) {
    return QuestionUI.glass(
      padding: EdgeInsets.all(14.w),
      borderColor: AppColors.sky.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand arrow
          GestureDetector(
            onTap: () => setState(() => _testsExpanded = !_testsExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.quiz_outlined, color: AppColors.sky, size: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Tests (${tests.length})',
                    style: GoogleFonts.poppins(
                      color: AppColors.sky,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _testsExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.sky,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
          // Collapsible content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                if (tests.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Center(
                      child: Text(
                        'No tests for this lesson',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  )
                else
                  ...tests.map((t) => _buildTestCard(context, t)),
              ],
            ),
            crossFadeState: _testsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, TestModel test) {
    final color = StatusUI.statusColor(test.status);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          testDetailViewRoute,
          arguments: {'testId': test.id},
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.titleEn.isNotEmpty ? test.titleEn : test.titleAr,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      _miniChip(
                        Icons.check_circle_outline,
                        'Pass ${test.passingScore}%',
                        AppColors.yellow,
                      ),
                      _miniChip(
                        Icons.info_outline,
                        test.status.toUpperCase(),
                        color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Comments (نفس منطق الطالب + واجهة المعلّم) ───
  Widget _buildCommentsSection(BuildContext context, LessonDetailLoaded state) {
    final comments = state.comments;
    return QuestionUI.glass(
      padding: EdgeInsets.all(14.w),
      borderColor: Colors.white.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.comment_outlined,
                color: AppColors.orange,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Comments (${comments.length})',
                style: GoogleFonts.poppins(
                  color: AppColors.orange,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (comments.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                'No comments yet',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
            )
          else
            ...comments.map((c) => _buildCommentTile(context, state, c)),
          if (state.hasMoreComments) ...[
            SizedBox(height: 8.h),
            Center(
              child: state.isLoadingMoreComments
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        color: AppColors.yellow,
                        strokeWidth: 2.5,
                      ),
                    )
                  : TextButton(
                      onPressed: () =>
                          context.read<LessonDetailCubit>().loadMoreComments(),
                      child: Text(
                        'Load more comments',
                        style: GoogleFonts.poppins(
                          color: AppColors.sky,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
            ),
          ],
          // Composer — فقط إذا الدرس published (منطق الباك)
          if (state.canCreateComment) ...[
            SizedBox(height: 14.h),
            _buildCommentComposer(context, state),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentTile(
    BuildContext context,
    LessonDetailLoaded state,
    LessonCommentModel c,
  ) {
    final name = c.isOwn
        ? (c.user != null && c.user!.fullName.isNotEmpty
              ? c.user!.fullName
              : 'You')
        : (c.user != null && c.user!.fullName.isNotEmpty
              ? c.user!.fullName
              : 'Anonymous');
    final isBusy = _busyCommentId == c.id || state.isBusyComment;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: c.isOwn
            ? AppColors.yellow.withOpacity(0.08)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: c.isOwn
              ? AppColors.yellow.withOpacity(0.35)
              : Colors.white.withOpacity(0.08),
        ),
      ),
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
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (c.isOwn)
                PopupMenuButton<String>(
                  enabled: !isBusy,
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white54,
                    size: 18.sp,
                  ),
                  color: AppColors.dark,
                  onSelected: (v) {
                    if (v == 'edit' && state.canUpdateComments) {
                      _openEditCommentDialog(context, c);
                    } else if (v == 'delete') {
                      _confirmDeleteComment(context, c);
                    }
                  },
                  itemBuilder: (_) => [
                    if (state.canUpdateComments)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            c.comment,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12.sp),
          ),
          if (c.createdAt != null && c.createdAt!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              c.createdAt!,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentComposer(BuildContext context, LessonDetailLoaded state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _commentCtrl,
            maxLines: 3,
            minLines: 1,
            maxLength: LessonDetailCubit.maxCommentLength,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.sp),
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 12.sp,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.sky.withOpacity(0.5)),
              ),
              counterStyle: GoogleFonts.poppins(
                color: Colors.white30,
                fontSize: 9.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: (_isSendingComment || state.isBusyComment)
              ? null
              : () => _submitComment(context),
          child: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.yellow, AppColors.orange],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: (_isSendingComment || state.isBusyComment)
                ? Padding(
                    padding: EdgeInsets.all(12.w),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.dark,
                    ),
                  )
                : Icon(Icons.send_rounded, color: AppColors.dark, size: 20.sp),
          ),
        ),
      ],
    );
  }

  Future<void> _submitComment(BuildContext context) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    if (text.length > LessonDetailCubit.maxCommentLength) {
      _showCommentSnack(
        context,
        'Comment must not exceed ${LessonDetailCubit.maxCommentLength} characters',
        Colors.redAccent,
      );
      return;
    }
    setState(() => _isSendingComment = true);
    final err = await context.read<LessonDetailCubit>().submitComment(
      widget.lessonId,
      text,
    );
    if (!mounted) return;
    setState(() => _isSendingComment = false);
    if (err == null) {
      _commentCtrl.clear();
    } else {
      _showCommentSnack(context, err, Colors.redAccent);
    }
  }

  void _openEditCommentDialog(
    BuildContext context,
    LessonCommentModel comment,
  ) {
    final ctrl = TextEditingController(text: comment.comment);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.dark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Edit Comment',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: ctrl,
            maxLines: 4,
            maxLength: LessonDetailCubit.maxCommentLength,
            autofocus: true,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              counterStyle: GoogleFonts.poppins(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newText = ctrl.text.trim();
                if (newText.isEmpty ||
                    newText == comment.comment ||
                    newText.length > LessonDetailCubit.maxCommentLength) {
                  Navigator.pop(dialogContext);
                  return;
                }
                Navigator.pop(dialogContext);
                setState(() => _busyCommentId = comment.id);
                final err = await context.read<LessonDetailCubit>().editComment(
                  comment.id,
                  newText,
                );
                if (!mounted) return;
                setState(() => _busyCommentId = null);
                if (err != null) {
                  _showCommentSnack(context, err, Colors.redAccent);
                }
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

  void _confirmDeleteComment(BuildContext context, LessonCommentModel comment) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.dark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Delete comment?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This action cannot be undone.',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                setState(() => _busyCommentId = comment.id);
                final err = await context
                    .read<LessonDetailCubit>()
                    .removeComment(comment.id);
                if (!mounted) return;
                setState(() => _busyCommentId = null);
                if (err != null) {
                  _showCommentSnack(context, err, Colors.redAccent);
                }
              },
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
    );
  }

  void _showCommentSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Helpers ───
  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
