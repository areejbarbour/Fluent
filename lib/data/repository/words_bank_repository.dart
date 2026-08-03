import 'package:dio/dio.dart';
import 'package:fluent/data/models/words_bank_model.dart';
import 'package:fluent/data/services/words_bank_service.dart';

class WordsBankRepository {
  final WordsBankService service;
  WordsBankRepository(this.service);

  Future<Map<String, dynamic>> getLearningWords() async {
    try {
      final response = await service.getLearningWords();
      print("✅ GetLearningWords Status: ${response.statusCode}");
      print("✅ GetLearningWords Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<WordsBankItem> list = [];

        if (data is Map && data['data'] is List) {
          list = (data['data'] as List)
              .whereType<Map>()
              .map((e) => WordsBankItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
        } else if (data is List) {
          list = data
              .whereType<Map>()
              .map((e) => WordsBankItem.fromJson(
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
              ? errorData['message'] ?? 'فشل في جلب الكلمات'
              : 'فشل في جلب الكلمات',
        };
      }
    } on DioException catch (e) {
      print("❌ GetLearningWords DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ GetLearningWords Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }
Future<Map<String, dynamic>> getKnowWords() async {
    try {
      final response = await service.getKnowWords();
      print("✅ GetKnowWords Status: ${response.statusCode}");
      print("✅ GetKnowWords Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': _parseList(response.data)};
      }

      final errorData = response.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'فشل في جلب الكلمات'
            : 'فشل في جلب الكلمات',
      };
    } on DioException catch (e) {
      print("❌ GetKnowWords DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ GetKnowWords Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  List<WordsBankItem> _parseList(dynamic data) {
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => WordsBankItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => WordsBankItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}