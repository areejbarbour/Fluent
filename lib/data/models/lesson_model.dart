class LessonModel {
  final int id;
  final String titleEn;
  final String titleAr;
  final int courseId;
  final String status;
  final int order;
  final int xpPoints;
  final String? videoUrl;
  final String? createdAt;
  final String? updatedAt;
  final String? courseName;

  /// Latest review notes when status == changes_requested (from list API).
  /// Never null at runtime — defaults to empty list.
  final List<String> reviewNotes;

  LessonModel({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.courseId,
    required this.status,
    required this.order,
    required this.xpPoints,
    this.videoUrl,
    this.createdAt,
    this.updatedAt,
    this.courseName,
    List<String>? reviewNotes,
  }) : reviewNotes = reviewNotes ?? const [];

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    String? video = json['video']?.toString();
    if (video != null && video.trim().isEmpty) video = null;

    final notes = <String>[];
    final rawNotes = json['review_notes'];
    if (rawNotes is List) {
      for (final n in rawNotes) {
        if (n is Map) {
          final msg =
              n['message']?.toString() ??
              n['note']?.toString() ??
              n['body']?.toString();
          if (msg != null && msg.trim().isNotEmpty) notes.add(msg.trim());
        } else if (n is String && n.trim().isNotEmpty) {
          notes.add(n.trim());
        }
      }
    }

    return LessonModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      titleEn: json['title_en']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      courseId: json['course_id'] is int
          ? json['course_id']
          : int.tryParse(json['course_id']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'draft',
      order: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '1') ?? 1,
      xpPoints: json['xp_points'] is int
          ? json['xp_points']
          : int.tryParse(json['xp_points']?.toString() ?? '20') ?? 20,
      videoUrl: video,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      reviewNotes: notes,
    );
  }

  LessonModel copyWith({String? courseName, List<String>? reviewNotes}) {
    return LessonModel(
      id: id,
      titleEn: titleEn,
      titleAr: titleAr,
      courseId: courseId,
      status: status,
      order: order,
      xpPoints: xpPoints,
      videoUrl: videoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      courseName: courseName ?? this.courseName,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }
}
