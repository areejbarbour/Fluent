// lib/data/models/lesson_model.dart
class LessonModel {
  final int id;
  final String titleEn; // ✅ تم التغيير من title إلى titleEn
  final String titleAr; // ✅ تم إضافة titleAr
  final int courseId;
  final String status;
  final int order;
  final int xpPoints;
  final String? videoUrl; // ✅ يتم تعيينه من حقل 'video'
  final String? createdAt;
  final String? updatedAt;
  final String? courseName;

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
  });

  // lib/data/models/lesson_model.dart
  factory LessonModel.fromJson(Map<String, dynamic> json) {
    String? video = json['video']?.toString();
    if (video != null && video.trim().isEmpty) video = null;

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
          : int.tryParse(json['order']?.toString() ?? '1') ?? 1, // ✅ مهم جداً
      xpPoints: json['xp_points'] is int
          ? json['xp_points']
          : int.tryParse(json['xp_points']?.toString() ?? '20') ??
                20, // ✅ مهم جداً
      videoUrl: video,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  LessonModel copyWith({String? courseName}) {
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
    );
  }
}
