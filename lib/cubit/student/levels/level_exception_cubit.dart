import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'level_exception_state.dart';

class LevelExceptionCubit extends Cubit<LevelExceptionState> {
  final LevelExceptionRepository repository;

  LevelExceptionCubit(this.repository) : super(LevelExceptionInitial());

  Future<void> fetchByStatus(String status) async {
    emit(LevelExceptionLoading());
    print("🟡 [LevelExceptionCubit] Fetching $status exceptions...");

    final result = await repository.getByStatus(status);

    if (result['success'] == true) {
      print("🎉 [LevelExceptionCubit] Loaded ${result['data'].length} items");
      emit(LevelExceptionSuccess(result['data'], status));
    } else {
      print("❌ [LevelExceptionCubit] Failed: ${result['message']}");
      emit(LevelExceptionFailure(result['message'] ?? 'فشل تحميل الطلبات'));
    }
  }
}