import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/data/models/content_review_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared UI for a single review note.
///
/// Backend contract:
/// - is_system_generated == true  → System note (cascade / returned from approved)
/// - is_system_generated == false → Admin / reviewer note
class ReviewNotePreview extends StatelessWidget {
  final ContentReviewNote note;

  /// compact: list cards / status board
  /// comfortable: detail screens / forms
  final bool compact;

  /// How many lines of note body to show.
  final int maxLines;

  const ReviewNotePreview({
    super.key,
    required this.note,
    this.compact = true,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final isSys = note.isSystemGenerated;
    final accent = isSys ? Colors.orange.shade300 : AppColors.sky;
    final label = isSys ? 'System' : 'Admin';
    final icon = isSys
        ? Icons.info_outline_rounded
        : Icons.person_outline_rounded;

    final padH = compact ? 8.w : 12.w;
    final padV = compact ? 6.h : 10.h;
    final titleSize = compact ? 9.sp : 11.sp;
    final bodySize = compact ? 10.sp : 12.sp;
    final iconSize = compact ? 11.sp : 14.sp;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(compact ? 8.r : 12.r),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: iconSize, color: accent),
              SizedBox(width: 4.w),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: accent,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 3.h : 6.h),
          Text(
            note.note ?? '—',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: bodySize,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Renders one or more review notes (System vs Admin).
/// Used under status banners and on list cards when status == changes_requested.
class ReviewNotesSection extends StatelessWidget {
  final List<ContentReviewNote> notes;
  final bool compact;
  final int maxItems;
  final int maxLinesPerNote;
  final String? title;

  const ReviewNotesSection({
    super.key,
    required this.notes,
    this.compact = true,
    this.maxItems = 3,
    this.maxLinesPerNote = 2,
    this.title,
  });

  List<ContentReviewNote> get _visible {
    final withText = notes.where((n) => n.hasText).toList();
    if (withText.length <= maxItems) return withText;
    return withText.take(maxItems).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: compact ? 10.sp : 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) SizedBox(height: compact ? 4.h : 8.h),
          ReviewNotePreview(
            note: visible[i],
            compact: compact,
            maxLines: maxLinesPerNote,
          ),
        ],
      ],
    );
  }
}
