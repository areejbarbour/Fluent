import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/repository/words_bank_repository.dart';
import 'words_bank_state.dart';

class WordsBankCubit extends SafeCubit<WordsBankState> {
  final WordsBankRepository repository;

  WordsBankCubit(this.repository) : super(WordsBankInitial());

  Future<void> fetchAll() async {
    emit(WordsBankLoading());
    print(" [WordsBankCubit] Fetching learning + know words...");

    final learningResult = await repository.getLearningWords();
    final knowResult = await repository.getKnowWords();

    if (learningResult['success'] == true) {
      print(" [WordsBankCubit] Words loaded");
      emit(
        WordsBankSuccess(
          learningWords: learningResult['data'] ?? [],
          knownWords: knowResult['success'] == true
              ? (knowResult['data'] ?? [])
              : [],
        ),
      );
    } else {
      print(" [WordsBankCubit] Failed: ${learningResult['message']}");
      emit(
        WordsBankFailure(
          learningResult['message'] ?? 'Failed to load word bank',
        ),
      );
    }
  }
}
