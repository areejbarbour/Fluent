/// Permission matrix matching backend TeacherLessonService / TestService exactly.
///
/// Lesson update blocked: closed | archived | approved | in_review
/// Lesson update restricted (published): only title_en, title_ar, xp_points
/// Lesson delete allowed: draft | pending | changes_requested
/// Lesson words manage: draft | pending | changes_requested
///
/// Test update blocked: in_review | archived | closed
/// Test update published → creates new draft version (still "editable" via versioning)
/// Test delete blocked: published | archived | closed | in_review
class TeacherPermissions {
  TeacherPermissions._();

  static String norm(String? s) => (s ?? '').toLowerCase().trim();

  // ─── Lesson ───────────────────────────────────────────────

  /// Backend: cannot update CLOSED | ARCHIVED | APPROVED | IN_REVIEW
  static bool canEditLesson(String? status) {
    const blocked = {'closed', 'archived', 'approved', 'in_review'};
    return !blocked.contains(norm(status));
  }

  /// Backend: published allows only title_en, title_ar, xp_points
  static bool isPublishedLessonEdit(String? status) =>
      norm(status) == 'published';

  /// Backend: cannot delete CLOSED | ARCHIVED | APPROVED | PUBLISHED | IN_REVIEW
  static bool canDeleteLesson(String? status) {
    const allowed = {'draft', 'pending', 'changes_requested'};
    return allowed.contains(norm(status));
  }

  /// Backend TeacherWordService: only on editable non-published lessons
  static bool canManageWords(String? status) {
    const allowed = {'draft', 'pending', 'changes_requested'};
    return allowed.contains(norm(status));
  }

  /// Submit requires status == draft (ContentReviewService)
  static bool canSubmitLesson(String? status) => norm(status) == 'draft';

  /// Resubmit requires status == changes_requested
  static bool canResubmitLesson(String? status) =>
      norm(status) == 'changes_requested';

  /// Extra pre-checks before Submit Lesson (backend also validates)
  static bool lessonReadyForSubmit({
    required String? status,
    required bool hasVideo,
    required bool hasDraftTest,
  }) {
    return canSubmitLesson(status) && hasVideo && hasDraftTest;
  }

  // ─── Test ─────────────────────────────────────────────────

  /// Backend: cannot edit IN_REVIEW | ARCHIVED | CLOSED
  /// Published is editable (creates new version)
  static bool canEditTest(String? status) {
    const blocked = {'in_review', 'archived', 'closed'};
    return !blocked.contains(norm(status));
  }

  /// Backend: cannot delete PUBLISHED | ARCHIVED | CLOSED | IN_REVIEW
  static bool canDeleteTest(String? status) {
    const blocked = {'published', 'archived', 'closed', 'in_review'};
    return !blocked.contains(norm(status));
  }

  static bool canSubmitTest(String? status) => norm(status) == 'draft';

  static bool canResubmitTest(String? status) =>
      norm(status) == 'changes_requested';
}
