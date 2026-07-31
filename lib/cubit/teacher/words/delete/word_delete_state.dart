abstract class WordDeleteState {}

class WordDeleteInitial extends WordDeleteState {}

class WordDeleteLoading extends WordDeleteState {}

class WordDeleteSuccess extends WordDeleteState {
  final int wordId;
  final String message;
  WordDeleteSuccess(this.wordId, {this.message = 'Word deleted successfully'});
}

class WordDeleteFailure extends WordDeleteState {
  final String error;
  final Map<String, dynamic>? errors;
  WordDeleteFailure(this.error, {this.errors});
}
