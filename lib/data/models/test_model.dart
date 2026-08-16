import 'package:fluent/utils/teacher_permissions.dart';
import 'package:fluent/data/models/question_model.dart';

class TestModel {
  final int id;
  final String titleEn;
  final String titleAr;
  final int passingScore;
  final String status;
  final String testableType; 
  final int testableId;
  final String? createdAt;
  final String? updatedAt;
  final List<Question> questions;

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

  String get normalizedStatus => status.toLowerCase().trim();
  String get normalizedTestableType => testableType.toLowerCase().trim();
  bool get isCourseTest => normalizedTestableType == 'course';
  bool get isLessonTest => normalizedTestableType == 'lesson';

  bool get canEdit => TeacherPermissions.canEditTest(status);

  bool get canDelete => TeacherPermissions.canDeleteTest(status);

  factory TestModel.fromJson(Map<String, dynamic> json) {
    final parsedQuestions = <Question>[];

    final questionsRaw = json['questions'];
    if (questionsRaw is List) {
      for (final item in questionsRaw) {
        if (item is Map) {
          parsedQuestions.add(
            Question.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
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
      status: json['status']?.toString().toLowerCase().trim() ?? 'draft',
      testableType:
          json['testable_type']?.toString().toLowerCase().trim() ?? 'lesson',
      testableId: json['testable_id'] is int
          ? json['testable_id']
          : int.tryParse(json['testable_id'].toString()) ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      questions: parsedQuestions,
    );
  }
}
