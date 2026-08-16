abstract class ProgressState {
  const ProgressState();
}

class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

class ProgressLoading extends ProgressState {
  final String scope; // 'course' | 'level'
  final int id;
  const ProgressLoading({required this.scope, required this.id});
}

class ProgressSuccess extends ProgressState {
  final String scope;
  final int id;
  /// 0.0 – 100.0
  final double percentage;
  const ProgressSuccess({
    required this.scope,
    required this.id,
    required this.percentage,
  });
}

class ProgressFailure extends ProgressState {
  final String scope;
  final int id;
  final String message;
  const ProgressFailure({
    required this.scope,
    required this.id,
    required this.message,
  });
}
