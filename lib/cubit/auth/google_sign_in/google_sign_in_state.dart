abstract class GoogleLoginState {
  const GoogleLoginState();
}

class GoogleLoginInitial extends GoogleLoginState {}

class GoogleLoginLoading extends GoogleLoginState {}

class GoogleLoginSuccess extends GoogleLoginState {
  final String token;
  final List<dynamic> roles;
  final Map<String, dynamic>? user;

  const GoogleLoginSuccess({
    required this.token,
    required this.roles,
    this.user,
  });
}

class GoogleLoginFailure extends GoogleLoginState {
  final String message;
  const GoogleLoginFailure(this.message);
}