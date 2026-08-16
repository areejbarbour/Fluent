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

class ProfileViewData {
  final bool isTeacher;
  final String name;
  final String email;
  final String? bio;
  final String? imageUrl;
  final int points;
  final int streak;
  final String? lastActivateDate;
  final WeeklyActivityModel? weeklyActivity;

  const ProfileViewData({
    required this.isTeacher,
    required this.name,
    required this.email,
    this.bio,
    this.imageUrl,
    this.points = 0,
    this.streak = 0,
    this.lastActivateDate,
    this.weeklyActivity,
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
    WeeklyActivityModel? weeklyActivity,
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
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
    );
  }
}

class WeeklyActivityDay {
  final DateTime date;
  final int completedLessons;

  const WeeklyActivityDay({required this.date, required this.completedLessons});

  bool get isActive => completedLessons > 0;

  String get shortLabel {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return labels[date.weekday % 7];
  }
}

class WeeklyActivityModel {
  final List<WeeklyActivityDay> days;

  const WeeklyActivityModel({required this.days});

  factory WeeklyActivityModel.fromJson(Map<String, dynamic> json) {
    final raw = json['weekly_activity'];
    final Map<String, dynamic> map;
    if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    } else {
      map = <String, dynamic>{};
    }

    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final days = <WeeklyActivityDay>[];
    for (final e in entries) {
      final parsed = DateTime.tryParse(e.key);
      if (parsed == null) continue;
      final count = e.value is int
          ? e.value as int
          : int.tryParse(e.value.toString()) ?? 0;
      days.add(WeeklyActivityDay(date: parsed, completedLessons: count));
    }

    if (days.isEmpty) {
      final now = DateTime.now();
      final sunday = now.subtract(Duration(days: now.weekday % 7));
      for (var i = 0; i < 7; i++) {
        final d = DateTime(sunday.year, sunday.month, sunday.day + i);
        days.add(WeeklyActivityDay(date: d, completedLessons: 0));
      }
    }

    return WeeklyActivityModel(days: days);
  }
}
