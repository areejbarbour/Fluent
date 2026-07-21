import 'package:flutter/material.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/data/models/content_status.dart';

/// Shared status color/icon/label lookups used by BOTH the Courses board
/// and the Lessons board, since course.status and lesson.status come from
/// the exact same backend enum (App\Enums\ContentStatus). One consistent
/// visual language for "what does this status mean" across the whole app.
///
/// Shared chrome (background gradient, glass container, glowing circles) is
/// intentionally reused from QuestionUI rather than duplicated, so there's
/// still a single visual language project-wide.
class StatusUI {
  static Color statusColor(String status) {
    switch (ContentStatus.fromString(status)) {
      case ContentStatus.draft:
        return Colors.white70;
      case ContentStatus.pending:
        return AppColors.lightOrange;
      case ContentStatus.inReview:
        return AppColors.sky;
      case ContentStatus.changesRequested:
        return Colors.redAccent;
      case ContentStatus.approved:
        return Colors.greenAccent;
      case ContentStatus.published:
        return AppColors.yellow;
      case ContentStatus.archived:
        return Colors.purpleAccent;
      case ContentStatus.closed:
        return Colors.blueGrey.shade200;
    }
  }

  static IconData statusIcon(String status) {
    switch (ContentStatus.fromString(status)) {
      case ContentStatus.draft:
        return Icons.edit_note_rounded;
      case ContentStatus.pending:
        return Icons.hourglass_top_rounded;
      case ContentStatus.inReview:
        return Icons.rate_review_outlined;
      case ContentStatus.changesRequested:
        return Icons.report_gmailerrorred_rounded;
      case ContentStatus.approved:
        return Icons.verified_outlined;
      case ContentStatus.published:
        return Icons.public_rounded;
      case ContentStatus.archived:
        return Icons.archive_outlined;
      case ContentStatus.closed:
        return Icons.lock_outline_rounded;
    }
  }

  static String statusLabel(String status) =>
      ContentStatus.fromString(status).displayName;
}
