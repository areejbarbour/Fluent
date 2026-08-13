// 📁 lib/presentation/screens/chat/chat_session_screen.dart
// Live AI chat — ChatGPT-like UX in Fluent cosmic language

import 'dart:ui';
import 'dart:ui' as ui;

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/chat/chat_cubit.dart';
import 'package:fluent/cubit/student/chat/chat_state.dart';
import 'package:fluent/data/models/chat_models.dart';
import 'package:fluent/presentation/widgets/app_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatSessionScreen extends StatefulWidget {
  const ChatSessionScreen({super.key});

  @override
  State<ChatSessionScreen> createState() => _ChatSessionScreenState();
}

class _ChatSessionScreenState extends State<ChatSessionScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _confirmEnd(BuildContext context) async {
    HapticFeedback.lightImpact();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EndSheet(
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ChatCubit>().endSession();
    }
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    _controller.clear();
    context.read<ChatCubit>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is ChatSessionActive) _scrollToBottom();
      },
      builder: (context, state) {
        if (state is! ChatSessionActive) {
          return const Scaffold(
            backgroundColor: Color(0xff071A2B),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.yellow),
            ),
          );
        }

        final session = state.session;
        final title = session.isTopics
            ? (session.topic?.title ?? 'Topic Chat')
            : 'Free Talk';

        return Scaffold(
          backgroundColor: const Color(0xff071A2B),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Soft vertical gradient — brighter & more inviting
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xff0B2A45),
                        const Color(0xff071A2B),
                        const Color(0xff0A2238),
                      ],
                    ),
                  ),
                ),
              ),
              const AppBackdrop(starCount: 14, seed: 3),
              // soft bottom fade for input
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 140.h,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xff071A2B).withOpacity(0),
                          const Color(0xff071A2B).withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _SessionAppBar(
                      title: title,
                      subtitle: session.isActive
                          ? 'Live · EnglishCoach'
                          : 'Ended',
                      isEnding: state.isEnding,
                      onEnd: () => _confirmEnd(context),
                    ),
                    Expanded(
                      child: session.messages.isEmpty
                          ? _EmptyChatHint(
                              isTopics: session.isTopics,
                              topic: session.topic?.title,
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                14.w,
                                8.h,
                                14.w,
                                16.h,
                              ),
                              itemCount:
                                  session.messages.length +
                                  (state.isSending ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (state.isSending &&
                                    index == session.messages.length) {
                                  return const _TypingBubble();
                                }
                                final msg = session.messages[index];
                                return _MessageBubble(
                                  message: msg,
                                  index: index,
                                );
                              },
                            ),
                    ),
                    if (state.sendError != null)
                      _ErrorBanner(text: state.sendError!),
                    _Composer(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled:
                          session.isActive &&
                          !state.isSending &&
                          !state.isEnding,
                      isSending: state.isSending,
                      onSend: _send,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── App bar ──────────────────────────────────────────────────

class _SessionAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isEnding;
  final VoidCallback onEnd;

  const _SessionAppBar({
    required this.title,
    required this.subtitle,
    required this.isEnding,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 4.h, 10.w, 6.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white.withOpacity(0.9),
              size: 18.sp,
            ),
          ),
          // live avatar
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.yellow, AppColors.orange],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: EdgeInsets.all(2.w),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff072238),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.yellow,
                size: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  softWrap: true,
                  maxLines: 2,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5.sp,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.sky,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.sky.withOpacity(0.7),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fade(begin: 0.4, end: 1, duration: 900.ms),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        subtitle,
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isEnding)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.yellow,
                ),
              ),
            )
          else
            TextButton(
              onPressed: onEnd,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.orange,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
              ),
              child: Text(
                'End',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────

class _EmptyChatHint extends StatelessWidget {
  final bool isTopics;
  final String? topic;
  const _EmptyChatHint({required this.isTopics, this.topic});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                  Icons.waving_hand_rounded,
                  color: AppColors.yellow,
                  size: 36.sp,
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .rotate(begin: -0.05, end: 0.05, duration: 800.ms),
            SizedBox(height: 14.h),
            Text(
              isTopics ? 'Ready when you are' : 'Say anything to start',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              isTopics
                  ? 'Practice “${topic ?? 'this topic'}” — type your first message below.'
                  : 'EnglishCoach will reply and gently correct mistakes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 12.5.sp,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ───────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final int index;

  const _MessageBubble({required this.message, required this.index});

  String _correctionsLabel(int count) {
    if (count == 1) return '1 correction in this message';
    return '$count corrections in this message';
  }

  void _openCorrectionsSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CorrectionsSheet(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    final hasCorrections = isUser && message.corrections.isNotEmpty;
    final count = message.corrections.length;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: EdgeInsets.only(left: 4.w, bottom: 5.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.yellow.withOpacity(0.85),
                    size: 12.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'EnglishCoach',
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 0.86.sw),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                      bottomLeft: Radius.circular(isUser ? 20.r : 6.r),
                      bottomRight: Radius.circular(isUser ? 6.r : 20.r),
                    ),
                    gradient: isUser
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xff1A9BC7), Color(0xff0D6E99)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xff1A3348), Color(0xff152A3C)],
                          ),
                    border: Border.all(
                      color: isUser
                          ? AppColors.sky.withOpacity(0.45)
                          : Colors.white.withOpacity(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xff1A9BC7).withOpacity(0.28)
                            : Colors.black.withOpacity(0.12),
                        blurRadius: isUser ? 14 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    softWrap: true,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.5.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 240.ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),

          // Premium corrections CTA — expands on tap only
          if (hasCorrections) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openCorrectionsSheet(context),
                  borderRadius: BorderRadius.circular(22.r),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 0.86.sw),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22.r),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.yellow.withOpacity(0.18),
                          AppColors.orange.withOpacity(0.16),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.yellow.withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.yellow, AppColors.orange],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$count',
                            style: GoogleFonts.poppins(
                              color: AppColors.dark,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            _correctionsLabel(count),
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              color: AppColors.yellow,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.yellow,
                          size: 18.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet — full corrections + optional full corrected sentence
class _CorrectionsSheet extends StatelessWidget {
  final ChatMessageModel message;
  const _CorrectionsSheet({required this.message});

  String _errorLabel(String type) {
    switch (type) {
      case 'grammar':
        return 'Grammar';
      case 'vocabulary':
        return 'Vocabulary';
      case 'spelling':
        return 'Spelling';
      case 'word_order':
        return 'Word order';
      case 'preposition':
        return 'Preposition';
      case 'tense':
        return 'Tense';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = message.corrections.length;
    final title = count == 1
        ? '1 correction found'
        : '$count corrections found';

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xff0F2438),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border.all(color: AppColors.sky.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 8.h),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.auto_fix_high_rounded,
                        color: AppColors.orange,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Review each note to improve faster',
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
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
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
                  children: [
                    // Original message
                    Text(
                      'Your message',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      child: Text(
                        message.content,
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13.5.sp,
                          height: 1.45,
                        ),
                      ),
                    ),

                    // Full corrected version (if different)
                    if (message.correctedContent != null &&
                        message.correctedContent!.isNotEmpty &&
                        message.correctedContent != message.content) ...[
                      SizedBox(height: 14.h),
                      Text(
                        'Suggested version',
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          color: const Color(0xff143528).withOpacity(0.85),
                          border: Border.all(
                            color: Colors.greenAccent.withOpacity(0.22),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.greenAccent.shade200,
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                message.correctedContent!,
                                softWrap: true,
                                style: GoogleFonts.poppins(
                                  color: Colors.greenAccent.shade100,
                                  fontSize: 13.5.sp,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 18.h),
                    Text(
                      'Details',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    ...message.corrections.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.r),
                                    color: AppColors.orange.withOpacity(0.15),
                                  ),
                                  child: Text(
                                    _errorLabel(c.errorType),
                                    style: GoogleFonts.poppins(
                                      color: AppColors.orange,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '#${i + 1}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white24,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  height: 1.4,
                                  color: Colors.white70,
                                ),
                                children: [
                                  TextSpan(
                                    text: c.originalFragment,
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Color(0xffFF8A80),
                                    ),
                                  ),
                                  const TextSpan(text: '  →  '),
                                  TextSpan(
                                    text: c.correctedFragment,
                                    style: const TextStyle(
                                      color: Color(0xff69F0AE),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (c.explanation.isNotEmpty) ...[
                              SizedBox(height: 8.h),
                              Text(
                                c.explanation,
                                softWrap: true,
                                textDirection: ui.TextDirection.rtl,
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 12.5.sp,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Typing indicator ─────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, top: 2.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
                  width: 7.w,
                  height: 7.w,
                  margin: EdgeInsets.only(right: i < 2 ? 5.w : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.yellow.withOpacity(0.85),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .fade(
                  begin: 0.25,
                  end: 1,
                  delay: (i * 140).ms,
                  duration: 420.ms,
                )
                .then()
                .fade(begin: 1, end: 0.25, duration: 420.ms);
          }),
        ),
      ),
    );
  }
}

// ── Error banner ─────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.red.withOpacity(0.15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Text(
        text,
        softWrap: true,
        style: GoogleFonts.poppins(
          color: Colors.redAccent.shade100,
          fontSize: 12.sp,
          height: 1.35,
        ),
      ),
    );
  }
}

