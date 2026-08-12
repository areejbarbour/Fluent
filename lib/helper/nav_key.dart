import 'package:flutter/material.dart';

/// Global navigator key.
///
/// This is defined once, at the top level, so it can be used both by
/// [MaterialApp] (as `navigatorKey:`) and by code that lives outside the
/// widget tree — most importantly [LocalNotificationsService], whose
/// `onDidReceiveNotificationResponse` callback fires when the user taps a
/// system-tray notification and has no [BuildContext] of its own.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
