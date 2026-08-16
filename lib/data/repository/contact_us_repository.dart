import 'package:dio/dio.dart';
import 'package:fluent/data/services/contact_us_service.dart';
import 'package:fluent/helper/api_error_helper.dart';

class ContactUsRepository {
  final ContactUsService contactUsService;
  ContactUsRepository(this.contactUsService);

  Future<Map<String, dynamic>> sendMessage(String text) async {
    try {
      final res = await contactUsService.store(text);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data;
        final msg = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Your message has been sent successfully.';
        return {'success': true, 'message': msg};
      }
      return ApiErrorHelper.failure(
        res.data,
        'Failed to send message',
        preferredKeys: const ['text'],
      );
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(
        e,
        'Failed to send message',
        preferredKeys: const ['text'],
      );
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
