// 📁 lib/data/models/chat_models.dart
// مطابق 100% لهيكل الباك (ChatSession, ChatMessage, ChatCorrection, ChatSessionSummary, ChatTopic)

class ChatTopicModel {
  final int id;
  final String title;
  final String? description;
  final int? levelId;

  ChatTopicModel({
    required this.id,
    required this.title,
    this.description,
    this.levelId,
  });

  factory ChatTopicModel.fromJson(Map<String, dynamic> json) {
    return ChatTopicModel(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      levelId: json['level_id'] as int?,
    );
  }
}

class ChatCorrectionModel {
  final int id;
  final String errorType;
  final String originalFragment;
  final String correctedFragment;
  final String explanation;

  ChatCorrectionModel({
    required this.id,
    required this.errorType,
    required this.originalFragment,
    required this.correctedFragment,
    required this.explanation,
  });

  factory ChatCorrectionModel.fromJson(Map<String, dynamic> json) {
    return ChatCorrectionModel(
      id: json['id'] as int? ?? 0,
      errorType: (json['error_type'] ?? 'other').toString(),
      originalFragment: (json['original_fragment'] ?? '').toString(),
      correctedFragment: (json['corrected_fragment'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
    );
  }
}

class ChatMessageModel {
  final int id;
  final String role; // user | assistant
  final String content;
  final String? correctedContent;
  final Map<String, dynamic>? metadata;
  final List<ChatCorrectionModel> corrections;
  final DateTime? createdAt;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.correctedContent,
    this.metadata,
    this.corrections = const [],
    this.createdAt,
  });

  bool get isFromUser => role == 'user';
  bool get isFromAssistant => role == 'assistant';

  String? get topicRelevance {
    final m = metadata;
    if (m == null) return null;
    return m['topic_relevance']?.toString();
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final correctionsRaw = json['corrections'];
    List<ChatCorrectionModel> corrections = [];
    if (correctionsRaw is List) {
      corrections = correctionsRaw
          .whereType<Map>()
          .map((e) => ChatCorrectionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    Map<String, dynamic>? metadata;
    final metaRaw = json['metadata'];
    if (metaRaw is Map) {
      metadata = Map<String, dynamic>.from(metaRaw);
    }

    DateTime? createdAt;
    if (json['created_at'] != null) {
      createdAt = DateTime.tryParse(json['created_at'].toString());
    }

    return ChatMessageModel(
      id: json['id'] as int? ?? 0,
      role: (json['role'] ?? 'user').toString(),
      content: (json['content'] ?? '').toString(),
      correctedContent: json['corrected_content']?.toString(),
      metadata: metadata,
      corrections: corrections,
      createdAt: createdAt,
    );
  }
}

class ChatSessionSummaryModel {
  final int id;
  final String? overallFeedback;
  final List<String> strengths;
  final List<ChatWeaknessItem> weaknesses;
  final String? estimatedLevel;
  final int xpAwarded;

  ChatSessionSummaryModel({
    required this.id,
    this.overallFeedback,
    this.strengths = const [],
    this.weaknesses = const [],
    this.estimatedLevel,
    this.xpAwarded = 0,
  });

  factory ChatSessionSummaryModel.fromJson(Map<String, dynamic> json) {
    List<String> strengths = [];
    final sRaw = json['strengths'];
    if (sRaw is List) {
      strengths = sRaw.map((e) => e.toString()).toList();
    }

    List<ChatWeaknessItem> weaknesses = [];
    final wRaw = json['weaknesses'];
    if (wRaw is List) {
      weaknesses = wRaw.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        return ChatWeaknessItem(
          errorType: (m['error_type'] ?? '').toString(),
          count: (m['count'] is int) ? m['count'] as int : int.tryParse('${m['count']}') ?? 0,
        );
      }).toList();
    }

    return ChatSessionSummaryModel(
      id: json['id'] as int? ?? 0,
      overallFeedback: json['overall_feedback']?.toString(),
      strengths: strengths,
      weaknesses: weaknesses,
      estimatedLevel: json['estimated_level']?.toString(),
      xpAwarded: (json['xp_awarded'] is int)
          ? json['xp_awarded'] as int
          : int.tryParse('${json['xp_awarded']}') ?? 0,
    );
  }
}

