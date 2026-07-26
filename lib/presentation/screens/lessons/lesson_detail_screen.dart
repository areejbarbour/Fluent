import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'package:fluent/cubit/student/lessons/lesson_detail_cubit.dart';
import 'package:fluent/cubit/student/lessons/lesson_detail_state.dart';
import 'package:fluent/data/models/lesson_detail_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final int? lessonId;
  final String lessonTitle;

  const LessonDetailScreen({
    super.key,
    this.lessonId,
    this.lessonTitle = '',
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<LessonDetailCubit>();
      if (cubit.state is LessonDetailInitial) {
        cubit.fetchLessonDetail(widget.lessonId ?? 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          _buildBackground(),
          _TwinklingStars(count: 35),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: _buildTopBar(),
                ),
                Expanded(
                  child: BlocBuilder<LessonDetailCubit, LessonDetailState>(
                    builder: (context, state) {
                      if (state is LessonDetailLoading ||
                          state is LessonDetailInitial) {
                        return _loadingCard();
                      }

                      if (state is LessonDetailFailure) {
                        return _errorCard(state.message);
                      }

                      if (state is LessonDetailSuccess) {
                        return _buildContent(state.data);
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

  Widget _loadingCard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.yellow),
          SizedBox(height: 12.h),
          Text(
            "Loading lesson...",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.7),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(.10),
                    Colors.white.withOpacity(.04),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      color: Colors.white.withOpacity(.7), size: 30.sp),
                  SizedBox(height: 10.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.85),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: () => context
                        .read<LessonDetailCubit>()
                        .fetchLessonDetail(widget.lessonId ?? 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 18.w, vertical: 9.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.orange, AppColors.yellow],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        "Retry",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.sp,
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

  Widget _buildContent(LessonDetailModel data) {
    final lesson = data.lesson;
    final comments = data.comments;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        SizedBox(height: 4.h),
        if (lesson != null && lesson.video.isNotEmpty)
          _LuxuryVideoPlayer(videoUrl: lesson.video)
        else
          _noVideoCard(),
        SizedBox(height: 16.h),
        if (lesson != null) _buildLessonInfoCard(lesson),
        SizedBox(height: 22.h),
        _buildCommentsHeader(comments.length),
        SizedBox(height: 12.h),
        if (comments.isEmpty)
          _emptyCommentsCard()
        else
          ...comments.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _CommentCard(
                    comment: entry.value,
                    index: entry.key,
                  ),
                ),
              ),
        SizedBox(height: 40.h),
      ],
    );
  }

  Widget _noVideoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(.08),
                Colors.white.withOpacity(.03),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.12)),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.videocam_off_rounded,
              color: Colors.white.withOpacity(.4), size: 34.sp),
        ),
      ),
    );
  }

  Widget _buildLessonInfoCard(LessonVideoModel lesson) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.10),
                Colors.white.withOpacity(.04),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.yellow],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.black, size: 13.sp),
                    SizedBox(width: 3.w),
                    Text(
                      "${lesson.xpPoints} XP",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).moveY(begin: 8, end: 0);
  }

  Widget _buildCommentsHeader(int count) {
    return Row(
      children: [
        Icon(Icons.forum_rounded, color: AppColors.sky, size: 17.sp),
        SizedBox(width: 8.w),
        Text(
          "Comments",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(.14)),
          ),
          child: Text(
            "$count",
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyCommentsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 26.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: Colors.white.withOpacity(.05),
            border: Border.all(color: Colors.white.withOpacity(.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white.withOpacity(.35), size: 26.sp),
              SizedBox(height: 8.h),
              Text(
                "No comments yet",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(.55),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "LESSON",
                style: GoogleFonts.poppins(
                  color: AppColors.sky.withOpacity(.85),
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                widget.lessonTitle.isNotEmpty ? widget.lessonTitle : "Lesson",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).moveY(begin: -10, end: 0);
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
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white.withOpacity(.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
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
                AppColors.dark,
              ],
              stops: [0.0, 0.3, 0.65, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -120.h,
          right: -80.w,
          child: _glowCircle(AppColors.yellow, 280.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-15, 10),
                duration: 5500.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          bottom: -140.h,
          left: -90.w,
          child: _glowCircle(AppColors.sky, 300.w)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(15, -10),
                duration: 6500.ms,
                curve: Curves.easeInOut,
              ),
        ),
      ],
    );
  }

  Widget _glowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 140,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}

