class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? emailVerifiedAt;
  final String? googleId;
  final String? fcmToken;
  final List<dynamic> roles;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.emailVerifiedAt,
    this.googleId,
    this.fcmToken,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print("👤 [UserModel] User loaded: ${json['email']}");

    return UserModel(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at']?.toString(),
      googleId: json['google_id']?.toString(),
      fcmToken: json['fcm_token']?.toString(),
      roles: json['roles'] ?? json['role'] ?? [], // ✅ ذكي
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isVerified => emailVerifiedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    };
  }
}