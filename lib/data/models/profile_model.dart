/// Student profile — matches `StudentProfileResource` from the backend.
class StudentProfileModel {
  final String? bio;
  final int points;
  final int streak;
  final String? lastActivateDate;
  final String? imageUrl;

  const StudentProfileModel({
    this.bio,
    this.points = 0,
    this.streak = 0,
    this.lastActivateDate,
    this.imageUrl,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      bio: json['bio']?.toString(),
      points: _asInt(json['points']),
      streak: _asInt(json['streak']),
      lastActivateDate: json['last_activate_date']?.toString(),
      imageUrl: _cleanUrl(json['image_url']),
    );
  }

  StudentProfileModel copyWith({
    String? bio,
    int? points,
    int? streak,
    String? lastActivateDate,
    String? imageUrl,
  }) {
    return StudentProfileModel(
      bio: bio ?? this.bio,
      points: points ?? this.points,
      streak: streak ?? this.streak,
      lastActivateDate: lastActivateDate ?? this.lastActivateDate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String? _cleanUrl(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return s;
  }
}

/// Teacher profile — matches `TeacherProfileResource` from the backend.
class TeacherProfileModel {
  final String? bio;
  final String? imageUrl;

  const TeacherProfileModel({this.bio, this.imageUrl});

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) {
    return TeacherProfileModel(
      bio: json['bio']?.toString(),
      imageUrl: StudentProfileModel._cleanUrl(json['image_url']),
    );
  }

  TeacherProfileModel copyWith({String? bio, String? imageUrl}) {
    return TeacherProfileModel(
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Unified view-model used by the Profile screen for both roles.
class ProfileViewData {
  final bool isTeacher;
  final String name;
  final String email;
  final String? bio;
  final String? imageUrl;
  final int points;
  final int streak;
  final String? lastActivateDate;

  const ProfileViewData({
    required this.isTeacher,
    required this.name,
    required this.email,
    this.bio,
    this.imageUrl,
    this.points = 0,
    this.streak = 0,
    this.lastActivateDate,
  });

  ProfileViewData copyWith({
    bool? isTeacher,
    String? name,
    String? email,
    String? bio,
    String? imageUrl,
    int? points,
    int? streak,
    String? lastActivateDate,
  }) {
    return ProfileViewData(
      isTeacher: isTeacher ?? this.isTeacher,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      points: points ?? this.points,
      streak: streak ?? this.streak,
      lastActivateDate: lastActivateDate ?? this.lastActivateDate,
    );
  }
}
