import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// How a reminder got scheduled.
enum Scheduled {
  /// On the minute.
  exact,

  /// Android may hold it back a few minutes to save battery.
  inexact,

  /// Notifications are off for the app.
  denied,

  /// Not on a phone (tests, desktop).
  unsupported,
}

/// Local notifications for reminders set from a dump.
class Reminders {
  Reminders._();

  static final instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Reminders you set from a brain dump',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFE5793F),
    ),
    iOS: DarwinNotificationDetails(),
  );

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_brain_dump'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<bool> _permission() async {
    if (Platform.isAndroid) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  /// Schedules a reminder notification [id] at [at].
  Future<Scheduled> schedule({
    required int id,
    required DateTime at,
    required String title,
    String? body,
  }) async {
    if (!_supported) return Scheduled.unsupported;
    await _init();
    if (!await _permission()) return Scheduled.denied;
    var exact = true;
    if (Platform.isAndroid) {
      exact = await _android?.canScheduleExactNotifications() ?? false;
    }
    await _plugin.zonedSchedule(
      id: id,
      // One-off reminders only need the instant, so UTC avoids needing the
      // device's time zone name.
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
    return exact ? Scheduled.exact : Scheduled.inexact;
  }

  /// Opens the system screen that allows on-the-minute reminders.
  Future<void> allowExact() async {
    if (!_supported || !Platform.isAndroid) return;
    await _init();
    await _android?.requestExactAlarmsPermission();
  }

  Future<void> cancel(int id) async {
    if (!_supported) return;
    await _init();
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    if (!_supported) return;
    await _init();
    await _plugin.cancelAll();
  }
}
