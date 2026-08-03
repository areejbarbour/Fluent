import 'package:fluent/data/models/rate_model.dart';

abstract class RateState {
  const RateState();
}

class RateInitial extends RateState {
  const RateInitial();
}

class RateLoading extends RateState {
  /// courseId currently being rated / deleted (for per-card loading UI)
  final int? courseId;
  final bool isDeleting;

  const RateLoading({this.courseId, this.isDeleting = false});
}

class RateSuccess extends RateState {
  final RateModel rate;
  final int courseId;
  final String message;

  const RateSuccess({
    required this.rate,
    required this.courseId,
    this.message = 'Rating saved successfully',
  });
}

class RateDeleted extends RateState {
  final int courseId;
  final int rateId;
  final String message;

  const RateDeleted({
    required this.courseId,
    required this.rateId,
    this.message = 'Rating deleted successfully',
  });
}

class RateFailure extends RateState {
  final String message;
  final Map<String, dynamic>? errors;
  final int? courseId;

  const RateFailure(
    this.message, {
    this.errors,
    this.courseId,
  });
}
