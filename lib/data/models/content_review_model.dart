

class ContentReviewNote {
  final int id;
  final String? note;
  final String? createdAt;
  final String? updatedAt;
  final int? contentReviewId;

 
  final bool isSystemGenerated;

  ContentReviewNote({
    required this.id,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.contentReviewId,
    this.isSystemGenerated = false,
  });

  String get sourceLabel => isSystemGenerated ? 'System' : 'Admin';

  bool get hasText => note != null && note!.trim().isNotEmpty;

  factory ContentReviewNote.fromJson(Map<String, dynamic> json) {
    final text =
        json['message']?.toString() ??
        json['note']?.toString() ??
        json['body']?.toString();

    final sysRaw = json['is_system_generated'];
    final isSystem =
        sysRaw == true ||
        sysRaw == 1 ||
        sysRaw?.toString().toLowerCase() == 'true';

    return ContentReviewNote(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      note: (text != null && text.trim().isNotEmpty) ? text.trim() : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      contentReviewId: json['content_review_id'] is int
          ? json['content_review_id'] as int
          : int.tryParse(json['content_review_id']?.toString() ?? ''),
      isSystemGenerated: isSystem,
    );
  }

  
  static List<ContentReviewNote> parseList(dynamic raw) {
    final notes = <ContentReviewNote>[];
    if (raw is! List) return notes;

    for (var i = 0; i < raw.length; i++) {
      final n = raw[i];
      if (n is Map) {
        notes.add(ContentReviewNote.fromJson(Map<String, dynamic>.from(n)));
      } else if (n is String && n.trim().isNotEmpty) {
        notes.add(
          ContentReviewNote(id: i, note: n.trim(), isSystemGenerated: false),
        );
      }
    }
    return notes;
  }
}

class ContentReviewSession {
  final int id;
  final String status;
  final int? reviewerId;
  final String? reviewerName;

  final String? claimedAt;
  final String? completedAt;
  final String? createdAt;
  final String? updatedAt;

  final List<ContentReviewNote> notes;

  ContentReviewSession({
    required this.id,
    required this.status,
    this.reviewerId,
    this.reviewerName,
    this.claimedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.notes = const [],
  });

  factory ContentReviewSession.fromJson(Map<String, dynamic> json) {
    final notes = ContentReviewNote.parseList(json['notes']);

    String? reviewerName;
    final reviewer = json['reviewer'];
    if (reviewer is Map) {
      final first = reviewer['first_name']?.toString() ?? '';
      final last = reviewer['last_name']?.toString() ?? '';
      reviewerName = '$first $last'.trim();
      if (reviewerName.isEmpty) reviewerName = null;
    }

    return ContentReviewSession(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      reviewerId: json['reviewer_id'] is int
          ? json['reviewer_id'] as int
          : int.tryParse(json['reviewer_id']?.toString() ?? ''),
      reviewerName: reviewerName,
      claimedAt: json['claimed_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      notes: notes,
    );
  }
}


class ReviewHistoryItem {
  final String type; 
  final String? timestamp;
  final ContentReviewSession? reviewSession;
  final ContentReviewNote? systemNote;

  ReviewHistoryItem({
    required this.type,
    this.timestamp,
    this.reviewSession,
    this.systemNote,
  });

  bool get isReviewSession => type == 'review_session';
  bool get isSystemNote => type == 'system_note';

  factory ReviewHistoryItem.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final data = json['data'];

    ContentReviewSession? session;
    ContentReviewNote? note;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (type == 'review_session') {
        session = ContentReviewSession.fromJson(map);
      } else if (type == 'system_note') {
        note = ContentReviewNote.fromJson(map);
      }
    }

    return ReviewHistoryItem(
      type: type,
      timestamp: json['timestamp']?.toString(),
      reviewSession: session,
      systemNote: note,
    );
  }
}

class ContentReviewActionResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? lessonJson;
  final Map<String, dynamic>? testJson;
  final Map<String, dynamic>? reviewJson;
  final Map<String, dynamic>? errors;

  ContentReviewActionResult({
    required this.success,
    this.message,
    this.lessonJson,
    this.testJson,
    this.reviewJson,
    this.errors,
  });
}
