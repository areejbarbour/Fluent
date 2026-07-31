import 'package:fluent/data/models/word_model.dart';

abstract class WordUpdateState {}

class WordUpdateInitial extends WordUpdateState {}

class WordUpdateLoading extends WordUpdateState {}

class WordUpdateSuccess extends WordUpdateState {
  final WordModel word;
  final String message;
  WordUpdateSuccess(this.word, {this.message = 'Word updated successfully'});
}

class WordUpdateFailure extends WordUpdateState {
  final String error;
  final Map<String, dynamic>? errors;
  WordUpdateFailure(this.error, {this.errors});
}
