import 'package:fluent/data/models/level_exception_model.dart';

abstract class LevelExceptionDetailsState {}

class LevelExceptionDetailsInitial extends LevelExceptionDetailsState {}

class LevelExceptionDetailsLoading extends LevelExceptionDetailsState {}

class LevelExceptionDetailsSuccess extends LevelExceptionDetailsState {
  final LevelExceptionModel details;

  final int? deletingMediaId;

  LevelExceptionDetailsSuccess(this.details, {this.deletingMediaId});

  bool get isDeleting => deletingMediaId != null;

  LevelExceptionDetailsSuccess copyWith({
    LevelExceptionModel? details,
    int? deletingMediaId,
    bool clearDeleting = false,
  }) {
    return LevelExceptionDetailsSuccess(
      details ?? this.details,
      deletingMediaId: clearDeleting
          ? null
          : (deletingMediaId ?? this.deletingMediaId),
    );
  }
}

class LevelExceptionDetailsFailure extends LevelExceptionDetailsState {
  final String message;
  LevelExceptionDetailsFailure(this.message);
}
