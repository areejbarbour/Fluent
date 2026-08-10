import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/data/models/notification_model.dart';
import 'nav_key.dart';
import 'notification_route_resolver.dart';

/// Shows real system-tray notifications (top of phone) while the app is in
/// foreground. Background/killed notifications are handled by FCM itself.
///
/// Branding:
///  • Small status-bar icon → white silhouette `@drawable/ic_notification`
///  • Large icon (expanded) → app launcher `@mipmap/ic_launcher`
///  • App name line → "Fluent" via [subText] / [summaryText]
///  • Accent color → AppColors.primary
///
/// Android icon: use a WHITE transparent silhouette in
///   android/app/src/main/res/drawable/ic_notification.png
/// Colored launcher icons appear as a white dot in the status bar — that's
/// an OS restriction. The app logo still shows via [largeIcon].
class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance =
      LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Displayed as the app identity on the system notification.
  static const String appName = 'Fluent';

  /// Must match AndroidManifest meta-data:
  /// com.google.firebase.messaging.default_notification_channel_id
  static const String channelId = 'high_importance_channel';
  static const String channelName = 'Fluent Notifications';
  static const String channelDesc = 'Course, lesson and review updates';

  /// Call once after Firebase.initializeApp() in main().
  Future<void> init() async {
    if (_ready) return;

    // Prefer white silhouette drawable. Fallback to launcher if missing.
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Android 13+ runtime permission
    await androidPlugin?.requestNotificationsPermission();

    _ready = true;
    print('✅ [LocalNotifications] initialized');
  }

  void _onTap(NotificationResponse response) {
    print('📩 [LocalNotifications] tapped payload=${response.payload}');

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(payload);
      data = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (e) {
      print('⚠️ [LocalNotifications] payload decode failed: $e');
      return;
    }

    final type = data['type']?.toString() ?? AppNotificationModel.typeGeneral;
    final title = data['title']?.toString();

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    NotificationRouteResolver.open(
      ctx,
      type: type,
      data: data,
      fallbackTitle: title,
    );
  }

  /// Show a system notification from an FCM RemoteMessage (foreground).
  Future<void> showFromFirebase(RemoteMessage message) async {
    await init();

    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        appName;
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) {
      print('⚠️ [LocalNotifications] empty title/body — skip');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      // Small icon in status bar (must be white silhouette)
      icon: '@drawable/ic_notification',
      // App logo shown when notification is expanded
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      // Shows "Fluent" under the title on many Android skins
      subText: appName,
      styleInformation: BigTextStyleInformation(
        body.isEmpty ? title : body,
        contentTitle: title,
        summaryText: appName,
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
      color: AppColors.primary,
      colorized: false,
      ticker: '$appName: $title',
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      showWhen: true,
      channelShowBadge: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // iOS shows the app name automatically from the bundle;
      // threadIdentifier groups Fluent notifications together.
      threadIdentifier: 'fluent_notifications',
      interruptionLevel: InterruptionLevel.active,
    );

    // Keep the full data payload (JSON) so the tap handler can route.
    final payloadMap = {
      ...message.data,
      if (!message.data.containsKey('title')) 'title': title,
      if (!message.data.containsKey('body') && body.isNotEmpty) 'body': body,
      if (!message.data.containsKey('type'))
        'type':
            message.data['type']?.toString() ??
            AppNotificationModel.typeGeneral,
    };

    await _plugin.show(
      id: message.hashCode.abs() % 2147483647,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payloadMap.isNotEmpty ? jsonEncode(payloadMap) : null,
    );

    print('✅ [LocalNotifications] shown: [$appName] $title');
  }

  /// Optional: show a custom local notification (not from FCM).
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      subText: appName,
      styleInformation: BigTextStyleInformation(
        body.isEmpty ? title : body,
        contentTitle: title,
        summaryText: appName,
      ),
      color: AppColors.primary,
      ticker: '$appName: $title',
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'fluent_notifications',
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }
}
