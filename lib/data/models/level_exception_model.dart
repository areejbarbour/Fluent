

class LevelExceptionModel {
  final int id;
  final String? status;
  final String? reason;
  final String? reviewNote;
  final List<String> attachments;
  final String? executedAt;
  final String? createdAt;
  final String? updatedAt;
  final RequestedLevel? requestedLevel;

  LevelExceptionModel({
    required this.id,
    this.status,
    this.reason,
    this.reviewNote,
    this.attachments = const [],
    this.executedAt,
    this.createdAt,
    this.updatedAt,
    this.requestedLevel,
  });

  factory LevelExceptionModel.fromJson(Map<String, dynamic> json) {
    return LevelExceptionModel(
      id: json['id'] ?? 0,
      status: json['status']?.toString(),
      reason: json['reason']?.toString(),
      reviewNote: json['review_note']?.toString(),
      attachments: (json['attachments'] is List)
          ? (json['attachments'] as List)
              .map((e) => e.toString())
              .toList()
          : [],
      executedAt: json['executed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      requestedLevel: json['requested_level'] != null
          ? RequestedLevel.fromJson(
              Map<String, dynamic>.from(json['requested_level']),
            )
          : null,
    );
  }

  String get statusLabel {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'قيد الانتظار';
    }
  }
}

class RequestedLevel {
  final int id;
  final String name;

  RequestedLevel({
    required this.id,
    required this.name,
  });

  factory RequestedLevel.fromJson(Map<String, dynamic> json) {
    return RequestedLevel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}