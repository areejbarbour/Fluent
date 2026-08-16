import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'package:fluent/cubit/student/levels/level_exception_details_state.dart';

class LevelExceptionDetailsCubit extends SafeCubit<LevelExceptionDetailsState> {
  final LevelExceptionRepository repository;

  LevelExceptionModel? _seed;

  LevelExceptionDetailsCubit(this.repository, {LevelExceptionModel? seed})
    : _seed = seed,
      super(LevelExceptionDetailsInitial());

  Future<void> fetchDetails(int id) async {
    emit(LevelExceptionDetailsLoading());
    print(" [LevelExceptionDetailsCubit] Fetching details for #$id...");

    final result = await repository.getDetails(id);

    if (result['success'] == true) {
      final fromApi = result['data'] as LevelExceptionModel;
      final merged = _mergeWithSeed(fromApi);
      print(" [LevelExceptionDetailsCubit] Details loaded");
      emit(LevelExceptionDetailsSuccess(merged));
    } else {
      if (_seed != null && _seed!.id == id) {
        print(" [LevelExceptionDetailsCubit] API failed — using list seed");
        emit(LevelExceptionDetailsSuccess(_seed!));
        return;
      }
      print(" [LevelExceptionDetailsCubit] Failed: ${result['message']}");
      emit(
        LevelExceptionDetailsFailure(
          result['message']?.toString() ?? 'Failed to load details',
        ),
      );
    }
  }

  LevelExceptionModel _mergeWithSeed(LevelExceptionModel api) {
    final seed = _seed;
    if (seed == null || seed.id != api.id) return api;

    return api.copyWith(
      requestedLevel: api.requestedLevel ?? seed.requestedLevel,
      recommendedLevel: api.recommendedLevel ?? seed.recommendedLevel,
      // Keep richer reason/status from API when present
      reason: (api.reason != null && api.reason!.isNotEmpty)
          ? api.reason
          : seed.reason,
      status: (api.status != null && api.status!.isNotEmpty)
          ? api.status
          : seed.status,
    );
  }

  Future<String?> deleteAttachment({
    required int exceptionId,
    required int mediaId,
  }) async {
    final current = state;
    if (current is! LevelExceptionDetailsSuccess) {
      return 'Details are not loaded yet.';
    }

    if (!current.details.canManageAttachments) {
      return 'This request cannot be updated.';
    }

    if (mediaId <= 0) {
      return 'Invalid attachment.';
    }

    if (current.deletingMediaId != null) {
      return 'Please wait for the current deletion to finish.';
    }

    emit(current.copyWith(deletingMediaId: mediaId));
    print(
      " [LevelExceptionDetailsCubit] Deleting attachment #$mediaId "
      "from exception #$exceptionId...",
    );

    final result = await repository.deleteAttachment(
      exceptionId: exceptionId,
      mediaId: mediaId,
    );

    final after = state;
    if (after is! LevelExceptionDetailsSuccess) {
      return result['success'] == true
          ? null
          : (result['message']?.toString() ?? 'Failed to delete attachment');
    }

    if (result['success'] == true) {
      print(" [LevelExceptionDetailsCubit] Attachment deleted");
      final updatedList = after.details.attachments
          .where((a) => a.id != mediaId)
          .toList();
      final updated = after.details.copyWith(attachments: updatedList);
      _seed = updated;
      emit(LevelExceptionDetailsSuccess(updated));
      return null;
    }

    print(" [LevelExceptionDetailsCubit] Delete failed: ${result['message']}");
    emit(after.copyWith(clearDeleting: true));
    return result['message']?.toString() ?? 'Failed to delete attachment';
  }
}
