class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String type;
  final bool isRead;
  final String? readAt;
  final String? createdAt;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.data = const {},
    required this.type,
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedData = {};
    final rawData = json['data'];
    if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    }

    final isReadRaw = json['is_read'] ?? json['read'];
    final isRead =
        isReadRaw == true ||
        isReadRaw == 1 ||
        isReadRaw?.toString().toLowerCase() == 'true';

    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: parsedData,
      type: json['type']?.toString() ?? 'general',
      isRead: isRead,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'type': type,
      'is_read': isRead,
      'read_at': readAt,
      'created_at': createdAt,
    };
  }

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    String? type,
    bool? isRead,
    String? readAt,
    String? createdAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

 
  static const String typeTopicPublished = 'topic-published';
  static const String typePodcastCreated = 'podcast-created';
  static const String typeLessonOpened = 'lesson-opened';
  static const String typeCourseAssigned = 'course-assigned';
  static const String typeLevelOpened = 'level-opened';
  static const String typeLevelException = 'level-exception';
  static const String typeLevelExceptionApproved = 'level-exception-approved';
  static const String typeLevelExceptionReject = 'level-exception-reject';
  static const String typeContentDependencyChange = 'content_dependency_change';
  static const String typeDeleteLesson = 'delete_lesson';
  static const String typeGeneral = 'general';

 
  static const String typeContentApproved = 'content-approved';
  static const String typeContentChangesRequested = 'content-changes-requested';
  static const String typeContentPublished = 'content-published';
}


class UnreadCountResult {
  final int count;

  UnreadCountResult({required this.count});

  factory UnreadCountResult.fromJson(Map<String, dynamic> json) {
    final raw =
        json['number of unread notification'] ??
        json['count'] ??
        json['unread_count'] ??
        0;
    final parsed = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    return UnreadCountResult(count: parsed);
  }
}
