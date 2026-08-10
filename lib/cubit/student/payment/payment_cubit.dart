import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/payment_repository.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository repository;

  PaymentCubit(this.repository) : super(PaymentInitial());

  Future<void> createIntent(int id) async {
    emit(PaymentLoading());
    print(" [PaymentCubit] Creating payment intent for #$id...");

    final result = await repository.createIntent(id);

    if (result['success'] == true) {
      print(" [PaymentCubit] Intent created");
      emit(PaymentIntentSuccess(result['data']));
    } else {
      print(" [PaymentCubit] Failed: ${result['message']}");
      emit(PaymentFailure(result['message'] ?? 'Failed to create payment'));
    }
  }

  Future<void> checkStatus(String paymentIntentId) async {
    emit(PaymentLoading());
    print(" [PaymentCubit] Checking status for $paymentIntentId...");

    final result = await repository.getStatus(paymentIntentId);

    if (result['success'] == true) {
      print(" [PaymentCubit] Status loaded");
      emit(PaymentStatusSuccess(result['data']));
    } else {
      print(" [PaymentCubit] Failed: ${result['message']}");
      emit(PaymentFailure(result['message'] ?? 'Failed to get payment status'));
    }
  }

  void reset() => emit(PaymentInitial());
}