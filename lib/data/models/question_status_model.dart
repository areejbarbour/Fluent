class QuestionStatus {
  final String status;
  final String message;
  final bool willRevertToPending;
  final List<AffectedTest> affectedPublishedTests;
  final List<AffectedTest> affectedArchivedTests;
  final List<AffectedTest> affectedInReviewTests;
  final List<AffectedTest> affectedApprovedTests;
  final List<AffectedTest> affectedClosedTests; 

  QuestionStatus({
    required this.status,
    required this.message,
    required this.willRevertToPending,
    this.affectedPublishedTests = const [],
    this.affectedArchivedTests = const [],
    this.affectedInReviewTests = const [],
    this.affectedApprovedTests = const [],
    this.affectedClosedTests = const [], 
  });


  factory QuestionStatus.fromJson(Map<String, dynamic> json) {
    List<AffectedTest> parseList(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => AffectedTest.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    }

    return QuestionStatus(
      status: json['status']?.toString() ?? 'Editable.',
      message: json['message']?.toString() ?? '',
      willRevertToPending: json['will_revert_to_pending'] == true,
      affectedPublishedTests: parseList(json['affected_published_tests']),
      affectedArchivedTests: parseList(json['affected_archived_tests']),
      affectedInReviewTests: parseList(json['affected_in_review_tests']),
      affectedApprovedTests: parseList(json['affected_approved_tests']),
      affectedClosedTests: parseList(json['affected_closed_tests']), 
    );
  }
}

class AffectedTest {
  final int id;
  final String? titleEn;
  final String? titleAr;
  final String? testableType;
  final int? testableId;
  final String? status; 

  AffectedTest({
    required this.id,
    this.titleEn,
    this.titleAr,
    this.testableType,
    this.testableId,
    this.status, 
  });

  String get displayTitle {
    if (titleEn != null && titleEn!.isNotEmpty) return titleEn!;
    if (titleAr != null && titleAr!.isNotEmpty) return titleAr!;
    return 'Test #$id';
  }

  factory AffectedTest.fromJson(Map<String, dynamic> json) {
    return AffectedTest(
      id: json['id'] is int ? json['id'] : 0,
      titleEn: json['title_en']?.toString(),
      titleAr: json['title_ar']?.toString(),
      testableType: json['testable_type']?.toString(),
      testableId: json['testable_id'] is int ? json['testable_id'] : null,
      status: json['status']?.toString(), 
    );
  }
}

class BlockingTests {
  final List<AffectedTest> blockingTests;

  BlockingTests({this.blockingTests = const []});

  factory BlockingTests.fromJson(Map<String, dynamic> json) {
    final list = json['blocking_tests'];
    if (list is List) {
      return BlockingTests(
        blockingTests: list
            .whereType<Map>()
            .map((e) => AffectedTest.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
    return BlockingTests();
  }
}
