import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'level_exception_create_state.dart';


class LevelExceptionCreateCubit extends Cubit<LevelExceptionCreateState> {
  final LevelExceptionRepository repository;

  LevelExceptionCreateCubit(this.repository)
      : super(LevelExceptionCreateInitial());

  Future<void> create({
    required int levelId,
    required String reason,
    List<MultipartFile>? attachments,
  }) async {
    emit(LevelExceptionCreateLoading());
    print("🟡 [LevelExceptionCreateCubit] Creating exception for level #$levelId...");

    final result = await repository.createException(
      levelId: levelId,
      reason: reason,
      attachments: attachments,
    );

    if (result['success'] == true) {
      print("🎉 [LevelExceptionCreateCubit] Created successfully");
      emit(LevelExceptionCreateSuccess(
        data: result['data'],
        message: result['message'] ?? 'تم إرسال الطلب بنجاح',
      ));
    } else {
      print("❌ [LevelExceptionCreateCubit] Failed: ${result['message']}");
      emit(LevelExceptionCreateFailure(
          result['message'] ?? 'فشل إرسال الطلب'));
    }
  }

  void reset() => emit(LevelExceptionCreateInitial());
}