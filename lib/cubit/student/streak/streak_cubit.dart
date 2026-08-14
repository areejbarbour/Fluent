import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/student/streak/streak_state.dart';
import 'package:fluent/data/models/profile_model.dart';
import 'package:fluent/data/repository/profile_repository.dart';

/// Loads real streak + weekly lesson activity for the Streak screen.
/// Matches backend:
/// - GET /api/student/profile → streak, last_activate_date
/// - GET /api/student/weeklyActivity → weekly_activity map (Sun→Sat)
class StreakCubit extends Cubit<StreakState> {
  final ProfileRepository profileRepository;

  StreakCubit({required this.profileRepository}) : super(StreakInitial());

  Future<void> load() async {
    emit(StreakLoading());

    try {
      // Fire both requests in parallel — independent endpoints.
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

      // Prefer showing something useful even if one call fails.
      if (weekly != null) {
        emit(StreakLoaded(
          streak: streak,
          lastActivateDate: lastActivateDate,
          weeklyActivity: weekly,
        ));
        return;
      }

      // Weekly failed — still show streak with empty week if profile ok.
      if (profileResult['success'] == true) {
        emit(StreakLoaded(
          streak: streak,
          lastActivateDate: lastActivateDate,
          weeklyActivity: WeeklyActivityModel.fromJson(const {}),
        ));
        return;
      }

      final msg = profileResult['message']?.toString() ??
          weeklyResult['message']?.toString() ??
          'Failed to load streak data';
      emit(StreakFailure(msg, streak: streak, weeklyActivity: weekly));
    } catch (e) {
      emit(StreakFailure(e.toString()));
    }
  }
}