// ── Composer (input) ─────────────────────────────────────────

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 10.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 6.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: AppColors.sky.withOpacity(0.28)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sky.withOpacity(0.08),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      maxLength: 1000,
                      maxLines: 5,
                      minLines: 1,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.sp,
                        height: 1.35,
                      ),
                      cursorColor: AppColors.yellow,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: enabled
                            ? 'Message EnglishCoach…'
                            : 'Session ended',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: enabled && !isSending
                          ? (_) => onSend()
                          : null,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  GestureDetector(
                    onTap: enabled && !isSending ? onSend : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: enabled && !isSending
                            ? const LinearGradient(
                                colors: [AppColors.orange, AppColors.yellow],
                              )
                            : null,
                        color: enabled && !isSending
                            ? null
                            : Colors.white.withOpacity(0.08),
                        boxShadow: enabled && !isSending
                            ? [
                                BoxShadow(
                                  color: AppColors.orange.withOpacity(0.35),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: isSending
                          ? Padding(
                              padding: EdgeInsets.all(11.w),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.yellow.withOpacity(0.8),
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              color: enabled ? AppColors.dark : Colors.white24,
                              size: 22.sp,
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
}

// ── End sheet ────────────────────────────────────────────────

class _EndSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _EndSheet({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(14.w),
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 22.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: const Color(0xff0F2438),
        border: Border.all(color: AppColors.sky.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 16.h),
          Icon(Icons.flag_rounded, color: AppColors.yellow, size: 32.sp),
          SizedBox(height: 10.h),
          Text(
            'End this session?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'You’ll get a summary and XP based on your messages.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13.sp),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white24),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Keep chatting',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.dark,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'End session',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
