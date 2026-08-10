import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class PaymentService {
  final Dio dio;
  PaymentService(this.dio);

  Future<Response> createIntent(int id) async {
    return await dio.post(
      apiCreatePaymentIntent(id),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getStatus(String paymentIntentId) async {
    return await dio.get(
      apiPaymentStatus(paymentIntentId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}