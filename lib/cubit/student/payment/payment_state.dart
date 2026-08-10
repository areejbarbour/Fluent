import 'package:fluent/data/models/payment_model.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentIntentSuccess extends PaymentState {
  final PaymentIntentModel intent;
  PaymentIntentSuccess(this.intent);
}

class PaymentStatusSuccess extends PaymentState {
  final PaymentStatusModel status;
  PaymentStatusSuccess(this.status);
}

class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);
}