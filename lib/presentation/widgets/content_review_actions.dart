import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/teacher/content_review/content_review_cubit.dart';
import 'package:fluent/cubit/teacher/content_review/content_review_state.dart';
import 'package:fluent/data/models/content_review_model.dart';
import 'package:fluent/presentation/widgets/app_date_format.dart';
import 'package:fluent/presentation/widgets/app_snackbar.dart';
import 'package:fluent/presentation/widgets/review_note_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Submit / Resubmit / History actions for Lessons & Tests.
/// Matches backend ContentReview rules:
/// - Submit   → only when status == draft
/// - Resubmit → only when status == changes_requested
/// - History  → always available (shows empty state if none)
class ContentReviewActionsBar extends StatelessWidget {
  final String status;
  final int targetId;
  final bool isLesson; // true = lesson, false = test
  final VoidCallback? onSuccess; // e.g. reload parent data
  final bool compact; // smaller buttons for cards
  /// Lesson-only: backend requires a video before submit.
  final bool hasVideo;

  /// Lesson-only: backend requires exactly one associated draft test.
  final bool hasDraftTest;

  /// Optional notes from list APIs (review_notes).
  /// When status == changes_requested these are shown above the action buttons
  /// with System vs Admin distinction.
  final List<ContentReviewNote>? reviewNotes;

  const ContentReviewActionsBar({
    super.key,
    required this.status,
    required this.targetId,
    required this.isLesson,
    this.onSuccess,
    this.compact = false,
    this.hasVideo = true,
    this.hasDraftTest = true,
    this.reviewNotes,
  });

  String get _normalized => status.toLowerCase().trim();
  bool get _statusAllowsSubmit => _normalized == 'draft';
  bool get _canResubmit => _normalized == 'changes_requested';

  /// For lessons, also require video + draft test (matches ContentReviewService).
  bool get _canSubmit {
    if (!_statusAllowsSubmit) return false;
    if (!isLesson) return true;
    return hasVideo && hasDraftTest;
  }

  String? get _submitBlockedReason {
    if (!_statusAllowsSubmit) return null;
    if (!isLesson) return null;
    if (!hasVideo && !hasDraftTest) {
      return 'Upload a video and attach a draft test before submitting.';
    }
    if (!hasVideo) return 'Upload a lesson video before submitting.';
    if (!hasDraftTest)
      return 'Create a draft test for this lesson before submitting.';
    return null;
  }

  bool get _showAny => true; // history always

  @override
  Widget build(BuildContext context) {
    if (!_showAny) return const SizedBox.shrink();

    return BlocConsumer<ContentReviewCubit, ContentReviewState>(
      listener: (context, state) {
        if (state.actionSuccess) {
          showAppSnackBar(
            context,
            state.message ?? 'Done',
            type: AppSnackType.success,
          );
          context.read<ContentReviewCubit>().clearActionResult();
          onSuccess?.call();
        } else if (state.error != null && state.error!.isNotEmpty) {
          showAppSnackBar(context, state.error!, type: AppSnackType.error);
          context.read<ContentReviewCubit>().clearActionResult();
        }
      },
      builder: (context, state) {
        final loading = state.loading;

        if (compact) {
          return _buildCompact(context, loading);
        }
        return _buildFull(context, loading);
      },
    );
  }

