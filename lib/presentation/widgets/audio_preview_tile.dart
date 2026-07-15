import 'package:audioplayers/audioplayers.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Simple word-audio player: just a play button + status.
/// No seek bar / duration — designed for short single-word clips.
class AudioPreviewTile extends StatefulWidget {
  final String url;
  final String? label;
  final bool compact; // true = small icon-only version (used in form tile)

  const AudioPreviewTile({
    super.key,
    required this.url,
    this.label,
    this.compact = false,
  });

  @override
  State<AudioPreviewTile> createState() => _AudioPreviewTileState();
}

class _AudioPreviewTileState extends State<AudioPreviewTile> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _state = PlayerState.stopped);
    });
  }

  @override
  void didUpdateWidget(covariant AudioPreviewTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _player.stop();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_state == PlayerState.playing) {
      await _player.stop();
      return;
    }
    setState(() => _loading = true);
    try {
      await _player.stop();
      await _player.play(UrlSource(widget.url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
          ), // 👈 بدل 'تعذّر تشغيل الصوت: $e'
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _state == PlayerState.playing;
    final size = widget.compact ? 34.w : 52.w;
    final iconSize = widget.compact ? 16.sp : 24.sp;

    final button =
        GestureDetector(
              onTap: _loading ? null : _play,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(isPlaying ? 0.35 : 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.orange.withOpacity(isPlaying ? 0.9 : 0.5),
                    width: isPlaying ? 2 : 1,
                  ),
                ),
                child: _loading
                    ? Padding(
                        padding: EdgeInsets.all(size * 0.28),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.orange,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.orange,
                        size: iconSize,
                      ),
              ),
            )
            .animate(target: isPlaying ? 1 : 0)
            .scaleXY(
              begin: 1,
              end: 1.08,
              duration: 400.ms,
              curve: Curves.easeInOut,
            );

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          SizedBox(width: 8.w),
          Text(
            isPlaying ? "Playing..." : "Listen",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.75),
              fontSize: 10.sp,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        button,
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label ?? "Audio",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(
                    isPlaying
                        ? Icons.graphic_eq_rounded
                        : Icons.volume_up_rounded,
                    color: AppColors.orange.withOpacity(0.8),
                    size: 12.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    isPlaying ? "Playing word..." : "Tap to listen",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
