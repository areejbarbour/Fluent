import 'package:dio/dio.dart';
import 'package:fluent/data/models/payment_model.dart';
import 'package:fluent/data/services/payment_service.dart';
import 'package:fluent/helper/api_error_helper.dart';

class PaymentRepository {
  final PaymentService service;
  PaymentRepository(this.service);

  static const _keys = ['message', 'error', 'data'];

  Future<Map<String, dynamic>> createIntent(int id) async {
    try {
      final response = await service.createIntent(id);
      print("✅ CreatePaymentIntent Status: ${response.statusCode}");
      print("✅ CreatePaymentIntent Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          return {
            'success': true,
            'data': PaymentIntentModel.fromJson(
              Map<String, dynamic>.from(data),
            ),
          };
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to create payment intent',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ CreatePaymentIntent DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to create payment intent',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ CreatePaymentIntent Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getStatus(String paymentIntentId) async {
    try {
      final response = await service.getStatus(paymentIntentId);
      print("✅ GetPaymentStatus Status: ${response.statusCode}");
      print("✅ GetPaymentStatus Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          return {
            'success': true,
            'data': PaymentStatusModel.fromJson(
              Map<String, dynamic>.from(data),
            ),
          };
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return ApiErrorHelper.failure(
        response.data,
        'Failed to get payment status',
        preferredKeys: _keys,
      );
    } on DioException catch (e) {
      print("❌ GetPaymentStatus DioException: ${e.response?.data}");
      return ApiErrorHelper.fromDio(
        e,
        'Failed to get payment status',
        preferredKeys: _keys,
      );
    } catch (e) {
      print("❌ GetPaymentStatus Unexpected: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}