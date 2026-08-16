import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'level_exception_create_state.dart';

class LevelExceptionCreateCubit extends SafeCubit<LevelExceptionCreateState> {
  final LevelExceptionRepository repository;

  LevelExceptionCreateCubit(this.repository)
    : super(LevelExceptionCreateInitial());

  Future<void> create({
    required int levelId,
    required String reason,
    List<MultipartFile>? attachments,
  }) async {
    emit(LevelExceptionCreateLoading());
    print(
      " [LevelExceptionCreateCubit] Creating exception for level #$levelId...",
    );

    final result = await repository.createException(
      levelId: levelId,
      reason: reason,
      attachments: attachments,
    );

    if (result['success'] == true) {
      print(" [LevelExceptionCreateCubit] Created successfully");
      emit(
        LevelExceptionCreateSuccess(
          data: result['data'],
          message: result['message'] ?? 'Request submitted successfully',
        ),
      );
    } else {
      print(" [LevelExceptionCreateCubit] Failed: ${result['message']}");
      emit(
        LevelExceptionCreateFailure(
          result['message'] ?? 'Failed to submit request',
        ),
      );
    }
  }

  void reset() => emit(LevelExceptionCreateInitial());
}
