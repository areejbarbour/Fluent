// lib/data/models/lesson_status.dart
//
// Mirrors App\Enums\ContentStatus on the backend (in declaration order).
// Kept as its own enum (rather than reusing QuestionType-style file) so the
// lesson feature stays self-contained, same convention used for
// QuestionType / QuestionDifficulty.

enum LessonStatus {
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
  const LessonStatus(this.value, this.displayName);

  static LessonStatus fromString(String? value) {
    if (value == null) return LessonStatus.draft;
    return LessonStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => LessonStatus.draft,
    );
  }
}
