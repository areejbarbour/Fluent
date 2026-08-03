import 'package:fluent/data/models/level_exception_model.dart';

/// Canonical student Level Exception statuses (backend LevelExceptionStatus).
class LevelExceptionStatuses {
  static const pending = 'pending';
  static const inReview = 'in_review';
  static const approved = 'approved';
  static const rejected = 'rejected';

  static const List<String> all = [pending, inReview, approved, rejected];
}

/// Pagination meta for one status list (Laravel paginate(10)).
class StatusPageMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const StatusPageMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 10,
    this.total = 0,
  });

  bool get hasMore => currentPage < lastPage;

  StatusPageMeta copyWith({
    int? currentPage,
    int? lastPage,
    int? perPage,
    int? total,
  }) {
    return StatusPageMeta(
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
    );
  }

  factory StatusPageMeta.fromLaravel(Map<String, dynamic>? meta) {
    if (meta == null) return const StatusPageMeta();
    int asInt(dynamic v, [int d = 0]) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? d;
    }

    return StatusPageMeta(
      currentPage: asInt(meta['current_page'], 1),
      lastPage: asInt(meta['last_page'], 1),
      perPage: asInt(meta['per_page'], 10),
      total: asInt(meta['total'], 0),
    );
  }
}

abstract class LevelExceptionState {}

class LevelExceptionInitial extends LevelExceptionState {}

class LevelExceptionLoading extends LevelExceptionState {}

/// Board-style success: all statuses grouped (Status Board pattern).
class LevelExceptionSuccess extends LevelExceptionState {
  final Map<String, List<LevelExceptionModel>> byStatus;
  final Map<String, StatusPageMeta> metaByStatus;

  /// Status currently loading the next page (null = none).
  final String? loadingMoreStatus;

  LevelExceptionSuccess(
    this.byStatus, {
    Map<String, StatusPageMeta>? metaByStatus,
    this.loadingMoreStatus,
  }) : metaByStatus = metaByStatus ?? const {};

  List<LevelExceptionModel> itemsFor(String status) =>
      byStatus[status] ?? const [];

  StatusPageMeta metaFor(String status) =>
      metaByStatus[status] ?? const StatusPageMeta();

  int countFor(String status) {
    final m = metaByStatus[status];
    if (m != null && m.total > 0) return m.total;
    return itemsFor(status).length;
  }

  bool hasMore(String status) => metaFor(status).hasMore;

  bool isLoadingMore(String status) => loadingMoreStatus == status;

  int get totalCount =>
      LevelExceptionStatuses.all.fold<int>(0, (sum, s) => sum + countFor(s));

  LevelExceptionSuccess copyWith({
    Map<String, List<LevelExceptionModel>>? byStatus,
    Map<String, StatusPageMeta>? metaByStatus,
    String? loadingMoreStatus,
    bool clearLoadingMore = false,
  }) {
    return LevelExceptionSuccess(
      byStatus ?? this.byStatus,
      metaByStatus: metaByStatus ?? this.metaByStatus,
      loadingMoreStatus: clearLoadingMore
          ? null
          : (loadingMoreStatus ?? this.loadingMoreStatus),
    );
  }
}

class LevelExceptionFailure extends LevelExceptionState {
  final String message;
  LevelExceptionFailure(this.message);
}
