abstract class TestCreateState {}

class TestCreateInitial extends TestCreateState {}
class TestCreateLoading extends TestCreateState {}
class TestCreateSuccess extends TestCreateState {
  final String message;
  TestCreateSuccess(this.message);
}
class TestCreateFailure extends TestCreateState {
  final String error;
  final Map<String, dynamic>? errors;
  TestCreateFailure(this.error, {this.errors});
}