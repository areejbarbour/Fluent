import 'package:dio/dio.dart';
import 'package:fluent/helper/api_error_helper.dart';
import '../models/level_model.dart';
import 'package:fluent/data/services/level_service.dart';

class LevelRepository {
  final LevelService levelService;
  LevelRepository(this.levelService);

  Future<Map<String, dynamic>> getStudentLevels() async {
    try {
      final response = await levelService.getStudentLevels();
      print("✅ GetStudentLevels Status: ${response.statusCode}");
      print("✅ GetStudentLevels Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {'success': true, 'data': StudentLevelsModel.fromJson(data)};
        }
        return {'success': false, 'message': 'Unexpected response format'};
      } else {
        final errorData = response.data;
        return ApiErrorHelper.failure(errorData, 'Failed to load levels');
      }
    } on DioException catch (e) {
      print("❌ GetStudentLevels DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(e, 'Something went wrong');
    } catch (e) {
      print("❌ GetStudentLevels Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getPlacementTestStatus() async {
    try {
      final response = await levelService.getPlacementTestStatus();
      print("✅ PlacementTestStatus Status: ${response.statusCode}");
      print("✅ PlacementTestStatus Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          return {
            'success': true,
            'data': PlacementTestStatusModel.fromJson(
              Map<String, dynamic>.from(data),
            ),
          };
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }
      return ApiErrorHelper.failure(
        response.data,
        'Failed to load placement status',
      );
    } on DioException catch (e) {
      print("❌ PlacementTestStatus DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(e, 'Something went wrong');
    } catch (e) {
      print("❌ PlacementTestStatus Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
