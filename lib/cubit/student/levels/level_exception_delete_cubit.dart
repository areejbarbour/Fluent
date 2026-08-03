import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'level_exception_delete_state.dart';

class LevelExceptionDeleteCubit extends Cubit<LevelExceptionDeleteState> {
  final LevelExceptionRepository repository;

  LevelExceptionDeleteCubit(this.repository)
      : super(LevelExceptionDeleteInitial());

  Future<void> delete(int id) async {
    emit(LevelExceptionDeleteLoading(id));
    print("🟡 [LevelExceptionDeleteCubit] Deleting exception #$id...");

    final result = await repository.deleteException(id);

    if (result['success'] == true) {
      print("🎉 [LevelExceptionDeleteCubit] Deleted successfully");
      emit(LevelExceptionDeleteSuccess(
        id: id,
        message: result['message'] ?? 'تم الحذف بنجاح',
      ));
    } else {
      print("❌ [LevelExceptionDeleteCubit] Failed: ${result['message']}");
      emit(LevelExceptionDeleteFailure(
          result['message'] ?? 'فشل حذف الطلب'));
    }
  }

  void reset() => emit(LevelExceptionDeleteInitial());
}