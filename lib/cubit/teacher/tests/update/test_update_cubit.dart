import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'test_update_state.dart';

class TestUpdateCubit extends Cubit<TestUpdateState> {
  final TestRepository testRepository;
  TestUpdateCubit(this.testRepository) : super(TestUpdateInitial());

  Future<void> updateTest(int testId, Map<String, dynamic> payload) async {
    emit(TestUpdateLoading());
    try {
      final result = await testRepository.updateTest(testId, payload);
      if (result['success'] == true) {
        emit(
          TestUpdateSuccess(
            result['message']?.toString() ?? 'Test updated successfully',
          ),
        );
      } else {
        emit(
          TestUpdateFailure(
            result['message']?.toString() ?? 'Failed to update test',
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