  Widget _buildFull(BuildContext context, bool loading) {
    final blockedReason = _submitBlockedReason;
    final notes = (reviewNotes ?? const <ContentReviewNote>[])
        .where((n) => n.hasText)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // changes_requested: show Admin vs System notes above actions
        if (_canResubmit && notes.isNotEmpty) ...[
          ReviewNotesSection(
            notes: notes,
            compact: false,
            maxItems: 5,
            maxLinesPerNote: 4,
            title: 'Revision notes',
          ),
          SizedBox(height: 12.h),
        ],
        // Status is draft but missing video/draft test → show why Submit is blocked
        if (_statusAllowsSubmit && blockedReason != null) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.orange.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade300,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    blockedReason,
                    style: GoogleFonts.poppins(
                      color: Colors.orange.shade200,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],
        if (_canSubmit || _canResubmit) ...[
          Row(
            children: [
              if (_canSubmit)
                Expanded(
                  child: _actionButton(
                    context: context,
                    label: isLesson ? 'Submit for Review' : 'Submit Test',
                    icon: Icons.send_rounded,
                    color: AppColors.orange,
                    loading: loading,
                    onTap: () => _confirmAndRun(
                      context,
                      title: isLesson
                          ? 'Submit Lesson for Review?'
                          : 'Submit Test for Review?',
                      body: isLesson
                          ? 'The lesson and its draft test will move to Pending.'
                          : 'The test will move to Pending for admin review.',
                      action: () {
                        if (isLesson) {
                          context.read<ContentReviewCubit>().submitLesson(
                            targetId,
                          );
                        } else {
                          context.read<ContentReviewCubit>().submitTest(
                            targetId,
                          );
                        }
                      },
                    ),
                  ),
                ),
              if (_canResubmit)
                Expanded(
                  child: _actionButton(
                    context: context,
                    label: isLesson ? 'Resubmit Lesson' : 'Resubmit Test',
                    icon: Icons.refresh_rounded,
                    color: AppColors.lightOrange,
                    loading: loading,
                    onTap: () => _confirmAndRun(
                      context,
                      title: isLesson ? 'Resubmit Lesson?' : 'Resubmit Test?',
                      body:
                          'This will send your changes back for review (In Review).',
                      action: () {
                        if (isLesson) {
                          context.read<ContentReviewCubit>().resubmitLesson(
                            targetId,
                          );
                        } else {
                          context.read<ContentReviewCubit>().resubmitTest(
                            targetId,
                          );
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
        ],
        _historyButton(context, loading),
      ],
    );
  }

  Widget _buildCompact(BuildContext context, bool loading) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_canSubmit)
          _iconBtn(
            context: context,
            icon: Icons.send_rounded,
            tooltip: 'Submit',
            color: AppColors.orange,
            loading: loading,
            onTap: () => _confirmAndRun(
              context,
              title: isLesson ? 'Submit Lesson?' : 'Submit Test?',
              body: 'Move to Pending for review.',
              action: () {
                if (isLesson) {
                  context.read<ContentReviewCubit>().submitLesson(targetId);
                } else {
                  context.read<ContentReviewCubit>().submitTest(targetId);
                }
              },
            ),
          ),
        if (_canResubmit)
          _iconBtn(
            context: context,
            icon: Icons.refresh_rounded,
            tooltip: 'Resubmit',
            color: AppColors.lightOrange,
            loading: loading,
            onTap: () => _confirmAndRun(
              context,
              title: isLesson ? 'Resubmit Lesson?' : 'Resubmit Test?',
              body: 'Send changes back for review.',
              action: () {
                if (isLesson) {
                  context.read<ContentReviewCubit>().resubmitLesson(targetId);
                } else {
                  context.read<ContentReviewCubit>().resubmitTest(targetId);
                }
              },
            ),
          ),
        _iconBtn(
          context: context,
          icon: Icons.history_rounded,
          tooltip: 'History',
          color: AppColors.sky,
          loading: false,
          onTap: () => _openHistorySheet(context),
        ),
      ],
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? SizedBox(
              width: 14.w,
              height: 14.w,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 16.sp),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _historyButton(BuildContext context, bool loading) {
    return OutlinedButton.icon(
      onPressed: () => _openHistorySheet(context),
      icon: Icon(Icons.history_rounded, size: 16.sp),
      label: Text(
        'Review History',
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.sky,
        side: BorderSide(color: AppColors.sky.withOpacity(0.5)),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _iconBtn({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required Color color,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: loading
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, size: 16.sp, color: color),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String body,
    required VoidCallback action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
        content: Text(
          body,
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
              'Confirm',
              style: GoogleFonts.poppins(
                color: AppColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      action();
    }
  }

  void _openHistorySheet(BuildContext context) {
    final cubit = context.read<ContentReviewCubit>();
    if (isLesson) {
      cubit.loadLessonHistory(targetId);
    } else {
      cubit.loadTestHistory(targetId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ReviewHistorySheet(isLesson: isLesson),
      ),
    );
  }
}

class _ReviewHistorySheet extends StatelessWidget {
  final bool isLesson;
  const _ReviewHistorySheet({required this.isLesson});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            border: Border.all(color: AppColors.sky.withOpacity(0.25)),
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
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: AppColors.sky,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        isLesson
                            ? 'Lesson Review History'
                            : 'Test Review History',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white12, height: 1.h),
              Expanded(
                child: BlocBuilder<ContentReviewCubit, ContentReviewState>(
                  builder: (context, state) {
                    if (state.historyLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.sky),
                      );
                    }
                    if (state.historyError != null) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Text(
                            state.historyError!,
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 13.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (state.history.isEmpty) {
                      return Center(
                        child: Text(
                          'No review history yet',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 13.sp,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.all(16.w),
                      itemCount: state.history.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        return _HistoryTile(item: state.history[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ReviewHistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.isReviewSession && item.reviewSession != null) {
      final s = item.reviewSession!;
      final allSystem =
          s.notes.isNotEmpty && s.notes.every((n) => n.isSystemGenerated);

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.sky.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rate_review_rounded,
                  color: AppColors.sky,
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Review Session',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                _chip(s.status),
              ],
            ),
            // Hide reviewer when every note is system-generated.
            if (s.reviewerName != null && !allSystem) ...[
              SizedBox(height: 6.h),
              Text(
                'Reviewer: ${s.reviewerName}',
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 11.sp,
                ),
              ),
            ],
            // Backend timestamps — only rows the API actually sent.
            _SessionTimestamps(
              claimedAt: s.claimedAt,
              completedAt: s.completedAt,
              createdAt: s.createdAt,
              updatedAt: s.updatedAt,
            ),
            if (s.notes.isNotEmpty) ...[
              SizedBox(height: 10.h),
              ...s.notes.map((n) => _NoteBlock(note: n)),
            ],
          ],
        ),
      );
    }

    // system_note history item
    final note = item.systemNote;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.orange.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.orange,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (note?.isSystemGenerated ?? true)
                      ? 'System Note'
                      : 'Admin Note',
                  style: GoogleFonts.poppins(
                    color: (note?.isSystemGenerated ?? true)
                        ? AppColors.orange
                        : AppColors.sky,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  note?.note ?? '—',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11.sp,
                  ),
                ),
                // Prefer note.createdAt; fall back to history timestamp.
                if (AppDateFormat.smart(note?.createdAt ?? item.timestamp) !=
                    null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    AppDateFormat.smart(note?.createdAt ?? item.timestamp)!,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (AppDateFormat.subtitle(
                        note?.createdAt ?? item.timestamp,
                      ) !=
                      null)
                    Text(
                      AppDateFormat.subtitle(
                        note?.createdAt ?? item.timestamp,
                      )!,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 9.sp,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.sky.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: AppColors.sky,
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Single note inside a review session (System vs Admin).
class _NoteBlock extends StatelessWidget {
  final ContentReviewNote note;
  const _NoteBlock({required this.note});

  @override
  Widget build(BuildContext context) {
    final isSys = note.isSystemGenerated;
    final accent = isSys ? AppColors.orange : AppColors.sky;
    final label = isSys ? 'System' : 'Admin';
    final primary = AppDateFormat.smart(note.createdAt);
    final secondary = AppDateFormat.subtitle(note.createdAt);

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: accent.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSys
                      ? Icons.info_outline_rounded
                      : Icons.person_outline_rounded,
                  size: 13.sp,
                  color: accent,
                ),
                SizedBox(width: 5.w),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: accent,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Text(
              note.note ?? '—',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12.sp,
                height: 1.35,
              ),
            ),
            if (primary != null) ...[
              SizedBox(height: 6.h),
              Text(
                primary,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (secondary != null)
                Text(
                  secondary,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 9.sp,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// claimed / completed / created / updated — only when backend sent them.
/// Layout matches global apps: smart primary + muted absolute subtitle.
class _SessionTimestamps extends StatelessWidget {
  final String? claimedAt;
  final String? completedAt;
  final String? createdAt;
  final String? updatedAt;

  const _SessionTimestamps({
    this.claimedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, IconData icon, String? raw})>[
      (label: 'Claimed', icon: Icons.handshake_outlined, raw: claimedAt),
      (label: 'Completed', icon: Icons.check_circle_outline, raw: completedAt),
      (label: 'Created', icon: Icons.add_circle_outline, raw: createdAt),
      (label: 'Updated', icon: Icons.update_rounded, raw: updatedAt),
    ];

    final visible = rows
        .where((r) => AppDateFormat.parse(r.raw) != null)
        .toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) ...[
                SizedBox(height: 8.h),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.white.withOpacity(0.06),
                ),
                SizedBox(height: 8.h),
              ],
              _TimestampRow(
                label: visible[i].label,
                icon: visible[i].icon,
                raw: visible[i].raw,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimestampRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? raw;

  const _TimestampRow({
    required this.label,
    required this.icon,
    required this.raw,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppDateFormat.smart(raw);
    final secondary = AppDateFormat.subtitle(raw);
    if (primary == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 14.sp, color: Colors.white54),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                primary,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              if (secondary != null) ...[
                SizedBox(height: 1.h),
                Text(
                  secondary,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.40),
                    fontSize: 10.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
