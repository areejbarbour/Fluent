import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class LevelService {
  final Dio dio;
  LevelService(this.dio);

  Future<Response> getStudentLevels() async {
    return await dio.get(
      apiGetStudentLevels,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}