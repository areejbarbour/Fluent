import 'package:fluent/data/models/words_bank_model.dart';

abstract class WordsBankState {}

class WordsBankInitial extends WordsBankState {}

class WordsBankLoading extends WordsBankState {}

class WordsBankSuccess extends WordsBankState {
  final List<WordsBankItem> learningWords;
  final List<WordsBankItem> knownWords;

  WordsBankSuccess({
    required this.learningWords,
    required this.knownWords,
  });
}

class WordsBankFailure extends WordsBankState {
  final String message;
  WordsBankFailure(this.message);
}