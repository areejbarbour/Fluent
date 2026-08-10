import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluent/cubit/notification/notification_cubit.dart';
import 'package:fluent/data/network/dio_client.dart';
import 'package:fluent/data/repository/notification_repository.dart';
import 'package:fluent/data/services/notification_service.dart';

/// Registers the device FCM token with the backend.
///
/// Backend rules (RegisterFirebaseTokenRequest):
/// - token: required string
/// - device_type: web | mobile | tablet
/// - device_name: optional
///
/// Call AFTER auth token is saved and [setupDio] has run.
class NotificationBootstrap {
  NotificationBootstrap._();

  static String get deviceType {
    if (kIsWeb) return 'web';
    return 'mobile';
  }

  static String get deviceName {
    if (kIsWeb) return 'web';
    try {
      return Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'mobile';
    } catch (_) {
      return 'mobile';
    }
  }

  /// Register using [BuildContext] (has access to [NotificationCubit]).
  static Future<void> registerFromContext(BuildContext context) async {
    try {
      final cubit = context.read<NotificationCubit>();
      await registerWithCubit(cubit);
    } catch (e) {
      debugPrint('⚠️ [NotificationBootstrap] registerFromContext: $e');
      // Fallback without cubit (still hits the API).
      await registerAfterAuth();
    }
  }

  /// Register via cubit.
  static Future<void> registerWithCubit(NotificationCubit cubit) async {
    try {
      final token = await _getFcmToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [NotificationBootstrap] No FCM token available');
        return;
      }

      await cubit.registerFirebaseToken(
        token: token,
        deviceType: deviceType,
        deviceName: deviceName,
      );
      debugPrint('✅ [NotificationBootstrap] Token registered (cubit)');
    } catch (e) {
      debugPrint('⚠️ [NotificationBootstrap] registerWithCubit: $e');
    }
  }

  /// Register without UI context — safe to call from auth cubits
  /// right after [setupDio].
  static Future<void> registerAfterAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null || authToken.isEmpty) {
        debugPrint('⚠️ [NotificationBootstrap] No auth token — skip FCM');
        return;
      }

      final fcmToken = await _getFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ [NotificationBootstrap] No FCM token available');
        return;
      }

      final repo = NotificationRepository(NotificationService(dio));
      final result = await repo.registerFirebaseToken(
        token: fcmToken,
        deviceType: deviceType,
        deviceName: deviceName,
      );

      if (result['success'] == true) {
        debugPrint('✅ [NotificationBootstrap] Token registered (after auth)');
      } else {
        debugPrint(
          '⚠️ [NotificationBootstrap] Register failed: ${result['message']}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationBootstrap] registerAfterAuth: $e');
    }
  }

  /// Listen for FCM token rotations and re-register while logged in.
  static void listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 [NotificationBootstrap] onTokenRefresh');
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null || authToken.isEmpty) return;

      try {
        final repo = NotificationRepository(NotificationService(dio));
        await repo.registerFirebaseToken(
          token: newToken,
          deviceType: deviceType,
          deviceName: deviceName,
        );
        debugPrint('✅ [NotificationBootstrap] Refreshed token registered');
      } catch (e) {
        debugPrint('⚠️ [NotificationBootstrap] onTokenRefresh failed: $e');
      }
    });
  }

  /// On logout: invalidate this device's FCM token so it stops receiving
  /// pushes for the previous user.
  static Future<void> clearOnLogout({BuildContext? context}) async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('✅ [NotificationBootstrap] FCM token deleted on logout');
    } catch (e) {
      debugPrint('⚠️ [NotificationBootstrap] deleteToken: $e');
    }

    if (context != null && context.mounted) {
      try {
        context.read<NotificationCubit>().clearSession();
      } catch (_) {}
    }
  }

  /// Refresh unread badge (call on app resume / after login).
  static Future<void> refreshUnread(BuildContext context) async {
    try {
      await context.read<NotificationCubit>().loadUnreadCount();
    } catch (e) {
      debugPrint('⚠️ [NotificationBootstrap] refreshUnread: $e');
    }
  }

  static Future<String?> _getFcmToken() async {
    try {
      return await _FirebaseMessagingBridge.getToken();
    } catch (e) {
      debugPrint('⚠️ [NotificationBootstrap] getToken failed: $e');
      return null;
    }
  }
}

class _FirebaseMessagingBridge {
  static Future<String?> getToken() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('⚠️ Notification permission denied');
      return null;
    }

    final token = await messaging.getToken();
    print('🔑 FCM token: $token');
    return token;
  }
}
