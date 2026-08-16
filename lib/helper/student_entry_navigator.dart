import 'package:fluent/constants/strings.dart';
import 'package:fluent/data/models/level_model.dart';
import 'package:fluent/data/repository/level_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Post-auth routing for students — uses official backend placement status.
///
/// Preferred source of truth: GET /api/placement-test/status
/// Fallback: local skip flag + levels enrollment (legacy).
class StudentEntryNavigator {
  static const _onboardKeyPrefix = 'student_onboarded_';
  static const _skipPlacementKeyPrefix = 'student_skip_placement_';

  static Future<String> _userId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id != null && id != 0) return id.toString();
    final s = prefs.getString('user_id');
    if (s != null && s.isNotEmpty) return s;
    return '0';
  }

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _userId();
    return prefs.getBool('$_onboardKeyPrefix$id') ?? false;
  }

  /// Call when the student first lands on Home (after placement or Level 1).
  static Future<void> markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _userId();
    await prefs.setBool('$_onboardKeyPrefix$id', true);
  }

  /// User chose "Start at Level 1" — skip placement dialog forever (local).
  static Future<void> markSkipPlacement() async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _userId();
    await prefs.setBool('$_skipPlacementKeyPrefix$id', true);
  }

  static Future<bool> hasSkippedPlacement() async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _userId();
    return prefs.getBool('$_skipPlacementKeyPrefix$id') ?? false;
  }

  /// Official backend decision via GET /api/placement-test/status.
  /// Returns null on network/parse failure so callers can fall back.
  static Future<PlacementTestStatusModel?> fetchPlacementStatus(
    LevelRepository levelRepository,
  ) async {
    try {
      final res = await levelRepository.getPlacementTestStatus();
      if (res['success'] == true && res['data'] is PlacementTestStatusModel) {
        return res['data'] as PlacementTestStatusModel;
      }
    } catch (_) {}
    return null;
  }

  /// Server-side placement progress (levels enrolled) — legacy fallback.
  static Future<bool> hasServerPlacement(
    LevelRepository levelRepository,
  ) async {
    try {
      final res = await levelRepository.getStudentLevels();
      if (res['success'] == true && res['data'] is StudentLevelsModel) {
        final d = res['data'] as StudentLevelsModel;
        return d.currentLevel != null || d.completedLevels.isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

  /// True if student should NOT see the placement choice UI.
  /// Uses official /placement-test/status first; falls back to levels + local skip.
  static Future<bool> hasCompletedPlacement(
    BuildContext context, {
    LevelRepository? levelRepository,
  }) async {
    if (await hasSkippedPlacement()) return true;
    final repo = levelRepository ?? context.read<LevelRepository>();

    final status = await fetchPlacementStatus(repo);
    if (status != null) {
      // action == show_levels means placement already done (or assigned)
      return status.shouldShowLevels;
    }

    // Fallback if status endpoint fails
    return hasServerPlacement(repo);
  }

  /// For main() without BuildContext.
  static Future<bool> hasCompletedPlacementStandalone(
    LevelRepository levelRepository,
  ) async {
    if (await hasSkippedPlacement()) return true;

    final status = await fetchPlacementStatus(levelRepository);
    if (status != null) {
      return status.shouldShowLevels;
    }

    return hasServerPlacement(levelRepository);
  }

  /// Resolves the next route after login / Google login for a student.
  static Future<String> resolveAfterLogin(BuildContext context) async {
    final placed = await hasCompletedPlacement(context);
    if (!placed) return placementTestDialogRoute;

    final returning = await hasCompletedOnboarding();
    if (returning) return streakRoute;

    return studentHomeRoute;
  }

  /// After streak "Continue".
  static Future<String> resolveAfterStreak(BuildContext context) async {
    final placed = await hasCompletedPlacement(context);
    return placed ? studentHomeRoute : placementTestDialogRoute;
  }

  static Future<void> goAfterLogin(BuildContext context) async {
    final route = await resolveAfterLogin(context);
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }

  static Future<void> goAfterStreak(BuildContext context) async {
    final route = await resolveAfterStreak(context);
    if (!context.mounted) return;
    if (route == studentHomeRoute) {
      await markOnboarded();
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }
}
