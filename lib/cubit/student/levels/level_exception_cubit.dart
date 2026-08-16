import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'level_exception_state.dart';

class LevelExceptionCubit extends SafeCubit<LevelExceptionState> {
  final LevelExceptionRepository repository;

  LevelExceptionCubit(this.repository) : super(LevelExceptionInitial());

  Future<void> loadBoard() async {
    emit(LevelExceptionLoading());
    print(" [LevelExceptionCubit] Loading exception board (page 1)...");

    try {
      final results = await Future.wait([
        for (final status in LevelExceptionStatuses.all)
          repository.getByStatus(status, page: 1),
      ]);

      final map = <String, List<LevelExceptionModel>>{};
      final metaMap = <String, StatusPageMeta>{};
      String? firstError;

      for (var i = 0; i < LevelExceptionStatuses.all.length; i++) {
        final status = LevelExceptionStatuses.all[i];
        final result = results[i];
        if (result['success'] == true) {
          map[status] = _asList(result['data']);
          metaMap[status] = _metaFromResult(result);
        } else {
          map[status] = const [];
          metaMap[status] = const StatusPageMeta();
          firstError ??= result['message']?.toString();
        }
      }

      final allFailed = results.every((r) => r['success'] != true);
      if (allFailed) {
        emit(LevelExceptionFailure(firstError ?? 'Failed to load requests'));
        return;
      }

      print(
        " [LevelExceptionCubit] Board page1 — "
        "pending=${metaMap['pending']?.total}, "
        "in_review=${metaMap['in_review']?.total}, "
        "approved=${metaMap['approved']?.total}, "
        "rejected=${metaMap['rejected']?.total}",
      );
      emit(LevelExceptionSuccess(map, metaByStatus: metaMap));
    } catch (e) {
      print(" [LevelExceptionCubit] Unexpected: $e");
      emit(LevelExceptionFailure(e.toString()));
    }
  }

  Future<void> loadMore(String status) async {
    final current = state;
    if (current is! LevelExceptionSuccess) return;
    if (!current.hasMore(status)) return;
    if (current.isLoadingMore(status)) return;

    final nextPage = current.metaFor(status).currentPage + 1;
    emit(current.copyWith(loadingMoreStatus: status));
    print(" [LevelExceptionCubit] loadMore $status page $nextPage");

    final result = await repository.getByStatus(status, page: nextPage);

    final after = state;
    if (after is! LevelExceptionSuccess) return;

    if (result['success'] != true) {
      emit(after.copyWith(clearLoadingMore: true));
      return;
    }

    final pageItems = _asList(result['data']);
    final existing = List<LevelExceptionModel>.from(after.itemsFor(status));
    final seen = existing.map((e) => e.id).toSet();
    for (final item in pageItems) {
      if (!seen.contains(item.id)) {
        existing.add(item);
        seen.add(item.id);
      }
    }

    final newByStatus = Map<String, List<LevelExceptionModel>>.from(
      after.byStatus,
    )..[status] = existing;

    final newMeta = Map<String, StatusPageMeta>.from(after.metaByStatus)
      ..[status] = _metaFromResult(result);

    emit(LevelExceptionSuccess(newByStatus, metaByStatus: newMeta));
  }

  Future<void> fetchByStatus(String status) async => loadBoard();

  void removeLocally(int id) {
    final current = state;
    if (current is! LevelExceptionSuccess) return;

    final updated = <String, List<LevelExceptionModel>>{};
    final metaUpdated = Map<String, StatusPageMeta>.from(current.metaByStatus);

    current.byStatus.forEach((key, list) {
      final before = list.length;
      final filtered = list.where((e) => e.id != id).toList();
      updated[key] = filtered;
      if (filtered.length < before) {
        final m = metaUpdated[key] ?? const StatusPageMeta();
        metaUpdated[key] = m.copyWith(total: (m.total - 1).clamp(0, 1 << 30));
      }
    });

    emit(LevelExceptionSuccess(updated, metaByStatus: metaUpdated));
  }

  List<LevelExceptionModel> _asList(dynamic raw) {
    if (raw is List<LevelExceptionModel>) return raw;
    if (raw is List) {
      return raw.whereType<LevelExceptionModel>().toList();
    }
    return const [];
  }

  StatusPageMeta _metaFromResult(Map<String, dynamic> result) {
    final metaRaw = result['meta'];
    if (metaRaw is Map) {
      return StatusPageMeta.fromLaravel(Map<String, dynamic>.from(metaRaw));
    }
    int asInt(dynamic v, [int d = 1]) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? d;
    }

    return StatusPageMeta(
      currentPage: asInt(result['current_page'], 1),
      lastPage: asInt(result['last_page'], 1),
      perPage: asInt(result['per_page'], 10),
      total: asInt(result['total'], 0),
    );
  }
}
