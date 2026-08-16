import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/rate_model.dart';
import 'package:fluent/data/repository/rate_repository.dart';
import 'rate_state.dart';

class RateCubit extends SafeCubit<RateState> {
  final RateRepository rateRepository;

  /// Local cache: courseId → last known RateModel for this session.
  final Map<int, RateModel> _ratesByCourse = {};

  RateCubit(this.rateRepository) : super(const RateInitial());

  Map<int, RateModel> get ratesByCourse => Map.unmodifiable(_ratesByCourse);

  RateModel? rateForCourse(int courseId) => _ratesByCourse[courseId];

  bool hasRated(int courseId) => _ratesByCourse.containsKey(courseId);

  /// Seed cache if you already know a rate (e.g. from a future API field).
  void seedRate(int courseId, RateModel rate) {
    _ratesByCourse[courseId] = rate;
  }

  Future<void> rateCourse({required int courseId, required int stars}) async {
    if (courseId <= 0) {
      emit(const RateFailure('Invalid course.'));
      return;
    }
    if (stars < RateRepository.minStars || stars > RateRepository.maxStars) {
      emit(
        RateFailure(
          'Stars must be between ${RateRepository.minStars} and ${RateRepository.maxStars}.',
          courseId: courseId,
        ),
      );
      return;
    }

    emit(RateLoading(courseId: courseId));
    print(' [RateCubit] Rating course #$courseId with $stars stars...');

    final result = await rateRepository.rateCourse(
      courseId: courseId,
      stars: stars,
    );

    if (result['success'] == true && result['data'] is RateModel) {
      final rate = result['data'] as RateModel;
      _ratesByCourse[courseId] = rate;
      print(' [RateCubit] Rated course #$courseId → rate #${rate.id}');
      emit(
        RateSuccess(
          rate: rate,
          courseId: courseId,
          message: 'Thanks! Your rating was saved.',
        ),
      );
    } else {
      final message =
          result['message']?.toString() ?? 'Failed to rate this course.';
      print(' [RateCubit] Rate failed: $message');
      emit(
        RateFailure(
          message,
          errors: result['errors'] as Map<String, dynamic>?,
          courseId: courseId,
        ),
      );
    }
  }

  Future<void> deleteRate({required int courseId, int? rateId}) async {
    final resolvedId = rateId ?? _ratesByCourse[courseId]?.id;
    if (resolvedId == null || resolvedId <= 0) {
      emit(
        RateFailure(
          'No rating found to delete for this course.',
          courseId: courseId,
        ),
      );
      return;
    }

    emit(RateLoading(courseId: courseId, isDeleting: true));
    print(' [RateCubit] Deleting rate #$resolvedId for course #$courseId...');

    final result = await rateRepository.deleteRate(resolvedId);

    if (result['success'] == true) {
      _ratesByCourse.remove(courseId);
      final message =
          result['message']?.toString() ?? 'Rating deleted successfully';
      print(' [RateCubit] Rate deleted');
      emit(
        RateDeleted(courseId: courseId, rateId: resolvedId, message: message),
      );
    } else {
      final message =
          result['message']?.toString() ?? 'Failed to delete rating.';
      print(' [RateCubit] Delete failed: $message');
      emit(
        RateFailure(
          message,
          errors: result['errors'] as Map<String, dynamic>?,
          courseId: courseId,
        ),
      );
    }
  }

  void reset() => emit(const RateInitial());
}
