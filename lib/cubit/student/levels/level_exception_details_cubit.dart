import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'package:fluent/cubit/student/levels/level_exception_details_state.dart';

class LevelExceptionDetailsCubit extends Cubit<LevelExceptionDetailsState> {
  final LevelExceptionRepository repository;

  LevelExceptionDetailsCubit(this.repository)
      : super(LevelExceptionDetailsInitial());

  Future<void> fetchDetails(int id) async {
    emit(LevelExceptionDetailsLoading());
    print("🟡 [LevelExceptionDetailsCubit] Fetching details for #$id...");

    final result = await repository.getDetails(id);

    if (result['success'] == true) {
      print("🎉 [LevelExceptionDetailsCubit] Details loaded");
      emit(LevelExceptionDetailsSuccess(result['data']));
    } else {
      print("❌ [LevelExceptionDetailsCubit] Failed: ${result['message']}");
      emit(LevelExceptionDetailsFailure(
          result['message'] ?? 'فشل تحميل التفاصيل'));
    }
  }
}