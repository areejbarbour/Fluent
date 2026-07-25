import 'package:fluent/data/models/question_model.dart';

class TestModel {
  final int id;
  final String titleEn;
  final String titleAr;
  final int passingScore;
  final String status;
  final String testableType; // 'Course' or 'Lesson'
  final int testableId;
  final String? createdAt;
  final String? updatedAt;
  final List<Question> questions; // الأسئلة المرتبطة بالاختبار

  TestModel({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.passingScore,
    required this.status,
    required this.testableType,
    required this.testableId,
    this.createdAt,
    this.updatedAt,
    this.questions = const [],
  });

  // التحقق من صلاحية التعديل بناءً على حالة الاختبار (مع تجاهل حالة الأحرف Case-insensitive)
  bool get canEdit {
    final lowerStatus = status.toLowerCase();
    return lowerStatus != 'in_review' &&
        lowerStatus != 'archived' &&
        lowerStatus != 'closed';
  }

  // التحقق من صلاحية الحذف بناءً على حالة الاختبار (مع تجاهل حالة الأحرف Case-insensitive)
  bool get canDelete {
    final lowerStatus = status.toLowerCase();
    return lowerStatus != 'published' &&
        lowerStatus != 'archived' &&
        lowerStatus != 'closed' &&
        lowerStatus != 'in_review';
  }

  factory TestModel.fromJson(Map<String, dynamic> json) {
    List<Question> parsedQuestions = [];
    if (json['questions'] is List) {
      parsedQuestions = (json['questions'] as List)
          .whereType<Map>()
          .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return TestModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      titleEn: json['title_en']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      passingScore: json['passing_score'] is int
          ? json['passing_score']
          : int.tryParse(json['passing_score'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'draft',
      testableType: json['testable_type']?.toString() ?? 'Lesson',
      testableId: json['testable_id'] is int
          ? json['testable_id']
          : int.tryParse(json['testable_id'].toString()) ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      questions: parsedQuestions,
    );
  }
}
