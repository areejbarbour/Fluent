import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'test_create_state.dart';

class TestCreateCubit extends Cubit<TestCreateState> {
  final TestRepository testRepository;
  TestCreateCubit(this.testRepository) : super(TestCreateInitial());

  Future<void> createTest(FormData formData) async {
    emit(TestCreateLoading());
    try {
      final result = await testRepository.createTest(formData);
      if (result['success'] == true) {
        emit(TestCreateSuccess(result['message'] ?? 'Test created successfully'));
      } else {
        emit(TestCreateFailure(
          result['message'] ?? 'Failed to create test',
          errors: result['errors'],
        ));
      }
    } catch (e) {
      emit(TestCreateFailure(e.toString()));
    }
  }

  void reset() => emit(TestCreateInitial());
}