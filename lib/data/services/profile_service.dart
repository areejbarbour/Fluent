import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class ProfileService {
  final Dio dio;
  ProfileService(this.dio);

  Options get _opts => Options(
    headers: {'Accept': 'application/json'},
    validateStatus: (status) => status != null && status < 500,
  );

  Future<Response> getStudentProfile() async {
    return await dio.get(apiStudentProfile, options: _opts);
  }

  Future<Response> updateStudentProfile(FormData formData) async {
    return await dio.post(apiStudentProfile, data: formData, options: _opts);
  }

  /// GET /api/student/weeklyActivity
  Future<Response> getWeeklyActivity() async {
    return await dio.get(apiStudentWeeklyActivity, options: _opts);
  }

  Future<Response> getTeacherProfile() async {
    return await dio.get(apiTeacherProfile, options: _opts);
  }

  Future<Response> updateTeacherProfile(FormData formData) async {
    return await dio.post(apiTeacherProfile, data: formData, options: _opts);
  }
}
