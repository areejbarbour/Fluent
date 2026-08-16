import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

/// Thin Dio layer — matches backend ContactUsController@store
class ContactUsService {
  final Dio dio;
  ContactUsService(this.dio);

  Options get _opts => Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      );

  /// POST /api/contact-us  body: { "text": "..." }
  /// Success 201: { "message": "Your message has been sent successfully." }
  /// Validation: text required, string, min:10, max:2000
  Future<Response> store(String text) {
    return dio.post(
      apiContactUs,
      data: {'text': text},
      options: _opts,
    );
  }
}