class ChatWeaknessItem {
  final String errorType;
  final int count;

  ChatWeaknessItem({required this.errorType, required this.count});
}

class ChatSessionModel {
  final int id;
  final int? userId;
  final int? topicId;
  final String mode; // free_talk | topics
  final String status; // active | ended
  final int? levelIdSnapshot;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final ChatTopicModel? topic;
  final List<ChatMessageModel> messages;
  final ChatSessionSummaryModel? summary;

  ChatSessionModel({
    required this.id,
    this.userId,
    this.topicId,
    required this.mode,
    required this.status,
    this.levelIdSnapshot,
    this.startedAt,
    this.endedAt,
    this.topic,
    this.messages = const [],
    this.summary,
  });

  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
  bool get isFreeTalk => mode == 'free_talk';
  bool get isTopics => mode == 'topics';

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    ChatTopicModel? topic;
    final topicRaw = json['topic'];
    if (topicRaw is Map) {
      topic = ChatTopicModel.fromJson(Map<String, dynamic>.from(topicRaw));
    }

    List<ChatMessageModel> messages = [];
    final messagesRaw = json['messages'];
    if (messagesRaw is List) {
      messages = messagesRaw
          .whereType<Map>()
          .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      // ترتيب زمني تصاعدي (أقدم → أحدث) للعرض
      messages.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return a.createdAt!.compareTo(b.createdAt!);
        }
        return a.id.compareTo(b.id);
      });
    }

    ChatSessionSummaryModel? summary;
    final summaryRaw = json['summary'];
    if (summaryRaw is Map) {
      summary = ChatSessionSummaryModel.fromJson(
        Map<String, dynamic>.from(summaryRaw),
      );
    }

    DateTime? startedAt;
    if (json['started_at'] != null) {
      startedAt = DateTime.tryParse(json['started_at'].toString());
    }
    DateTime? endedAt;
    if (json['ended_at'] != null) {
      endedAt = DateTime.tryParse(json['ended_at'].toString());
    }

    return ChatSessionModel(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      topicId: json['topic_id'] as int?,
      mode: (json['mode'] ?? 'free_talk').toString(),
      status: (json['status'] ?? 'active').toString(),
      levelIdSnapshot: json['level_id_snapshot'] as int?,
      startedAt: startedAt,
      endedAt: endedAt,
      topic: topic,
      messages: messages,
      summary: summary,
    );
  }

  ChatSessionModel copyWith({
    List<ChatMessageModel>? messages,
    String? status,
    ChatSessionSummaryModel? summary,
    DateTime? endedAt,
  }) {
    return ChatSessionModel(
      id: id,
      userId: userId,
      topicId: topicId,
      mode: mode,
      status: status ?? this.status,
      levelIdSnapshot: levelIdSnapshot,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      topic: topic,
      messages: messages ?? this.messages,
      summary: summary ?? this.summary,
    );
  }
}

/// نتيجة إرسال رسالة (مطابق لرد الباك)
class SendMessageResult {
  final ChatMessageModel userMessage;
  final ChatMessageModel assistantMessage;

  SendMessageResult({
    required this.userMessage,
    required this.assistantMessage,
  });
}

/// عنصر في قائمة الـ history (جلسة منتهية بدون رسائل كاملة)
class ChatHistoryItem {
  final ChatSessionModel session;

  ChatHistoryItem(this.session);

  int get id => session.id;
  String get mode => session.mode;
  String? get topicTitle => session.topic?.title;
  DateTime? get startedAt => session.startedAt;
  int get xpAwarded => session.summary?.xpAwarded ?? 0;
  String? get overallFeedback => session.summary?.overallFeedback;
}

/// Pagination للـ history (Laravel paginate)
class ChatHistoryPage {
  final List<ChatHistoryItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  ChatHistoryPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  }) : hasMore = currentPage < lastPage;
}
