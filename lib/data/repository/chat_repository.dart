
import 'package:dio/dio.dart';
import 'package:fluent/data/models/chat_models.dart';
import 'package:fluent/data/services/chat_service.dart';
import 'package:fluent/helper/api_error_helper.dart';

class ChatRepository {
  final ChatService service;
  ChatRepository(this.service);

  static const _keys = ['message', 'error', 'data', 'mode', 'topic_id'];

  
  Future<Map<String, dynamic>> getActiveSession() async {
    try {
      final response = await service.getActiveSession();
      print("✅ GetActiveSession Status: ${response.statusCode}");
      print("✅ GetActiveSession Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          final sessionRaw = data['session'];
          if (sessionRaw == null) {
            return {'success': true, 'data': null};
          }
          if (sessionRaw is Map) {
            return {
              'success': true,
              'data': ChatSessionModel.fromJson(
                Map<String, dynamic>.from(sessionRaw),
              ),
            };
          }
        }
        return {'success': true, 'data': null};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to load active session',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ GetActiveSession DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to load active session',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ GetActiveSession Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// POST /chat/sessions
  Future<Map<String, dynamic>> createSession({
    required String mode,
    int? topicId,
  }) async {
    try {
      final response = await service.createSession(mode: mode, topicId: topicId);
      print("✅ CreateSession Status: ${response.statusCode}");
      print("✅ CreateSession Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        Map<String, dynamic>? payload;
        if (data is Map && data['session'] is Map) {
          payload = Map<String, dynamic>.from(data['session'] as Map);
        } else if (data is Map) {
          payload = Map<String, dynamic>.from(data);
        }
        if (payload != null) {
          return {
            'success': true,
            'data': ChatSessionModel.fromJson(payload),
          };
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to create session',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ CreateSession DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to create session',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ CreateSession Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

 
  Future<Map<String, dynamic>> sendMessage({
    required int sessionId,
    required String message,
  }) async {
    try {
      final response = await service.sendMessage(
        sessionId: sessionId,
        message: message,
      );
      print("✅ SendMessage Status: ${response.statusCode}");
      print("✅ SendMessage Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          final userRaw = data['user_message'];
          final assistantRaw = data['message'];
          if (userRaw is Map && assistantRaw is Map) {
            return {
              'success': true,
              'data': SendMessageResult(
                userMessage: ChatMessageModel.fromJson(
                  Map<String, dynamic>.from(userRaw),
                ),
                assistantMessage: ChatMessageModel.fromJson(
                  Map<String, dynamic>.from(assistantRaw),
                ),
              ),
            };
          }
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to send message',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ SendMessage DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to send message',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ SendMessage Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> endSession(int sessionId) async {
    try {
      final response = await service.endSession(sessionId);
      print("✅ EndSession Status: ${response.statusCode}");
      print("✅ EndSession Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        Map<String, dynamic>? payload;
        if (data is Map && data['summary'] is Map) {
          payload = Map<String, dynamic>.from(data['summary'] as Map);
        } else if (data is Map) {
          payload = Map<String, dynamic>.from(data);
        }
        if (payload != null) {
          return {
            'success': true,
            'data': ChatSessionSummaryModel.fromJson(payload),
          };
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to end session',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ EndSession DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to end session',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ EndSession Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getHistory({int page = 1}) async {
    try {
      final response = await service.getHistory(page: page);
      print("✅ GetHistory Status: ${response.statusCode}");
      print("✅ GetHistory Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          final listRaw = data['data'];
          List<ChatHistoryItem> items = [];
          if (listRaw is List) {
            items = listRaw
                .whereType<Map>()
                .map((e) => ChatHistoryItem(
                      ChatSessionModel.fromJson(
                        Map<String, dynamic>.from(e),
                      ),
                    ))
                .toList();
          }

          final currentPage = data['current_page'] is int
              ? data['current_page'] as int
              : int.tryParse('${data['current_page']}') ?? 1;
          final lastPage = data['last_page'] is int
              ? data['last_page'] as int
              : int.tryParse('${data['last_page']}') ?? 1;
          final total = data['total'] is int
              ? data['total'] as int
              : int.tryParse('${data['total']}') ?? items.length;

          return {
            'success': true,
            'data': ChatHistoryPage(
              items: items,
              currentPage: currentPage,
              lastPage: lastPage,
              total: total,
            ),
          };
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to load history',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ GetHistory DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to load history',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ GetHistory Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getSessionDetails(int sessionId) async {
    try {
      final response = await service.getSessionDetails(sessionId);
      print("✅ GetSessionDetails Status: ${response.statusCode}");
      print("✅ GetSessionDetails Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        Map<String, dynamic>? payload;
        if (data is Map && data['id'] != null) {
          payload = Map<String, dynamic>.from(data);
        } else if (data is Map && data['session'] is Map) {
          payload = Map<String, dynamic>.from(data['session'] as Map);
        }
        if (payload != null) {
          return {
            'success': true,
            'data': ChatSessionModel.fromJson(payload),
          };
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to load session details',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ GetSessionDetails DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to load session details',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ GetSessionDetails Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getAvailableTopics() async {
    try {
      final response = await service.getAvailableTopics();
      print("✅ GetChatTopics Status: ${response.statusCode}");
      print("✅ GetChatTopics Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<ChatTopicModel> list = [];
        if (data is Map && data['topics'] is List) {
          list = (data['topics'] as List)
              .whereType<Map>()
              .map((e) =>
                  ChatTopicModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (data is List) {
          list = data
              .whereType<Map>()
              .map((e) =>
                  ChatTopicModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        return {'success': true, 'data': list};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to load topics',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ GetChatTopics DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to load topics',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ GetChatTopics Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
