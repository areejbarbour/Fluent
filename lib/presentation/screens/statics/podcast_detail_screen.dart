
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/podcasts/podcast_detail_cubit.dart';
import 'package:fluent/cubit/student/podcasts/podcast_detail_state.dart';
import 'package:fluent/data/models/podcast_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = d.inHours;
  return hours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
}

class PodcastDetailScreen extends StatefulWidget {
  final int podcastId;
  final String podcastTitle;

  const PodcastDetailScreen({
    super.key,
    required this.podcastId,
    this.podcastTitle = '',
  });

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          _buildBackground(),
          const _TwinklingStars(count: 32),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: _buildTopBar(),
                ),
                Expanded(
                  child: BlocBuilder<PodcastDetailCubit, PodcastDetailState>(
                    builder: (context, state) {
                      if (state is PodcastDetailLoading ||
                          state is PodcastDetailInitial) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.yellow,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                "Loading podcast...",
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(.65),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is PodcastDetailFailure) {
                        return _errorCard(state.message);
                      }

                      if (state is PodcastDetailSuccess) {
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
          top: -120.h,
          right: -80.w,
          child: _glowCircle(AppColors.yellow, 300.w, 160, 40)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-15, 10),
                duration: 5500.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          top: 420.h,
          left: -100.w,
          child: _glowCircle(AppColors.sky, 260.w, 150, 30)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(20, 15),
                duration: 6500.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          top: 850.h,
          right: -60.w,
          child: _glowCircle(const Color(0xffB861F5), 220.w, 140, 25)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-10, -8),
                duration: 7000.ms,
                curve: Curves.easeInOut,
              ),
        ),
      ],
    );
  }

  Widget _glowCircle(Color color, double size, double blur, double spread) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.30),
            blurRadius: blur,
            spreadRadius: spread,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(.14),
                  Colors.white.withOpacity(.06),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(.25)),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Podcast",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 44.w),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _errorCard(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(.10),
                    Colors.white.withOpacity(.04),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(.14)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      color: Colors.white54, size: 40.sp),
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
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context
                          .read<PodcastDetailCubit>()
                          .fetchDetails(widget.podcastId);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 22.w, vertical: 11.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.orange, AppColors.yellow],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.yellow.withOpacity(.4),
                            blurRadius: 14,
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
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PodcastDetailModel data) {
  final title =
      data.name.isNotEmpty ? data.name : widget.podcastTitle;

  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 28.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.yellow.withOpacity(.14),
                    Colors.white.withOpacity(.05),
                    AppColors.sky.withOpacity(.08),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(.16)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(.12),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: const LinearGradient(
                            colors: [AppColors.orange, AppColors.yellow],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellow.withOpacity(.45),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.podcasts_rounded,
                          color: Colors.black,
                          size: 24.sp,
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
                                fontWeight: FontWeight.w800,
                                fontSize: 16.sp,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.yellow.withOpacity(.14),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: AppColors.yellow.withOpacity(.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.diamond_rounded,
                                    color: AppColors.yellow,
                                    size: 13.sp,
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    "${data.pointRequired} pts",
                                    style: GoogleFonts.poppins(
                                      color: AppColors.yellow,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.sp,
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
                  SizedBox(height: 16.h),
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(.08),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        color: Colors.white.withOpacity(.45),
                        size: 15.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "Listen & improve your English",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 420.ms)
            .moveY(begin: 10, end: 0),

        SizedBox(height: 18.h),

        // ─── الفيديو تحت ───
        if (data.hasVideo)
          _PodcastVideoPlayer(videoUrl: data.videoUrl!)
              .animate()
              .fadeIn(delay: 100.ms, duration: 450.ms)
              .moveY(begin: 14, end: 0)
        else
          _noVideoPlaceholder(),
      ],
    ),
  );
}

  Widget _noVideoPlaceholder() {
    return Container(
      height: 210.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(.08),
            Colors.white.withOpacity(.03),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded,
              color: Colors.white38, size: 42.sp),
          SizedBox(height: 10.h),
          Text(
            "No video available",
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Video Player (أسلوب واجهة الدروس)
// ─────────────────────────────────────────────

class _PodcastVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _PodcastVideoPlayer({required this.videoUrl});

  @override
  State<_PodcastVideoPlayer> createState() => _PodcastVideoPlayerState();
}

class _PodcastVideoPlayerState extends State<_PodcastVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isMuted = false;
  bool _isSeeking = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      _controller.setLooping(false);
      _controller.addListener(() {
        if (mounted && !_isSeeking) setState(() {});
      });
      if (mounted) {
        setState(() => _initialized = true);
        _scheduleHideControls();
      }
    } catch (e) {
      debugPrint("Video error: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _togglePlayPause() {
    HapticFeedback.selectionClick();
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _showControls = true);
    } else {
      _controller.play();
      _scheduleHideControls();
    }
    setState(() {});
  }

  void _toggleMute() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
    _scheduleHideControls();
  }

  Future<void> _openFullscreen() async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenPodcastPlayer(
          controller: _controller,
          isMuted: _isMuted,
          onMuteChanged: (v) {
            setState(() {
              _isMuted = v;
              _controller.setVolume(v ? 0 : 1);
            });
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 220.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          color: Colors.white.withOpacity(.06),
          border: Border.all(color: Colors.white.withOpacity(.12)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 34.sp),
              SizedBox(height: 8.h),
              Text(
                "Failed to load video",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        height: 220.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          color: Colors.black.withOpacity(.4),
          border: Border.all(color: Colors.white.withOpacity(.12)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.yellow),
        ),
      );
    }

    final value = _controller.value;
    final position = value.position;
    final duration = value.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return GestureDetector(
      onTap: _toggleControls,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: AspectRatio(
          aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),

              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(.5),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(.7),
                        ],
                        stops: const [0, 0.22, 0.55, 1],
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: Row(
                          children: [
                            _circleControl(
                              icon: _isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              onTap: _toggleMute,
                            ),
                            SizedBox(width: 8.w),
                            _circleControl(
                              icon: Icons.fullscreen_rounded,
                              onTap: _openFullscreen,
                            ),
                          ],
                        ),
                      ),

                      Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.orange, AppColors.yellow],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.yellow.withOpacity(.55),
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
                              size: 34.sp,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
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
                                    overlayShape: RoundSliderOverlayShape(
                                      overlayRadius: 12.r,
                                    ),
                                    activeTrackColor: AppColors.yellow,
                                    inactiveTrackColor:
                                        Colors.white.withOpacity(.25),
                                    thumbColor: AppColors.yellow,
                                    overlayColor:
                                        AppColors.yellow.withOpacity(.25),
                                  ),
                                  child: Slider(
                                    value: progress.clamp(0.0, 1.0),
                                    onChanged: (v) {
                                      final newPos = Duration(
                                        milliseconds:
                                            (duration.inMilliseconds * v)
                                                .round(),
                                      );
                                      _controller.seekTo(newPos);
                                    },
                                    onChangeStart: (_) =>
                                        setState(() => _isSeeking = true),
                                    onChangeEnd: (_) {
                                      setState(() => _isSeeking = false);
                                      _scheduleHideControls();
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleControl({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(.45),
          border: Border.all(color: Colors.white.withOpacity(.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 16.sp),
      ),
    );
  }
}

class _FullscreenPodcastPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;

  const _FullscreenPodcastPlayer({
    required this.controller,
    required this.isMuted,
    required this.onMuteChanged,
  });

  @override
  State<_FullscreenPodcastPlayer> createState() =>
      _FullscreenPodcastPlayerState();
}

