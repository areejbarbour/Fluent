// 📁 lib/cubit/student/chat/chat_state.dart

import 'package:fluent/data/models/chat_models.dart';

abstract class ChatState {}

/// الحالة الابتدائية قبل أي تحميل
class ChatInitial extends ChatState {}

/// جاري فحص الجلسة الـ active / تحميل أولي
class ChatBootstrapLoading extends ChatState {}

/// مفيش جلسة active → شاشة اختيار Mode / Topic
class ChatNoActiveSession extends ChatState {
  final List<ChatTopicModel> topics;
  final bool topicsLoading;
  final String? topicsError;

  ChatNoActiveSession({
    this.topics = const [],
    this.topicsLoading = false,
    this.topicsError,
  });

  ChatNoActiveSession copyWith({
    List<ChatTopicModel>? topics,
    bool? topicsLoading,
    String? topicsError,
  }) {
    return ChatNoActiveSession(
      topics: topics ?? this.topics,
      topicsLoading: topicsLoading ?? this.topicsLoading,
      topicsError: topicsError,
    );
  }
}

/// جاري إنشاء جلسة جديدة
class ChatCreatingSession extends ChatState {}

/// جلسة active مفتوحة + الرسائل
class ChatSessionActive extends ChatState {
  final ChatSessionModel session;
  final bool isSending;
  final String? sendError;
  final bool isEnding;

  ChatSessionActive({
    required this.session,
    this.isSending = false,
    this.sendError,
    this.isEnding = false,
  });

  ChatSessionActive copyWith({
    ChatSessionModel? session,
    bool? isSending,
    String? sendError,
    bool? isEnding,
    bool clearSendError = false,
  }) {
    return ChatSessionActive(
      session: session ?? this.session,
      isSending: isSending ?? this.isSending,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
      isEnding: isEnding ?? this.isEnding,
    );
  }
}

/// تم إنهاء الجلسة → عرض الملخص
class ChatSessionEnded extends ChatState {
  final ChatSessionModel session;
  final ChatSessionSummaryModel summary;

  ChatSessionEnded({
    required this.session,
    required this.summary,
  });
}

/// قائمة التاريخ
class ChatHistoryLoading extends ChatState {}

class ChatHistoryLoaded extends ChatState {
  final List<ChatHistoryItem> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  ChatHistoryLoaded({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  ChatHistoryLoaded copyWith({
    List<ChatHistoryItem>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ChatHistoryLoaded(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// تفاصيل جلسة قديمة (من الـ history)
class ChatHistoryDetailLoading extends ChatState {}

class ChatHistoryDetailLoaded extends ChatState {
  final ChatSessionModel session;

  ChatHistoryDetailLoaded(this.session);
}

/// خطأ عام (bootstrap / network ...)
class ChatFailure extends ChatState {
  final String message;
  ChatFailure(this.message);
}
