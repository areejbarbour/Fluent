import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class LevelService {
  final Dio dio;
  LevelService(this.dio);

  Options get _opts => Options(
    headers: {'Accept': 'application/json'},
    validateStatus: (status) => status != null && status < 500,
  );

  Future<Response> getStudentLevels() async {
    return await dio.get(apiGetStudentLevels, options: _opts);
  }

  /// GET /api/placement-test/status
  /// Backend (StudentLevelService@getStatus):
  /// - no completed placement → { action: "take_placement_test", can_retake_placement: false }
  /// - has completed → { action: "show_levels", can_retake_placement: bool, retake_available_at?: string|null }
  Future<Response> getPlacementTestStatus() async {
    return await dio.get(apiPlacementTestStatus, options: _opts);
  }
}
