import 'package:dio/dio.dart';
import 'package:fluent/data/models/profile_model.dart';
import 'package:fluent/data/services/profile_service.dart';
import 'package:fluent/helper/api_error_helper.dart';

class ProfileRepository {
  final ProfileService profileService;
  ProfileRepository(this.profileService);

  /// Laravel JsonResource may wrap payload in `data`.
  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      final inner = body['data'];
      if (inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      final response = await profileService.getStudentProfile();
      print('✅ GetStudentProfile Status: ${response.statusCode}');
      print('✅ GetStudentProfile Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _unwrap(response.data);
        return {'success': true, 'data': StudentProfileModel.fromJson(map)};
      }
      return ApiErrorHelper.failure(
        response.data,
        'Failed to load student profile',
      );
    } on DioException catch (e) {
      print('❌ GetStudentProfile DioException: ${e.response?.data}');
      return ApiErrorHelper.fromDio(e, 'Failed to load student profile');
    } catch (e) {
      print('❌ GetStudentProfile Unexpected: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> updateStudentProfile({
    String? bio,
    String? imagePath,
  }) async {
    try {
      final formData = FormData();
      if (bio != null) {
        formData.fields.add(MapEntry('bio', bio));
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        final name = imagePath.split(RegExp(r'[\\/]')).last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imagePath, filename: name),
          ),
        );
      }

      final response = await profileService.updateStudentProfile(formData);
      print('✅ UpdateStudentProfile Status: ${response.statusCode}');
      print('✅ UpdateStudentProfile Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _unwrap(response.data);
        return {
          'success': true,
          'data': StudentProfileModel.fromJson(map),
          'message': 'Profile updated successfully',
        };
      }
      return ApiErrorHelper.failure(
        response.data,
        'Failed to update student profile',
      );
    } on DioException catch (e) {
      print('❌ UpdateStudentProfile DioException: ${e.response?.data}');
      return ApiErrorHelper.fromDio(e, 'Failed to update student profile');
    } catch (e) {
      print('❌ UpdateStudentProfile Unexpected: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getTeacherProfile() async {
    try {
      final response = await profileService.getTeacherProfile();
      print('✅ GetTeacherProfile Status: ${response.statusCode}');
      print('✅ GetTeacherProfile Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _unwrap(response.data);
        return {'success': true, 'data': TeacherProfileModel.fromJson(map)};
      }
      return ApiErrorHelper.failure(
        response.data,
        'Failed to load teacher profile',
      );
    } on DioException catch (e) {
      print('❌ GetTeacherProfile DioException: ${e.response?.data}');
      return ApiErrorHelper.fromDio(e, 'Failed to load teacher profile');
    } catch (e) {
      print('❌ GetTeacherProfile Unexpected: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> updateTeacherProfile({
    String? bio,
    String? imagePath,
  }) async {
    try {
      final formData = FormData();
      if (bio != null) {
        formData.fields.add(MapEntry('bio', bio));
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        final name = imagePath.split(RegExp(r'[\\/]')).last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imagePath, filename: name),
          ),
        );
      }

      final response = await profileService.updateTeacherProfile(formData);
      print('✅ UpdateTeacherProfile Status: ${response.statusCode}');
      print('✅ UpdateTeacherProfile Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _unwrap(response.data);
        return {
          'success': true,
          'data': TeacherProfileModel.fromJson(map),
          'message': 'Profile updated successfully',
        };
      }
      return ApiErrorHelper.failure(
        response.data,
        'Failed to update teacher profile',
      );
    } on DioException catch (e) {
      print('❌ UpdateTeacherProfile DioException: ${e.response?.data}');
      return ApiErrorHelper.fromDio(e, 'Failed to update teacher profile');
    } catch (e) {
      print('❌ UpdateTeacherProfile Unexpected: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getWeeklyActivity() async {
    try {
      final response = await profileService.getWeeklyActivity();
      print('✅ GetWeeklyActivity Status: ${response.statusCode}');
      print('✅ GetWeeklyActivity Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        final Map<String, dynamic> map;
        if (body is Map<String, dynamic>) {
          map = body;
        } else if (body is Map) {
          map = Map<String, dynamic>.from(body);
        } else {
          map = <String, dynamic>{};
        }
        return {'success': true, 'data': WeeklyActivityModel.fromJson(map)};
      }
      return ApiErrorHelper.failure(
        response.data,
        'Failed to load weekly activity',
      );
    } on DioException catch (e) {
      print('❌ GetWeeklyActivity DioException: ${e.response?.data}');
      return ApiErrorHelper.fromDio(e, 'Failed to load weekly activity');
    } catch (e) {
      print('❌ GetWeeklyActivity Unexpected: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
