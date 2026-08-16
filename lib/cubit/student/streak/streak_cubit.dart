import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/cubit/student/streak/streak_state.dart';
import 'package:fluent/data/models/profile_model.dart';
import 'package:fluent/data/repository/profile_repository.dart';

class StreakCubit extends SafeCubit<StreakState> {
  final ProfileRepository profileRepository;

  StreakCubit({required this.profileRepository}) : super(StreakInitial());

  Future<void> load() async {
    emit(StreakLoading());

    try {
      final results = await Future.wait([
        profileRepository.getStudentProfile(),
        profileRepository.getWeeklyActivity(),
      ]);

      final profileResult = results[0];
      final weeklyResult = results[1];

      int streak = 0;
      String? lastActivateDate;
      WeeklyActivityModel? weekly;

      if (profileResult['success'] == true &&
          profileResult['data'] is StudentProfileModel) {
        final p = profileResult['data'] as StudentProfileModel;
        streak = p.streak;
        lastActivateDate = p.lastActivateDate;
      }

      if (weeklyResult['success'] == true &&
          weeklyResult['data'] is WeeklyActivityModel) {
        weekly = weeklyResult['data'] as WeeklyActivityModel;
      }

      if (weekly != null) {
        emit(
          StreakLoaded(
            streak: streak,
            lastActivateDate: lastActivateDate,
            weeklyActivity: weekly,
          ),
        );
        return;
      }

      if (profileResult['success'] == true) {
        emit(
          StreakLoaded(
            streak: streak,
            lastActivateDate: lastActivateDate,
            weeklyActivity: WeeklyActivityModel.fromJson(const {}),
          ),
        );
        return;
      }

      final msg =
          profileResult['message']?.toString() ??
          weeklyResult['message']?.toString() ??
          'Failed to load streak data';
      emit(StreakFailure(msg, streak: streak, weeklyActivity: weekly));
    } catch (e) {
      emit(StreakFailure(e.toString()));
    }
  }
}
