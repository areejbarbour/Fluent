import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'package:fluent/cubit/student/levels/level_exception_update_state.dart';

class LevelExceptionUpdateCubit extends Cubit<LevelExceptionUpdateState> {
  final LevelExceptionRepository repository;

  LevelExceptionUpdateCubit(this.repository)
      : super(LevelExceptionUpdateInitial());

  Future<void> update({
    required int id,
    required String reason,
    List<MultipartFile>? attachments,
  }) async {
    emit(LevelExceptionUpdateLoading());
    print("🟡 [LevelExceptionUpdateCubit] Updating exception #$id...");

    final result = await repository.updateException(
      id: id,
      reason: reason,
      attachments: attachments,
    );

    if (result['success'] == true) {
      print("🎉 [LevelExceptionUpdateCubit] Updated successfully");
      emit(LevelExceptionUpdateSuccess(
        updated: result['data'],
        message: result['message'] ?? 'تم التحديث بنجاح',
      ));
    } else {
      print("❌ [LevelExceptionUpdateCubit] Failed: ${result['message']}");
      emit(LevelExceptionUpdateFailure(
          result['message'] ?? 'فشل تحديث الطلب'));
    }
  }

  void reset() => emit(LevelExceptionUpdateInitial());
}