class _LuxuryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _LuxuryVideoPlayer({required this.videoUrl});

  @override
  State<_LuxuryVideoPlayer> createState() => _LuxuryVideoPlayerState();
}

class _LuxuryVideoPlayerState extends State<_LuxuryVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isMuted = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await controller.initialize();
      controller.addListener(_onControllerUpdate);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    HapticFeedback.lightImpact();
    if (controller.value.isPlaying) {
      controller.pause();
      _cancelHideTimer();
      setState(() => _showControls = true);
    } else {
      controller.play();
      _scheduleHideControls();
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _scheduleHideControls() {
    _cancelHideTimer();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _onTapVideo() {
    setState(() => _showControls = !_showControls);
    if (_showControls && (_controller?.value.isPlaying ?? false)) {
      _scheduleHideControls();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0
        ? "$hours:$minutes:$seconds"
        : "$minutes:$seconds";
  }

  @override
  void dispose() {
    _cancelHideTimer();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(.14)),
          boxShadow: [
            BoxShadow(
              color: AppColors.sky.withOpacity(.18),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio:
              _isInitialized ? _controller!.value.aspectRatio : 16 / 9,
          child: _hasError
              ? _buildErrorPlaceholder()
              : !_isInitialized
                  ? _buildLoadingPlaceholder()
                  : GestureDetector(
                      onTap: _onTapVideo,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayer(_controller!),
                          AnimatedOpacity(
                            opacity: _showControls ? 1 : 0,
                            duration: 220.ms,
                            child: IgnorePointer(
                              ignoring: !_showControls,
                              child: _buildControlsOverlay(),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(.97, .97),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black.withOpacity(.35),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.yellow),
          SizedBox(height: 10.h),
          Text(
            "Loading video...",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.7),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.black.withOpacity(.35),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.white.withOpacity(.6), size: 30.sp),
          SizedBox(height: 8.h),
          Text(
            "Couldn't load the video",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.75),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final controller = _controller!;
    final value = controller.value;
    final position = value.position;
    final duration = value.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(.35),
            Colors.transparent,
            Colors.black.withOpacity(.55),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(.35),
                    ),
                    child: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.yellow],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(.6),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 32.sp,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Text(
                  _formatDuration(position),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5.h,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 6.r,
                      ),
                      overlayShape:
                          RoundSliderOverlayShape(overlayRadius: 12.r),
                      activeTrackColor: AppColors.yellow,
                      inactiveTrackColor: Colors.white.withOpacity(.25),
                      thumbColor: AppColors.yellow,
                      overlayColor: AppColors.yellow.withOpacity(.25),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (v) {
                        final newPosition = Duration(
                          milliseconds:
                              (duration.inMilliseconds * v).round(),
                        );
                        controller.seekTo(newPosition);
                      },
                      onChangeStart: (_) => _cancelHideTimer(),
                      onChangeEnd: (_) {
                        if (value.isPlaying) _scheduleHideControls();
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDuration(duration),
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

class _CommentCard extends StatelessWidget {
  final LessonCommentModel comment;
  final int index;

  const _CommentCard({required this.comment, required this.index});

  static const List<Color> _avatarColors = [
    AppColors.sky,
    AppColors.orange,
    Color(0xFF4ADE80),
    AppColors.yellow,
    Color(0xFFB388FF),
    Color(0xFFFF6FB5),
  ];

  Color _colorForUser(int userId) =>
      _avatarColors[userId % _avatarColors.length];

  String _timeAgo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return "";
    final date = DateTime.tryParse(isoDate);
    if (date == null) return "";
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${(diff.inDays / 7).floor()}w ago";
  }

  @override
  Widget build(BuildContext context) {
    final user = comment.user;
    final name = user != null && user.fullName.isNotEmpty
        ? user.fullName
        : "Fluent User";
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final color = _colorForUser(user?.id ?? comment.id);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(.08),
                Colors.white.withOpacity(.03),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      LinearGradient(colors: [color, color.withOpacity(.6)]),
                  border:
                      Border.all(color: Colors.white.withOpacity(.4), width: 1),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(.5), blurRadius: 8),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                    ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _timeAgo(comment.createdAt),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.45),
                            fontSize: 9.5.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      comment.comment,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 11.5.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (100 + index * 60).ms, duration: 350.ms)
        .moveX(begin: 10, end: 0, curve: Curves.easeOutCubic);
  }
}

class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 35});

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