// lib/data/models/content_status.dart
enum ContentStatus {
  draft('draft', 'Draft'),
  pending('pending', 'Pending'),
  inReview('in_review', 'In Review'),
  changesRequested('changes_requested', 'Changes Requested'),
  approved('approved', 'Approved'),
  published('published', 'Published'),
  archived('archived', 'Archived'),
  closed('closed', 'Closed');

  final String value;
  final String displayName;
  const ContentStatus(this.value, this.displayName);

  static ContentStatus fromString(String? value) {
    if (value == null) return ContentStatus.draft;
    return ContentStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ContentStatus.draft,
    );
  }

  // ✅ User-friendly labels for Courses
  String get courseLabel {
    switch (this) {
      case ContentStatus.pending: return 'In Preparation';
      case ContentStatus.published: return 'Live';
      case ContentStatus.archived: return 'Archived';
      case ContentStatus.closed: return 'Closed';
      default: return displayName;
    }
  }

  // ✅ User-friendly labels for Lessons
  String get lessonLabel {
    switch (this) {
      case ContentStatus.draft: return 'Draft';
      case ContentStatus.pending: return 'Submitted';
      case ContentStatus.inReview: return 'Under Review';
      case ContentStatus.changesRequested: return 'Needs Revision';
      case ContentStatus.approved: return 'Approved';
      case ContentStatus.published: return 'Live';
      case ContentStatus.archived: return 'Archived';
      case ContentStatus.closed: return 'Closed';
    }
  }
}