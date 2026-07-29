class LessonVideoModel {
  final int id;
  final String title;
  final int xpPoints;
  final String video;

  /// حالة الدرس من الباك (published / archived / closed ...) إن وُجدت
  final String? status;

  LessonVideoModel({
    required this.id,
    required this.title,
    required this.xpPoints,
    required this.video,
    this.status,
  });

  bool get isPublished =>
      status == null || status!.toLowerCase() == 'published';

  bool get isArchivedOrClosed {
    final s = status?.toLowerCase();
    return s == 'archived' || s == 'closed';
  }

  factory LessonVideoModel.fromJson(Map<String, dynamic> json) {
    return LessonVideoModel(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      xpPoints: json['xp_points'] ?? 0,
      video: json['video']?.toString() ?? '',
      status: json['status']?.toString(),
    );
  }
}

class LessonCommentUserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  LessonCommentUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName =>
      [firstName, lastName].where((e) => e.trim().isNotEmpty).join(' ');

  factory LessonCommentUserModel.fromJson(Map<String, dynamic> json) {
    return LessonCommentUserModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class LessonCommentModel {
  final int id;
  final String comment;
  final LessonCommentUserModel? user;
  final String? createdAt;
  final String? updatedAt;
  final bool isOwn;

  LessonCommentModel({
    required this.id,
    required this.comment,
    required this.user,
    required this.createdAt,
    this.updatedAt,
    this.isOwn = false,
  });

  LessonCommentModel copyWith({
    bool? isOwn,
    String? comment,
    String? updatedAt,
    LessonCommentUserModel? user,
    bool clearUser = false,
  }) {
    return LessonCommentModel(
      id: id,
      comment: comment ?? this.comment,
      user: clearUser ? null : (user ?? this.user),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOwn: isOwn ?? this.isOwn,
    );
  }

  factory LessonCommentModel.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    final user = json['user'] != null
        ? LessonCommentUserModel.fromJson(
            Map<String, dynamic>.from(json['user'] as Map),
          )
        : null;

    final isOwn =
        currentUserId != null &&
        currentUserId > 0 &&
        user != null &&
        user.id == currentUserId;

    return LessonCommentModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      comment: json['comment']?.toString() ?? '',
      user: user,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      isOwn: isOwn,
    );
  }
}

/// نتيجة تحليل التعليقات (قائمة عادية أو paginated من Laravel)
class CommentsParseResult {
  final List<LessonCommentModel> comments;
  final int currentPage;
  final int lastPage;
  final int total;

  const CommentsParseResult({
    required this.comments,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  bool get hasMore => currentPage < lastPage;
}

class LessonDetailModel {
  final LessonVideoModel? lesson;
  final List<LessonCommentModel> comments;
  final int commentsCurrentPage;
  final int commentsLastPage;
  final int commentsTotal;

  LessonDetailModel({
    required this.lesson,
    required this.comments,
    this.commentsCurrentPage = 1,
    this.commentsLastPage = 1,
    this.commentsTotal = 0,
  });

  bool get hasMoreComments => commentsCurrentPage < commentsLastPage;

  /// هل يُسمح بإنشاء تعليق حسب حالة الدرس (منطق الباك: published فقط)
  bool get canCreateComment => lesson == null || lesson!.isPublished;

  /// هل يُسمح بتعديل التعليقات حسب حالة الدرس (منطق الباك: ليس archived/closed)
  bool get canUpdateComments => lesson == null || !lesson!.isArchivedOrClosed;

  LessonDetailModel copyWith({
    LessonVideoModel? lesson,
    List<LessonCommentModel>? comments,
    int? commentsCurrentPage,
    int? commentsLastPage,
    int? commentsTotal,
  }) {
    return LessonDetailModel(
      lesson: lesson ?? this.lesson,
      comments: comments ?? this.comments,
      commentsCurrentPage: commentsCurrentPage ?? this.commentsCurrentPage,
      commentsLastPage: commentsLastPage ?? this.commentsLastPage,
      commentsTotal: commentsTotal ?? this.commentsTotal,
    );
  }

  /// حجم صفحة التعليقات في الباك: CommentService::paginate(10)
  static const int backendCommentsPageSize = 10;

  /// يستخرج قائمة التعليقات سواء كانت List مباشرة أو Laravel pagination.
  /// إذا رجعت List بدون meta وطولها == 10 → نفترض احتمال وجود صفحات إضافية.
  static CommentsParseResult parseComments(
    dynamic raw, {
    int? currentUserId,
    int requestedPage = 1,
  }) {
    List list = const [];
    int currentPage = requestedPage < 1 ? 1 : requestedPage;
    int lastPage = currentPage;
    int total = 0;
    bool hasExplicitMeta = false;

    if (raw is List) {
      list = raw;
      total = list.length;
    } else if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      // شكل Laravel ResourceCollection / LengthAwarePaginator
      if (map['data'] is List) {
        list = map['data'] as List;
      } else if (map['comments'] is List) {
        list = map['comments'] as List;
      }

      final cp = _asInt(map['current_page']);
      final lp = _asInt(map['last_page']);
      final tot = _asInt(map['total']);
      if (cp != null || lp != null || tot != null) {
        hasExplicitMeta = true;
        currentPage = cp ?? currentPage;
        lastPage = lp ?? lastPage;
        total = tot ?? list.length;
      }

      // meta داخل بعض الـ APIs
      final meta = map['meta'];
      if (meta is Map) {
        hasExplicitMeta = true;
        currentPage = _asInt(meta['current_page']) ?? currentPage;
        lastPage = _asInt(meta['last_page']) ?? lastPage;
        total = _asInt(meta['total']) ?? total;
      }
    }

    final comments = list
        .whereType<Map>()
        .map(
          (e) => LessonCommentModel.fromJson(
            Map<String, dynamic>.from(e),
            currentUserId: currentUserId,
          ),
        )
        .toList();

    if (total == 0) total = comments.length;
    if (lastPage < 1) lastPage = 1;

    // الباك يرجع comments كـ List فقط (بدون meta) مع paginate(10)
    // → إذا امتلأت الصفحة يحتمل وجود المزيد
    if (!hasExplicitMeta) {
      currentPage = requestedPage < 1 ? 1 : requestedPage;
      if (comments.length >= backendCommentsPageSize) {
        lastPage = currentPage + 1; // صفحة إضافية محتملة (غير معروفة النهاية)
      } else {
        lastPage = currentPage; // آخر صفحة
      }
      total = comments.length;
    }

    return CommentsParseResult(
      comments: comments,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory LessonDetailModel.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
    int requestedPage = 1,
  }) {
    final parsed = parseComments(
      json['comments'],
      currentUserId: currentUserId,
      requestedPage: requestedPage,
    );

    return LessonDetailModel(
      lesson: json['lesson'] != null
          ? LessonVideoModel.fromJson(Map<String, dynamic>.from(json['lesson']))
          : null,
      comments: parsed.comments,
      commentsCurrentPage: parsed.currentPage,
      commentsLastPage: parsed.lastPage,
      commentsTotal: parsed.total,
    );
  }
}
