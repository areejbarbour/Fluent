// 📁 lib/presentation/screens/chat/chat_entry_screen.dart
// Premium entry — cosmic Fluent design language (v2, elevated)

import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/chat/chat_cubit.dart';
import 'package:fluent/cubit/student/chat/chat_state.dart';
import 'package:fluent/data/models/chat_models.dart';
import 'package:fluent/presentation/screens/chat/chat_session_screen.dart';
import 'package:fluent/presentation/screens/chat/chat_history_screen.dart';
import 'package:fluent/presentation/screens/chat/chat_summary_screen.dart';
import 'package:fluent/presentation/widgets/app_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatEntryScreen extends StatelessWidget {
  const ChatEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is ChatSessionActive) return const ChatSessionScreen();
        if (state is ChatSessionEnded) {
          return ChatSummaryScreen(
            session: state.session,
            summary: state.summary,
          );
        }
        if (state is ChatHistoryLoading ||
            state is ChatHistoryLoaded ||
            state is ChatHistoryDetailLoading ||
            state is ChatHistoryDetailLoaded) {
          return const ChatHistoryScreen();
        }

        return _ChatHubScaffold(state: state);
      },
    );
  }
}

class _ChatHubScaffold extends StatelessWidget {
  final ChatState state;
  const _ChatHubScaffold({required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading =
        state is ChatBootstrapLoading || state is ChatCreatingSession;
    final noActive = state is ChatNoActiveSession
        ? state as ChatNoActiveSession
        : null;
    final failure = state is ChatFailure ? state as ChatFailure : null;

    return Scaffold(
      backgroundColor: const Color(0xff03060F),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Base cosmic backdrop
          const AppBackdrop(starCount: 34, seed: 11),

          // Soft ambient glow blobs for depth
          Positioned(
            top: -90.h,
            right: -70.w,
            child: _AmbientGlow(
              color: AppColors.yellow,
              size: 260.w,
              opacity: 0.16,
            ),
          ),
          Positioned(
            bottom: -60.h,
            left: -90.w,
            child: _AmbientGlow(
              color: AppColors.sky,
              size: 300.w,
              opacity: 0.14,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _HubAppBar(
                  onHistory: () {
                    HapticFeedback.selectionClick();
                    context.read<ChatCubit>().loadHistory();
                  },
                ),
                Expanded(
                  child: isLoading
                      ? const _HubLoading()
                      : failure != null
                      ? _HubError(
                          message: failure.message,
                          onRetry: () => context.read<ChatCubit>().bootstrap(),
                        )
                      : _HubContent(noActive: noActive),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft, blurred radial glow used to add atmospheric depth behind content.
class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _AmbientGlow({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

class _HubAppBar extends StatelessWidget {
  final VoidCallback onHistory;
  const _HubAppBar({required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 14.w, 6.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.r),
              color: Colors.white.withOpacity(0.045),
              border: Border.all(color: Colors.white.withOpacity(0.09)),
            ),
            child: Row(
              children: [
                _GlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                  iconColor: Colors.white.withOpacity(0.92),
                  size: 17.sp,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Colors.white, AppColors.yellow],
                            ).createShader(bounds),
                            child: Text(
                              'EnglishCoach',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18.sp,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xff4ADE80),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xff4ADE80,
                                      ).withOpacity(0.7),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fadeIn(duration: 900.ms)
                              .then()
                              .fadeOut(duration: 900.ms),
                        ],
                      ),
                      Text(
                        'AI conversation partner',
                        style: GoogleFonts.poppins(
                          color: AppColors.sky.withOpacity(0.85),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _GlassIconButton(icon: Icons.history_rounded, onTap: onHistory),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubLoading extends StatelessWidget {
  const _HubLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 56.w,
                height: 56.w,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.yellow.withOpacity(0.18),
                      AppColors.sky.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.yellow,
                  backgroundColor: Colors.white.withOpacity(0.08),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 1400.ms,
                curve: Curves.easeInOut,
              ),
          SizedBox(height: 16.h),
          Text(
            'Preparing your coach…',
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _HubError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: _GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withOpacity(0.12),
                  border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.orange,
                  size: 30.sp,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Something went off track',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 12.5.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 18.h),
              _PrimaryPill(label: 'Try again', onTap: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubContent extends StatelessWidget {
  final ChatNoActiveSession? noActive;
  const _HubContent({this.noActive});

  @override
  Widget build(BuildContext context) {
    final topics = noActive?.topics ?? [];
    final topicsLoading = noActive?.topicsLoading ?? false;
    final topicsError = noActive?.topicsError;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CoachHero()
              .animate()
              .fadeIn(duration: 450.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          SizedBox(height: 26.h),
          const _SectionLabel(text: 'START CHATTING'),
          SizedBox(height: 10.h),
          _FreeTalkCard(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.read<ChatCubit>().startSession(mode: 'free_talk');
                },
              )
              .animate()
              .fadeIn(delay: 80.ms, duration: 450.ms)
              .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
          SizedBox(height: 30.h),
          Row(
            children: [
              const _SectionLabel(text: 'GUIDED TOPICS'),
              const Spacer(),
              if (topicsLoading)
                SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.yellow.withOpacity(0.7),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          if (topicsError != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  color: Colors.redAccent.withOpacity(0.08),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent.shade100,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        topicsError,
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent.shade100,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.read<ChatCubit>().loadTopics(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.poppins(
                          color: AppColors.yellow,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!topicsLoading && topics.isEmpty && topicsError == null)
            _GlassCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.explore_off_rounded,
                      color: Colors.white38,
                      size: 26.sp,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'No topics for your level yet — try Free Talk!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...topics.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child:
                  _TopicTile(
                        topic: t,
                        index: i,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.read<ChatCubit>().startSession(
                            mode: 'topics',
                            topicId: t.id,
                          );
                        },
                      )
                      .animate()
                      .fadeIn(delay: (120 + i * 55).ms, duration: 380.ms)
                      .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
            );
          }),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14.w,
          height: 2.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.r),
            gradient: const LinearGradient(
              colors: [AppColors.yellow, AppColors.orange],
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white38,
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _CoachHero extends StatelessWidget {
  const _CoachHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.6),
                const Color(0xff0A2740).withOpacity(0.92),
                const Color(0xff03060F).withOpacity(0.96),
              ],
            ),
            border: Border.all(color: AppColors.yellow.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withOpacity(0.1),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.yellow, AppColors.orange],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellow.withOpacity(0.45),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(2.5.w),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff0A2740),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.yellow,
                            size: 28.sp,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 2200.ms,
                        curve: Curves.easeInOut,
                      ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice English live',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Instant corrections · Natural replies',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 11.5.sp,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _HeroStatChip(
                      icon: Icons.bolt_rounded,
                      label: 'Instant feedback',
                      color: AppColors.yellow,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _HeroStatChip(
                      icon: Icons.emoji_events_rounded,
                      label: 'Earn XP',
                      color: AppColors.sky,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeroStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 13.sp),
          SizedBox(width: 5.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeTalkCard extends StatefulWidget {
  final VoidCallback onTap;
  const _FreeTalkCard({required this.onTap});

  @override
  State<_FreeTalkCard> createState() => _FreeTalkCardState();
}

class _FreeTalkCardState extends State<_FreeTalkCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: 120.ms,
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xffFFC94D), AppColors.yellow, AppColors.orange],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Stack(
              children: [
                // Diagonal sheen accent
                Positioned(
                  right: -30.w,
                  top: -30.h,
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 18.h,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Icon(
                          Icons.forum_rounded,
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
                              'Free Talk',
                              style: GoogleFonts.poppins(
                                color: AppColors.dark,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Chat about anything — no topic needed',
                              style: GoogleFonts.poppins(
                                color: AppColors.dark.withOpacity(0.72),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.14),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.dark,
                          size: 18.sp,
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
    );
  }
}

class _TopicTile extends StatefulWidget {
  final ChatTopicModel topic;
  final int index;
  final VoidCallback onTap;

  const _TopicTile({
    required this.topic,
    required this.index,
    required this.onTap,
  });

  static const IconData _icon = Icons.chat_bubble_outline_rounded;
  static const Color _accent = AppColors.sky;

  @override
  State<_TopicTile> createState() => _TopicTileState();
}

class _TopicTileState extends State<_TopicTile> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    const icon = _TopicTile._icon;
    const accent = _TopicTile._accent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.985),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: 110.ms,
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13.r),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withOpacity(0.28),
                          accent.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(color: accent.withOpacity(0.28)),
                    ),
                    child: Icon(icon, color: accent, size: 21.sp),
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.topic.title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Guided conversation',
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                      size: 18.sp,
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
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: Colors.white.withOpacity(0.055),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final double? size;
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.yellow,
            size: size ?? 20.sp,
          ),
        ),
      ),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 11.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: const LinearGradient(
              colors: [AppColors.orange, AppColors.yellow],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.dark,
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
            ),
          ),
        ),
      ),
    );
  }
}
