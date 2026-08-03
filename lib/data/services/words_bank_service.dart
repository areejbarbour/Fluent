import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class WordsBankService {
  final Dio dio;
  WordsBankService(this.dio);

  Future<Response> getLearningWords() async {
    return await dio.get(
      apiWordsBankLearning,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getKnowWords() async {
    return await dio.get(
      apiWordsBankKnow,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}