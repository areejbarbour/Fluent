import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'test_delete_state.dart';

class TestDeleteCubit extends SafeCubit<TestDeleteState> {
  final TestRepository testRepository;
  TestDeleteCubit(this.testRepository) : super(TestDeleteInitial());

  Future<void> deleteTest(int testId) async {
    emit(TestDeleteLoading());
    try {
      final result = await testRepository.deleteTest(testId);
      if (result['success'] == true) {
        emit(
          TestDeleteSuccess(result['message'] ?? 'Test deleted successfully'),
        );
      } else {
        emit(TestDeleteFailure(result['message'] ?? 'Failed to delete test'));
      }
    } catch (e) {
      emit(TestDeleteFailure(e.toString()));
    }
  }
}
