import 'package:dio/dio.dart';
import 'package:fluent/helper/api_error_helper.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/services/level_exception_service.dart';

class LevelExceptionRepository {
  final LevelExceptionService levelExceptionService;
  LevelExceptionRepository(this.levelExceptionService);

  Future<Map<String, dynamic>> getByStatus(
    String status, {
    int page = 1,
  }) async {
    try {
      late final Response response;

      switch (status.toLowerCase()) {
        case 'pending':
          response = await levelExceptionService.getPending(page: page);
          break;
        case 'in_review':
          response = await levelExceptionService.getInReview(page: page);
          break;
        case 'rejected':
          response = await levelExceptionService.getRejected(page: page);
          break;
        case 'approved':
          response = await levelExceptionService.getApproved(page: page);
          break;
        default:
          return {'success': false, 'message': 'Unknown status'};
      }

      print(
        "✅ GetLevelExceptions ($status p$page) Status: ${response.statusCode}",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<LevelExceptionModel> list = [];

        if (data is Map && data['data'] is List) {
          list = (data['data'] as List)
              .whereType<Map>()
              .map(
                (e) =>
                    LevelExceptionModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
        } else if (data is List) {
          list = data
              .whereType<Map>()
              .map(
                (e) =>
                    LevelExceptionModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
        }

        Map<String, dynamic>? meta;
        if (data is Map && data['meta'] is Map) {
          meta = Map<String, dynamic>.from(data['meta'] as Map);
        }

        return {
          'success': true,
          'data': list,
          'meta': meta,
          'current_page': meta?['current_page'] ?? page,
          'last_page': meta?['last_page'] ?? 1,
          'per_page': meta?['per_page'] ?? 10,
          'total': meta?['total'] ?? list.length,
        };
      } else {
        final errorData = response.data;
        return ApiErrorHelper.failure(
          errorData,
          'Failed to load exception requests',
        );
      }
    } on DioException catch (e) {
      print("❌ GetLevelExceptions DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(e, 'Something went wrong');
    } catch (e) {
      print("❌ GetLevelExceptions Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getDetails(int id) async {
    try {
      final response = await levelExceptionService.getDetails(id);

      print("✅ GetLevelExceptionDetails Status: ${response.statusCode}");
      print("✅ GetLevelExceptionDetails Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map && data['data'] is Map) {
          return {
            'success': true,
            'data': LevelExceptionModel.fromJson(
              Map<String, dynamic>.from(data['data']),
            ),
          };
        }
        return {'success': false, 'message': 'Unexpected response format'};
      } else {
        final errorData = response.data;
        return ApiErrorHelper.failure(
          errorData,
          'Failed to load request details',
        );
      }
    } on DioException catch (e) {
      print("❌ GetLevelExceptionDetails DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return ApiErrorHelper.fromDio(e, 'Something went wrong');
    } catch (e) {
      print("❌ GetLevelExceptionDetails Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> updateException({
    required int id,
    required String reason,
    List<MultipartFile>? attachments,
  }) async {
    try {
      final response = await levelExceptionService.updateException(
        id: id,
        reason: reason,
        attachments: attachments,
      );

      print("✅ UpdateLevelException Status: ${response.statusCode}");
      print("✅ UpdateLevelException Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map && data['data'] is Map) {
          return {
            'success': true,
            'data': LevelExceptionModel.fromJson(
              Map<String, dynamic>.from(data['data']),
            ),
            'message': 'Request updated successfully',
          };
        }
        return {'success': true, 'message': 'Request updated successfully'};
      } else {
        final errorData = response.data;
        return ApiErrorHelper.failure(errorData, 'Failed to update request');
      }
    } on DioException catch (e) {
      print("❌ UpdateLevelException DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return ApiErrorHelper.fromDio(e, 'Something went wrong');
    } catch (e) {
      print("❌ UpdateLevelException Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> createException({
    required int levelId,
    required String reason,
    List<MultipartFile>? attachments,
  }) async {
    try {
      final response = await levelExceptionService.createException(
        levelId: levelId,
        reason: reason,
        attachments: attachments,
      );

      print("✅ CreateLevelException Status: ${response.statusCode}");
      print("✅ CreateLevelException Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map && data['data'] is Map) {
          return {
            'success': true,
            'data': LevelExceptionModel.fromJson(
              Map<String, dynamic>.from(data['data']),
            ),
            'message': 'Exception request submitted successfully',
          };
        }
        return {
          'success': true,
          'message': 'Exception request submitted successfully',
        };
      } else {
        final errorData = response.data;
        return ApiErrorHelper.failure(errorData, 'Failed to submit request');
      }
    } on DioException catch (e) {
      print("❌ CreateLevelException DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return ApiErrorHelper.fromDio(e, 'Something went wrong');
    } catch (e) {
      print("❌ CreateLevelException Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> deleteException(int id) async {
    try {
      final response = await levelExceptionService.deleteException(id);

      print("✅ DeleteLevelException Status: ${response.statusCode}");
      print("✅ DeleteLevelException Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Request deleted successfully'};
      } else {
        final errorData = response.data;
        return ApiErrorHelper.failure(errorData, 'Failed to delete request');
      }
    } on DioException catch (e) {
      print("❌ DeleteLevelException DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return ApiErrorHelper.fromDio(e, 'Something went wrong');
    } catch (e) {
      print("❌ DeleteLevelException Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// DELETE /api/level-exceptions/{exceptionId}/attachments/{mediaId}
  Future<Map<String, dynamic>> deleteAttachment({
    required int exceptionId,
    required int mediaId,
  }) async {
    if (exceptionId <= 0 || mediaId <= 0) {
      return {
        'success': false,
        'message': 'Invalid exception or attachment id.',
      };
    }

    try {
      final response = await levelExceptionService.deleteAttachment(
        exceptionId: exceptionId,
        mediaId: mediaId,
      );

      print("✅ DeleteAttachment Status: ${response.statusCode}");
      print("✅ DeleteAttachment Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        String message = 'Attachment deleted successfully.';
        final data = response.data;
        if (data is Map && data['message'] is String) {
          message = data['message'] as String;
        } else if (data is String && data.isNotEmpty) {
          message = data;
        }
        return {'success': true, 'message': message};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to delete attachment',
        preferredKeys: const ['level', 'media', 'attachment', 'message'],
      );
    } on DioException catch (e) {
      print("❌ DeleteAttachment DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Something went wrong',
        preferredKeys: const ['level', 'media', 'attachment', 'message'],
      );
    } catch (e) {
      print("❌ DeleteAttachment Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
