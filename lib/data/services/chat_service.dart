// 📁 lib/data/services/chat_service.dart
// مطابق 100% لـ routes/api.php في الباك

import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class ChatService {
  final Dio dio;
  ChatService(this.dio);

  /// GET /api/chat/sessions/active
  Future<Response> getActiveSession() async {
    return await dio.get(
      apiChatActiveSession,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// POST /api/chat/sessions
  /// body: { mode: free_talk|topics, topic_id?: int }
  Future<Response> createSession({
    required String mode,
    int? topicId,
  }) async {
    final body = <String, dynamic>{
      'mode': mode,
      if (topicId != null) 'topic_id': topicId,
    };
    return await dio.post(
      apiChatSessions,
      data: body,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// POST /api/chat/sessions/{session}/messages
  /// body: { message: string }
  Future<Response> sendMessage({
    required int sessionId,
    required String message,
  }) async {
    return await dio.post(
      apiChatSendMessage(sessionId),
      data: {'message': message},
      options: Options(
        headers: {'Accept': 'application/json'},
        // Gemini قد يأخذ وقت أطول
        receiveTimeout: const Duration(seconds: 60),
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// POST /api/chat/sessions/{session}/end
  Future<Response> endSession(int sessionId) async {
    return await dio.post(
      apiChatEndSession(sessionId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// GET /api/chat/sessions/history?page=1
  Future<Response> getHistory({int page = 1}) async {
    return await dio.get(
      apiChatHistory,
      queryParameters: {'page': page},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// GET /api/chat/sessions/{session}
  Future<Response> getSessionDetails(int sessionId) async {
    return await dio.get(
      apiChatSessionDetails(sessionId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// GET /api/chat/topics
  Future<Response> getAvailableTopics() async {
    return await dio.get(
      apiChatTopics,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
