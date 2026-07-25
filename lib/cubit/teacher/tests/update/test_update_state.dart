abstract class TestUpdateState {}
class TestUpdateInitial extends TestUpdateState {}
class TestUpdateLoading extends TestUpdateState {}
class TestUpdateSuccess extends TestUpdateState {
  final String message;
  TestUpdateSuccess(this.message);
}
class TestUpdateFailure extends TestUpdateState {
  final String error;
  final Map<String, dynamic>? errors;
  TestUpdateFailure(this.error, {this.errors});
}