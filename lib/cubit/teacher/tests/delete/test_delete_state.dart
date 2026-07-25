abstract class TestDeleteState {}

class TestDeleteInitial extends TestDeleteState {}
class TestDeleteLoading extends TestDeleteState {}
class TestDeleteSuccess extends TestDeleteState {
  final String message;
  TestDeleteSuccess(this.message);
}
class TestDeleteFailure extends TestDeleteState {
  final String error;
  TestDeleteFailure(this.error);
}