class _FullscreenPodcastPlayerState extends State<_FullscreenPodcastPlayer> {
  late bool _isMuted = widget.isMuted;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    widget.controller.addListener(_onTick);
    _scheduleHide();
  }

  void _onTick() {
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

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onTick);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final position = value.position;
    final duration = value.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) _scheduleHide();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio:
                    value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            if (_showControls) ...[
              // play
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (value.isPlaying) {
                    widget.controller.pause();
                  } else {
                    widget.controller.play();
                    _scheduleHide();
                  }
                  setState(() {});
                },
                child: Container(
                  width: 68.w,
                  height: 68.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.yellow],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withOpacity(.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 36.sp,
                  ),
                ),
              ),
              // close
              Positioned(
                top: 24.h,
                left: 20.w,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(.5),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white, size: 20.sp),
                  ),
                ),
              ),
              // bottom bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 18.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22.w),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.5,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            activeTrackColor: AppColors.yellow,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: AppColors.yellow,
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (v) {
                              widget.controller.seekTo(
                                Duration(
                                  milliseconds:
                                      (duration.inMilliseconds * v).round(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: () {
                          setState(() => _isMuted = !_isMuted);
                          widget.controller.setVolume(_isMuted ? 0 : 1);
                          widget.onMuteChanged(_isMuted);
                        },
                        child: Icon(
                          _isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                    ],
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

class _TwinklingStars extends StatelessWidget {
  final int count;
  const _TwinklingStars({this.count = 32});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(11);
    return IgnorePointer(
      child: Stack(
        children: List.generate(count, (i) {
          final left = rng.nextDouble();
          final top = rng.nextDouble();
          final size = rng.nextDouble() * 2 + 1;
          final delay = rng.nextInt(3000);
          final duration = 1500 + rng.nextInt(2500);
          final maxOpacity = rng.nextDouble() * 0.55 + 0.25;

          return Positioned(
            left: left * 1.sw,
            top: top * 1.sh,
            child: Container(
              width: size.w,
              height: size.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
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