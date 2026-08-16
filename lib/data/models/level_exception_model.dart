
class LevelExceptionAttachment {
  final int id;
  final String url;

  const LevelExceptionAttachment({required this.id, required this.url});

  factory LevelExceptionAttachment.fromJson(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final idRaw = map['id'];
      final id = idRaw is int
          ? idRaw
          : int.tryParse(idRaw?.toString() ?? '0') ?? 0;
      final url = (map['url'] ?? map['original_url'] ?? map['file'] ?? '')
          .toString();
      return LevelExceptionAttachment(id: id, url: url);
    }
    final url = raw?.toString() ?? '';
    return LevelExceptionAttachment(id: 0, url: url);
  }

  Map<String, dynamic> toJson() => {'id': id, 'url': url};

  String get fileName {
    if (url.isEmpty) return 'attachment';
    final cleaned = url.split('?').first;
    final name = cleaned.split('/').last;
    return name.isEmpty ? 'attachment' : name;
  }

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');

  bool get canDelete => id > 0;

  LevelExceptionAttachment copyWith({int? id, String? url}) {
    return LevelExceptionAttachment(id: id ?? this.id, url: url ?? this.url);
  }
}

class LevelExceptionModel {
  final int id;
  final String? status;
  final String? reason;
  final String? reviewNote;
  final List<LevelExceptionAttachment> attachments;
  final String? executedAt;
  final String? createdAt;
  final String? updatedAt;
  final RequestedLevel? requestedLevel;
  final RequestedLevel? recommendedLevel;

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
    this.recommendedLevel,
  });

  factory LevelExceptionModel.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final attachments = <LevelExceptionAttachment>[];
    if (rawAttachments is List) {
      for (final item in rawAttachments) {
        attachments.add(LevelExceptionAttachment.fromJson(item));
      }
    }

    RequestedLevel? parseLevel(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map) {
        return RequestedLevel.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    }

    return LevelExceptionModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString(),
      reason: json['reason']?.toString(),
      reviewNote: json['review_note']?.toString(),
      attachments: attachments,
      executedAt: json['executed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      requestedLevel: parseLevel(
        json['requested_level'] ?? json['requestedLevel'],
      ),
      recommendedLevel: parseLevel(
        json['recommended_level'] ?? json['recommendedLevel'],
      ),
    );
  }

  bool get canManageAttachments {
    final s = status?.toLowerCase();
    return s == null || s == 'pending';
  }

  bool get isPending {
    final s = status?.toLowerCase();
    return s == null || s == 'pending';
  }

  String? get requestedLevelName {
    final n = requestedLevel?.name.trim();
    if (n == null || n.isEmpty) return null;
    return n;
  }

  String get statusLabel {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'in_review':
        return 'In Review';
      default:
        return 'Pending';
    }
  }

  LevelExceptionModel copyWith({
    int? id,
    String? status,
    String? reason,
    String? reviewNote,
    List<LevelExceptionAttachment>? attachments,
    String? executedAt,
    String? createdAt,
    String? updatedAt,
    RequestedLevel? requestedLevel,
    RequestedLevel? recommendedLevel,
  }) {
    return LevelExceptionModel(
      id: id ?? this.id,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      reviewNote: reviewNote ?? this.reviewNote,
      attachments: attachments ?? this.attachments,
      executedAt: executedAt ?? this.executedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requestedLevel: requestedLevel ?? this.requestedLevel,
      recommendedLevel: recommendedLevel ?? this.recommendedLevel,
    );
  }
}

class RequestedLevel {
  final int id;
  final String name;

  RequestedLevel({required this.id, required this.name});

  factory RequestedLevel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    final candidates = [
      json['name'],
      json['name_en'],
      json['name_ar'],
      json['title'],
      json['title_en'],
      json['title_ar'],
    ];

    String name = '';
    for (final c in candidates) {
      final s = c?.toString().trim();
      if (s != null && s.isNotEmpty && s != 'null') {
        name = s;
        break;
      }
    }

    return RequestedLevel(id: id, name: name);
  }
}
