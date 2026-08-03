import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'test_create_state.dart';

class TestCreateCubit extends Cubit<TestCreateState> {
  final TestRepository testRepository;
  TestCreateCubit(this.testRepository) : super(TestCreateInitial());

  Future<void> createTest(Map<String, dynamic> payload) async {
    emit(TestCreateLoading());
    try {
      final result = await testRepository.createTest(payload);
      if (result['success'] == true) {
        emit(
          TestCreateSuccess(
            result['message']?.toString() ?? 'Test created successfully',
          ),
        );
      } else {
        emit(
          TestCreateFailure(
            result['message']?.toString() ?? 'Failed to create test',
            errors: result['errors'],
          ),
        );
      }
    } catch (e) {
      emit(TestCreateFailure(e.toString()));
    }
  }

  void reset() => emit(TestCreateInitial());
}
