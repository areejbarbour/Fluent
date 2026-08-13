// 📁 lib/presentation/screens/chat/chat_summary_screen.dart
// Session summary — premium Fluent style

import 'dart:ui' as ui;

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/chat/chat_cubit.dart';
import 'package:fluent/data/models/chat_models.dart';
import 'package:fluent/presentation/widgets/app_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatSummaryScreen extends StatelessWidget {
  final ChatSessionModel session;
  final ChatSessionSummaryModel summary;

  const ChatSummaryScreen({
    super.key,
    required this.session,
    required this.summary,
  });

  String _strengthLabel(String s) {
    switch (s) {
      case 'low_error_rate':
        return 'Low error rate';
      case 'active_participation':
        return 'Active participation';
      default:
        return s;
    }
  }

  String _errorLabel(String t) {
    switch (t) {
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
        return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMsgCount = session.messages.where((m) => m.isFromUser).length;

    return Scaffold(
      backgroundColor: const Color(0xff020B18),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AppBackdrop(starCount: 24, seed: 19),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: Row(
                    children: [
                      Text(
                        'Session complete',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // XP hero
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 28.h,
                            horizontal: 20.w,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.r),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.yellow.withOpacity(0.2),
                                AppColors.orange.withOpacity(0.12),
                                const Color(0xff072238).withOpacity(0.9),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.yellow.withOpacity(0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.yellow.withOpacity(0.12),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: AppColors.yellow,
                                size: 42.sp,
                              ).animate().scale(
                                begin: const Offset(0.6, 0.6),
                                end: const Offset(1, 1),
                                duration: 450.ms,
                                curve: Curves.elasticOut,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                    '+${summary.xpAwarded} XP',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.yellow,
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 100.ms)
                                  .slideY(begin: 0.2, end: 0),
                              SizedBox(height: 4.h),
                              Text(
                                userMsgCount < 3
                                    ? 'Need 3+ messages to earn XP'
                                    : 'Nice work this session!',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12.5.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),

                        if (summary.overallFeedback != null &&
                            summary.overallFeedback!.isNotEmpty) ...[
                          _SectionLabel('Feedback'),
                          SizedBox(height: 8.h),
                          _GlassBox(
                            child: Text(
                              summary.overallFeedback!,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13.5.sp,
                                height: 1.5,
                              ),
                              textDirection: ui.TextDirection.rtl,
                            ),
                          ),
                          SizedBox(height: 18.h),
                        ],

                        if (summary.strengths.isNotEmpty) ...[
                          _SectionLabel('Strengths', color: Colors.greenAccent),
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: summary.strengths
                                .map(
                                  (s) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 7.h,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.r),
                                      color: Colors.green.withOpacity(0.12),
                                      border: Border.all(
                                        color: Colors.greenAccent.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _strengthLabel(s),
                                      style: GoogleFonts.poppins(
                                        color: Colors.greenAccent.shade100,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          SizedBox(height: 18.h),
                        ],

                        if (summary.weaknesses.isNotEmpty) ...[
                          _SectionLabel(
                            'Focus next time',
                            color: AppColors.orange,
                          ),
                          SizedBox(height: 8.h),
                          ...summary.weaknesses.map(
                            (w) => Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14.r),
                                color: AppColors.orange.withOpacity(0.08),
                                border: Border.all(
                                  color: AppColors.orange.withOpacity(0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _errorLabel(w.errorType),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.r),
                                      color: AppColors.orange.withOpacity(0.2),
                                    ),
                                    child: Text(
                                      '${w.count}×',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.orange,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),
                        ],

                        Row(
                          children: [
                            _StatCard(
                              label: 'Messages',
                              value: '$userMsgCount',
                            ),
                            SizedBox(width: 10.w),
                            _StatCard(
                              label: 'Mode',
                              value: session.isFreeTalk
                                  ? 'Free Talk'
                                  : 'Topics',
                            ),
                          ],
                        ),
                        SizedBox(height: 28.h),

                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.read<ChatCubit>().startNewAfterSummary();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
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
                            child: Center(
                              child: Text(
                                'Start new session',
                                style: GoogleFonts.poppins(
                                  color: AppColors.dark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.read<ChatCubit>().loadHistory();
                          },
                          child: Text(
                            'View history',
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const _SectionLabel(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        color: color ?? Colors.white38,
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  final Widget child;
  const _GlassBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
