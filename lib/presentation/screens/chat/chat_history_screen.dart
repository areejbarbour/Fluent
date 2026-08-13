// 📁 lib/presentation/screens/chat/chat_history_screen.dart
// History + detail — premium Fluent style

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
import 'package:intl/intl.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is ChatHistoryDetailLoading) {
          return Scaffold(
            backgroundColor: const Color(0xff020B18),
            body: Stack(
              children: [
                const AppBackdrop(starCount: 16, seed: 5),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.yellow),
                ),
              ],
            ),
          );
        }

        if (state is ChatHistoryDetailLoaded) {
          return _HistoryDetailView(session: state.session);
        }

        return Scaffold(
          backgroundColor: const Color(0xff020B18),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              const AppBackdrop(starCount: 20, seed: 8),
              SafeArea(
                child: Column(
                  children: [
                    _HistoryAppBar(
                      onBack: () {
                        HapticFeedback.selectionClick();
                        context.read<ChatCubit>().bootstrap();
                      },
                    ),
                    Expanded(child: _buildList(context, state)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, ChatState state) {
    if (state is ChatHistoryLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      );
    }

    if (state is ChatFailure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.message,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
              ),
            ),
            TextButton(
              onPressed: () => context.read<ChatCubit>().loadHistory(),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(color: AppColors.yellow),
              ),
            ),
          ],
        ),
      );
    }

    if (state is! ChatHistoryLoaded) return const SizedBox.shrink();

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white24,
              size: 40.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              'No past sessions yet',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120) {
          context.read<ChatCubit>().loadMoreHistory();
        }
        return false;
      },
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return Padding(
              padding: EdgeInsets.all(16.w),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.yellow,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          final item = state.items[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _HistoryTile(
              item: item,
              index: index,
              onTap: () {
                HapticFeedback.selectionClick();
                context.read<ChatCubit>().openHistorySession(item.id);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryAppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _HistoryAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 16.w, 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white.withOpacity(0.9),
              size: 18.sp,
            ),
          ),
          Text(
            'Chat history',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ChatHistoryItem item;
  final int index;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = item.startedAt != null
        ? DateFormat('dd MMM · HH:mm').format(item.startedAt!.toLocal())
        : '';
    final isTopic = item.mode == 'topics';

    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18.r),
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.09)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13.r),
                      color: isTopic
                          ? AppColors.sky.withOpacity(0.12)
                          : AppColors.yellow.withOpacity(0.12),
                      border: Border.all(
                        color: isTopic
                            ? AppColors.sky.withOpacity(0.25)
                            : AppColors.yellow.withOpacity(0.25),
                      ),
                    ),
                    child: Icon(
                      isTopic ? Icons.topic_rounded : Icons.forum_rounded,
                      color: isTopic ? AppColors.sky : AppColors.yellow,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTopic
                              ? (item.topicTitle ?? 'Topic session')
                              : 'Free Talk',
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 11.sp,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.xpAwarded > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        color: AppColors.yellow.withOpacity(0.12),
                        border: Border.all(
                          color: AppColors.yellow.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '+${item.xpAwarded}',
                        style: GoogleFonts.poppins(
                          color: AppColors.yellow,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (40 + index * 30).ms, duration: 300.ms)
        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }
}

class _HistoryDetailView extends StatelessWidget {
  final ChatSessionModel session;
  const _HistoryDetailView({required this.session});

  @override
  Widget build(BuildContext context) {
    final title = session.isTopics
        ? (session.topic?.title ?? 'Topic Chat')
        : 'Free Talk';

    return Scaffold(
      backgroundColor: const Color(0xff020B18),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AppBackdrop(starCount: 16, seed: 2),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 4.h, 12.w, 6.h),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.read<ChatCubit>().backToHistory();
                        },
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 18.sp,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          softWrap: true,
                          maxLines: 2,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.sp,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (session.summary != null)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      color: AppColors.yellow.withOpacity(0.08),
                      border: Border.all(
                        color: AppColors.yellow.withOpacity(0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: AppColors.yellow,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '+${session.summary!.xpAwarded} XP',
                          style: GoogleFonts.poppins(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.sp,
                          ),
                        ),
                        if (session.summary!.overallFeedback != null) ...[
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              session.summary!.overallFeedback!,
                              softWrap: true,
                              style: GoogleFonts.poppins(
                                color: Colors.white60,
                                fontSize: 11.sp,
                                height: 1.35,
                              ),
                              textDirection: ui.TextDirection.rtl,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: session.messages.isEmpty
                      ? Center(
                          child: Text(
                            'No messages in this session.',
                            style: GoogleFonts.poppins(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 20.h),
                          itemCount: session.messages.length,
                          itemBuilder: (context, index) {
                            return _ReadOnlyBubble(
                              message: session.messages[index],
                            );
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

class _ReadOnlyBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _ReadOnlyBubble({required this.message});

  String _correctionsLabel(int count) {
    if (count == 1) return '1 correction in this message';
    return '$count corrections in this message';
  }

  void _openCorrections(BuildContext context) {
    HapticFeedback.selectionClick();
    final count = message.corrections.length;
    final title = count == 1
        ? '1 correction found'
        : '$count corrections found';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xff0A1622),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 14.h),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    softWrap: true,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    message.content,
                    softWrap: true,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13.5.sp,
                      height: 1.45,
                    ),
                  ),
                  if (message.correctedContent != null &&
                      message.correctedContent!.isNotEmpty &&
                      message.correctedContent != message.content) ...[
                    SizedBox(height: 12.h),
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
                      child: Text(
                        message.correctedContent!,
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          color: Colors.greenAccent.shade100,
                          fontSize: 13.5.sp,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  ...message.corrections.map((c) {
                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        color: Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.originalFragment}  →  ${c.correctedFragment}',
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13.5.sp,
                              height: 1.4,
                            ),
                          ),
                          if (c.explanation.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              c.explanation,
                              softWrap: true,
                              textDirection: ui.TextDirection.rtl,
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12.sp,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    final hasCorrections = isUser && message.corrections.isNotEmpty;
    final count = message.corrections.length;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: 0.86.sw),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(isUser ? 18.r : 6.r),
                  bottomRight: Radius.circular(isUser ? 6.r : 18.r),
                ),
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xff0C6A8C), Color(0xff0A4F6E)],
                      )
                    : null,
                color: isUser ? null : const Color(0xff0E1C2A),
                border: Border.all(
                  color: isUser
                      ? AppColors.sky.withOpacity(0.22)
                      : Colors.white.withOpacity(0.07),
                ),
              ),
              child: Text(
                message.content,
                softWrap: true,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (hasCorrections) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openCorrections(context),
                  borderRadius: BorderRadius.circular(22.r),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 0.86.sw),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22.r),
                      color: AppColors.orange.withOpacity(0.12),
                      border: Border.all(
                        color: AppColors.orange.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.orange.withOpacity(0.22),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$count',
                            style: GoogleFonts.poppins(
                              color: AppColors.orange,
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
                              color: AppColors.orange,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.orange.withOpacity(0.9),
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
