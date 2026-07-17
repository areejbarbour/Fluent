import 'package:dio/dio.dart';
import '../models/level_model.dart';
import '../services/level_service.dart';

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
        return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'فشل في جلب المستويات'
              : 'فشل في جلب المستويات',
        };
      }
    } on DioException catch (e) {
      print("❌ GetStudentLevels DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ GetStudentLevels Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }
}