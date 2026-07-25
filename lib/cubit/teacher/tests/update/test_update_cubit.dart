import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'test_update_state.dart';

class TestUpdateCubit extends Cubit<TestUpdateState> {
  final TestRepository testRepository;
  TestUpdateCubit(this.testRepository) : super(TestUpdateInitial());

  Future<void> updateTest(int testId, FormData formData) async {
    emit(TestUpdateLoading());
    try {
      final result = await testRepository.updateTest(testId, formData);
      if (result['success'] == true) {
        emit(
          TestUpdateSuccess(result['message'] ?? 'Test updated successfully'),
        );
      } else {
        emit(
          TestUpdateFailure(
            result['message'] ?? 'Failed to update test',
            errors: result['errors'],
          ),
        );
      }
    } catch (e) {
      emit(TestUpdateFailure(e.toString()));
    }
  }

  void reset() => emit(TestUpdateInitial());
}
