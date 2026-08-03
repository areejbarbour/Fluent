import 'package:dio/dio.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/services/level_exception_service.dart';

class LevelExceptionRepository {
  final LevelExceptionService levelExceptionService;
  LevelExceptionRepository(this.levelExceptionService);

  Future<Map<String, dynamic>> getByStatus(String status) async {
    try {
      late final Response response;

      switch (status.toLowerCase()) {
        case 'pending':
          response = await levelExceptionService.getPending();
          break;
        case 'rejected':
          response = await levelExceptionService.getRejected();
          break;
        case 'approved':
          response = await levelExceptionService.getApproved();
          break;
        default:
          return {'success': false, 'message': 'حالة غير معروفة'};
      }

      print("✅ GetLevelExceptions ($status) Status: ${response.statusCode}");
      print("✅ GetLevelExceptions ($status) Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<LevelExceptionModel> list = [];

        if (data is Map && data['data'] is List) {
          list = (data['data'] as List)
              .whereType<Map>()
              .map((e) => LevelExceptionModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
        } else if (data is List) {
          list = data
              .whereType<Map>()
              .map((e) => LevelExceptionModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
        }

        return {'success': true, 'data': list};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'فشل في جلب طلبات الاستثناء'
              : 'فشل في جلب طلبات الاستثناء',
        };
      }
    } on DioException catch (e) {
      print("❌ GetLevelExceptions DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ GetLevelExceptions Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
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
      return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
    } else {
      final errorData = response.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'فشل في جلب تفاصيل الطلب'
            : 'فشل في جلب تفاصيل الطلب',
      };
    }
  } on DioException catch (e) {
    print("❌ GetLevelExceptionDetails DioException: ${e.response?.data}");
    final errorData = e.response?.data;
    return {
      'success': false,
      'message': errorData is Map
          ? errorData['message'] ?? 'حدث خطأ ما'
          : e.message ?? 'حدث خطأ ما',
    };
  } catch (e) {
    print("❌ GetLevelExceptionDetails Unexpected error: $e");
    return {'success': false, 'message': 'حدث خطأ غير متوقع'};
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
          'message': 'تم تحديث الطلب بنجاح',
        };
      }
      return {'success': true, 'message': 'تم تحديث الطلب بنجاح'};
    } else {
      final errorData = response.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'فشل في تحديث الطلب'
            : 'فشل في تحديث الطلب',
      };
    }
  } on DioException catch (e) {
    print("❌ UpdateLevelException DioException: ${e.response?.data}");
    final errorData = e.response?.data;
    return {
      'success': false,
      'message': errorData is Map
          ? errorData['message'] ?? 'حدث خطأ ما'
          : e.message ?? 'حدث خطأ ما',
    };
  } catch (e) {
    print("❌ UpdateLevelException Unexpected error: $e");
    return {'success': false, 'message': 'حدث خطأ غير متوقع'};
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
          'message': 'تم إرسال طلب الاستثناء بنجاح',
        };
      }
      return {'success': true, 'message': 'تم إرسال طلب الاستثناء بنجاح'};
    } else {
      final errorData = response.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'فشل في إرسال الطلب'
            : 'فشل في إرسال الطلب',
      };
    }
  } on DioException catch (e) {
    print("❌ CreateLevelException DioException: ${e.response?.data}");
    final errorData = e.response?.data;
    return {
      'success': false,
      'message': errorData is Map
          ? errorData['message'] ?? 'حدث خطأ ما'
          : e.message ?? 'حدث خطأ ما',
    };
  } catch (e) {
    print("❌ CreateLevelException Unexpected error: $e");
    return {'success': false, 'message': 'حدث خطأ غير متوقع'};
  }
}

Future<Map<String, dynamic>> deleteException(int id) async {
  try {
    final response = await levelExceptionService.deleteException(id);

    print("✅ DeleteLevelException Status: ${response.statusCode}");
    print("✅ DeleteLevelException Data: ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'message': 'تم حذف الطلب بنجاح',
      };
    } else {
      final errorData = response.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'فشل في حذف الطلب'
            : 'فشل في حذف الطلب',
      };
    }
  } on DioException catch (e) {
    print("❌ DeleteLevelException DioException: ${e.response?.data}");
    final errorData = e.response?.data;
    return {
      'success': false,
      'message': errorData is Map
          ? errorData['message'] ?? 'حدث خطأ ما'
          : e.message ?? 'حدث خطأ ما',
    };
  } catch (e) {
    print("❌ DeleteLevelException Unexpected error: $e");
    return {'success': false, 'message': 'حدث خطأ غير متوقع'};
  }
}
}