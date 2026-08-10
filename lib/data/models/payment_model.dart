class PaymentIntentModel {
  final String clientSecret;
  final String paymentIntentId;

  PaymentIntentModel({
    required this.clientSecret,
    required this.paymentIntentId,
  });

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    return PaymentIntentModel(
      clientSecret: json['clientSecret']?.toString() ??
          json['client_secret']?.toString() ??
          '',
      paymentIntentId: json['paymentIntentId']?.toString() ??
          json['payment_intent_id']?.toString() ??
          '',
    );
  }
}

class PaymentStatusModel {
  final String status;

  PaymentStatusModel({required this.status});

  factory PaymentStatusModel.fromJson(Map<String, dynamic> json) {
    return PaymentStatusModel(
      status: json['status']?.toString() ?? 'unknown',
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSucceeded =>
      status.toLowerCase() == 'succeeded' ||
      status.toLowerCase() == 'paid' ||
      status.toLowerCase() == 'success';
  bool get isFailed =>
      status.toLowerCase() == 'failed' ||
      status.toLowerCase() == 'canceled';
}