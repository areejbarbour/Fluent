import 'package:flutter/material.dart';

/// Global navigator key.
///
/// This is defined once, at the top level, so it can be used both by
/// [MaterialApp] (as `navigatorKey:`) and by code that lives outside the
/// widget tree — most importantly [LocalNotificationsService], whose
/// `onDidReceiveNotificationResponse` callback fires when the user taps a
/// system-tray notification and has no [BuildContext] of its own.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Global route observer.
///
/// Registered on [MaterialApp] as a `navigatorObservers` entry so any screen
/// can subscribe with [RouteAware] and know when it has been pushed,
/// popped, or — most usefully — when the user has navigated back to it
/// (`didPopNext`). This lets screens like the student Home auto-refresh
/// their data every time they become visible again, instead of relying on
/// a manual pull-to-refresh.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
