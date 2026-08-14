import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for auth persistence (student + teacher).
///
/// Rules:
/// - Logged in  → must have non-empty [token] + [is_logged_in] == true
/// - Logged out → no token, no is_logged_in (all session keys cleared)
/// - Cold start uses [isLoggedIn] / [role] only — never show login while session is valid
class AuthSession {
  AuthSession._();

  static const tokenKey = 'token';
  static const loggedInKey = 'is_logged_in';
  static const roleKey = 'user_role';
  static const userIdKey = 'user_id';
  static const loginMethodKey = 'login_method';

  /// True only when a real session exists (token + flag).
  /// Auto-repairs inconsistent states.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey)?.trim() ?? '';
    final flag = prefs.getBool(loggedInKey) ?? false;

    // Valid session
    if (token.isNotEmpty && flag) return true;

    // Token present but flag missing → repair (upgrade from older builds)
    if (token.isNotEmpty && !flag) {
      await prefs.setBool(loggedInKey, true);
      print('🔧 [AuthSession] repaired is_logged_in=true (token present)');
      return true;
    }

    // Flag true but no token → invalid, force logout local
    if (flag && token.isEmpty) {
      print('🔧 [AuthSession] invalid session (flag without token) → clear');
      await clear();
      return false;
    }

    return false;
  }

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(tokenKey)?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  /// Normalized role: `student` | `teacher` | null
  static Future<String?> role() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(roleKey)?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    if (raw.contains('teacher')) return 'teacher';
    if (raw.contains('student')) return 'student';
    return raw;
  }

  static Future<int?> userId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(userIdKey);
    if (id != null && id > 0) return id;
    final s = prefs.getString(userIdKey);
    if (s != null) return int.tryParse(s);
    return null;
  }

  /// Call after successful email / Google / OTP login.
  static Future<void> saveSession({
    required String token,
    required String role,
    int? userId,
    String loginMethod = 'email',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final t = token.trim();
    if (t.isEmpty) {
      throw ArgumentError('AuthSession.saveSession: token must not be empty');
    }

    final roleNorm = role.trim().toLowerCase().contains('teacher')
        ? 'teacher'
        : 'student';

    await prefs.setString(tokenKey, t);
    await prefs.setBool(loggedInKey, true);
    await prefs.setString(roleKey, roleNorm);
    await prefs.setString(loginMethodKey, loginMethod);
    if (userId != null && userId > 0) {
      await prefs.setInt(userIdKey, userId);
    }

    print(
      '✅ [AuthSession] saved session role=$roleNorm userId=$userId method=$loginMethod',
    );
  }

  /// Always clears local session (call on logout, even if API fails).
  /// Does NOT clear app_language / placement skip / onboard flags (per-user keys).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(loggedInKey);
    await prefs.remove(roleKey);
    await prefs.remove(userIdKey);
    await prefs.remove(loginMethodKey);
    // legacy / alternate keys
    await prefs.remove('auth_token');
    await prefs.remove('access_token');
    print('🧹 [AuthSession] session cleared');
  }
}
