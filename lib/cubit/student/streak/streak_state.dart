import 'package:fluent/data/models/profile_model.dart';

abstract class StreakState {}

class StreakInitial extends StreakState {}

class StreakLoading extends StreakState {}

class StreakLoaded extends StreakState {
  final int streak;
  final String? lastActivateDate;
  final WeeklyActivityModel weeklyActivity;

  StreakLoaded({
    required this.streak,
    required this.weeklyActivity,
    this.lastActivateDate,
  });
}

class StreakFailure extends StreakState {
  final String message;
  final int? streak;
  final WeeklyActivityModel? weeklyActivity;

  StreakFailure(
    this.message, {
    this.streak,
    this.weeklyActivity,
  });
}
