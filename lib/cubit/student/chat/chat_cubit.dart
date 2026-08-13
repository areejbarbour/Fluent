// 📁 lib/cubit/student/chat/chat_cubit.dart
// Flow مطابق 100% للباك:
// 1) bootstrap → GET /active
// 2) لو null → اختيار mode/topic → POST /sessions
// 3) إرسال رسائل → POST /sessions/{id}/messages
// 4) إنهاء → POST /sessions/{id}/end → ملخص + XP
// 5) history + تفاصيل جلسة قديمة
// 6) يمنع الإرسال إذا status ≠ active
// 7) يمنع إنشاء جلسة جديدة إذا فيه active (حماية فرونت)

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/chat_models.dart';
import 'package:fluent/data/repository/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;

  ChatCubit(this.repository) : super(ChatInitial());

  // ─────────────────────────────────────────────
  // Bootstrap: أول ما يفتح شاشة الشات
  // ─────────────────────────────────────────────
  Future<void> bootstrap() async {
    emit(ChatBootstrapLoading());
    print("🔍 [ChatCubit] Bootstrap — checking active session...");

    final result = await repository.getActiveSession();

    if (result['success'] != true) {
      emit(ChatFailure(result['message'] ?? 'Failed to load chat'));
      return;
    }

    final ChatSessionModel? session = result['data'] as ChatSessionModel?;

    if (session != null && session.isActive) {
      print("✅ [ChatCubit] Active session found id=${session.id}");
      emit(ChatSessionActive(session: session));
    } else {
      print("ℹ️ [ChatCubit] No active session — show mode picker");
      emit(ChatNoActiveSession());
      // حمّل المواضيع في الخلفية
      loadTopics();
    }
  }

  // ─────────────────────────────────────────────
  // تحميل المواضيع المتاحة (لمستويات الطالب)
  // ─────────────────────────────────────────────
  Future<void> loadTopics() async {
    final current = state;
    if (current is ChatNoActiveSession) {
      emit(current.copyWith(topicsLoading: true, topicsError: null));
    }

    final result = await repository.getAvailableTopics();

    if (state is! ChatNoActiveSession) return; // state تغيّر أثناء الانتظار

    final noActive = state as ChatNoActiveSession;

    if (result['success'] == true) {
      final topics = result['data'] as List<ChatTopicModel>;
      emit(noActive.copyWith(topics: topics, topicsLoading: false));
    } else {
      emit(
        noActive.copyWith(
          topicsLoading: false,
          topicsError: result['message'] ?? 'Failed to load topics',
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // إنشاء جلسة جديدة
  // mode: free_talk | topics
  // ─────────────────────────────────────────────
  Future<void> startSession({required String mode, int? topicId}) async {
    if (state is ChatSessionActive) {
      print("⚠️ [ChatCubit] Already has active session — ignore start");
      return;
    }

    if (mode == 'topics' && topicId == null) {
      emit(ChatFailure('Please select a topic'));
      return;
    }

    emit(ChatCreatingSession());
    print("🚀 [ChatCubit] Creating session mode=$mode topicId=$topicId");

    final result = await repository.createSession(mode: mode, topicId: topicId);

    if (result['success'] == true) {
      final session = result['data'] as ChatSessionModel;
      print("✅ [ChatCubit] Session created id=${session.id}");
      emit(ChatSessionActive(session: session));
    } else {
      emit(ChatFailure(result['message'] ?? 'Failed to create session'));
      // رجّع لشاشة الاختيار
      emit(ChatNoActiveSession());
      loadTopics();
    }
  }

  // ─────────────────────────────────────────────
  // إرسال رسالة — Optimistic UI:
  // الرسالة تظهر فوراً، وبعدين ينضاف رد الـ AI
  // ─────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    final current = state;
    if (current is! ChatSessionActive) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > 1000) {
      emit(current.copyWith(sendError: 'Message is too long (max 1000)'));
      return;
    }

    if (!current.session.isActive) {
      emit(current.copyWith(sendError: 'This session has ended'));
      return;
    }

    if (current.isSending) return;

    // رسالة مؤقتة تظهر فوراً في الشات
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimisticUser = ChatMessageModel(
      id: tempId,
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );

    final withOptimistic = current.session.copyWith(
      messages: [...current.session.messages, optimisticUser],
    );

    emit(
      current.copyWith(
        session: withOptimistic,
        isSending: true,
        clearSendError: true,
      ),
    );

    final result = await repository.sendMessage(
      sessionId: current.session.id,
      message: trimmed,
    );

    if (state is! ChatSessionActive) return;
    final active = state as ChatSessionActive;

    // شيل الرسالة المؤقتة من القائمة الحالية
    final withoutTemp = active.session.messages
        .where((m) => m.id != tempId)
        .toList();

    if (result['success'] == true) {
      final sendResult = result['data'] as SendMessageResult;
      final updatedMessages = [
        ...withoutTemp,
        sendResult.userMessage,
        sendResult.assistantMessage,
      ];
      final updatedSession = active.session.copyWith(messages: updatedMessages);

      emit(
        active.copyWith(
          session: updatedSession,
          isSending: false,
          clearSendError: true,
        ),
      );
    } else {
      // فشل الإرسال → رجّع القائمة بدون الرسالة المؤقتة
      emit(
        active.copyWith(
          session: active.session.copyWith(messages: withoutTemp),
          isSending: false,
          sendError: result['message'] ?? 'Failed to send message',
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // إنهاء الجلسة
  // ─────────────────────────────────────────────
  Future<void> endSession() async {
    final current = state;
    if (current is! ChatSessionActive) return;
    if (current.isEnding) return;

    emit(current.copyWith(isEnding: true));

    final result = await repository.endSession(current.session.id);

    if (result['success'] == true) {
      final summary = result['data'] as ChatSessionSummaryModel;
      final endedSession = current.session.copyWith(
        status: 'ended',
        summary: summary,
        endedAt: DateTime.now(),
      );
      print("✅ [ChatCubit] Session ended — XP=${summary.xpAwarded}");
      emit(ChatSessionEnded(session: endedSession, summary: summary));
    } else {
      // رجّع للحالة النشطة مع خطأ
      if (state is ChatSessionActive) {
        emit(
          (state as ChatSessionActive).copyWith(
            isEnding: false,
            sendError: result['message'] ?? 'Failed to end session',
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // الرجوع لشاشة البداية بعد الملخص (جلسة جديدة)
  // ─────────────────────────────────────────────
  void startNewAfterSummary() {
    emit(ChatNoActiveSession());
    loadTopics();
  }

  // ─────────────────────────────────────────────
  // History
  // ─────────────────────────────────────────────
  Future<void> loadHistory({bool refresh = true}) async {
    if (refresh) {
      emit(ChatHistoryLoading());
    }

    final result = await repository.getHistory(page: 1);

    if (result['success'] == true) {
      final page = result['data'] as ChatHistoryPage;
      emit(
        ChatHistoryLoaded(
          items: page.items,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
        ),
      );
    } else {
      emit(ChatFailure(result['message'] ?? 'Failed to load history'));
    }
  }

  Future<void> loadMoreHistory() async {
    final current = state;
    if (current is! ChatHistoryLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await repository.getHistory(page: nextPage);

    if (state is! ChatHistoryLoaded) return;
    final loaded = state as ChatHistoryLoaded;

    if (result['success'] == true) {
      final page = result['data'] as ChatHistoryPage;
      emit(
        loaded.copyWith(
          items: [...loaded.items, ...page.items],
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } else {
      emit(loaded.copyWith(isLoadingMore: false));
    }
  }

  // ─────────────────────────────────────────────
  // تفاصيل جلسة قديمة
  // ─────────────────────────────────────────────
  Future<void> openHistorySession(int sessionId) async {
    emit(ChatHistoryDetailLoading());

    final result = await repository.getSessionDetails(sessionId);

    if (result['success'] == true) {
      final session = result['data'] as ChatSessionModel;
      emit(ChatHistoryDetailLoaded(session));
    } else {
      emit(ChatFailure(result['message'] ?? 'Failed to load session'));
    }
  }

  /// الرجوع من تفاصيل جلسة قديمة لقائمة الـ history
  Future<void> backToHistory() async {
    await loadHistory(refresh: true);
  }
}
