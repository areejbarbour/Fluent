import 'package:fluent/data/models/word_model.dart';

abstract class WordCreateState {}

class WordCreateInitial extends WordCreateState {}

class WordCreateLoading extends WordCreateState {}

class WordCreateSuccess extends WordCreateState {
  final WordModel word;
  final String message;
  WordCreateSuccess(this.word, {this.message = 'Word created successfully'});
}

class WordCreateFailure extends WordCreateState {
  final String error;
  final Map<String, dynamic>? errors;
  WordCreateFailure(this.error, {this.errors});
}
