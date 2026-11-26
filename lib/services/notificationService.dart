import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/services/birthdayStore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class PlannedReminder {
  final BirthdayEntry entry;
  final int leadDays;
  final DateTime fireAt;
  const PlannedReminder(this.entry, this.leadDays, this.fireAt);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // iOS behält höchstens 64 geplante Benachrichtigungen, Android begrenzt
  // Alarme auf 500 pro App. Geplant werden deshalb immer die nächsten.
  static const int _maxPendingIOS = 60;
  static const int _maxPendingAndroid = 400;
  static const String _channelId = 'birthday_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void> _pending = Future.value();
  Future<void>? _initFuture;

  static const String _planSignatureKey = 'notificationPlanSignature';

  Future<void>? _timeZoneFuture;

  // Wird beim ersten Bedarf eingerichtet, nicht beim Start der App
  Future<void> init() => _initFuture ??= _init();

  // Die Zeitzonen-Datenbank braucht nur die Planung. Sie wird erst dann
  // geladen, weil das sonst das Öffnen der App verzögert.
  Future<void> _initTimeZone() =>
      _timeZoneFuture ??= () async {
        tzdata.initializeTimeZones();
        final timeZone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZone.identifier));
      }();

  Future<void> _init() async {
    try {
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: darwin,
          macOS: darwin,
        ),
      );
      _ready = true;
    } catch (e) {
      // Ohne Benachrichtigungen muss die App trotzdem starten
      debugPrint('Notification setup failed: $e');
    }
  }

  // -------------------
  // Berechtigung
  // -------------------
  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios =
        _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    return await ios?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        ) ??
        false;
  }

  Future<bool> hasPermission() async {
    await init();
    if (!_ready) return false;
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios =
        _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    final options = await ios?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  // -------------------
  // Planung
  // -------------------

  // Liefert alle anstehenden Erinnerungen, die nächste zuerst
  @visibleForTesting
  static List<PlannedReminder> plan(
    List<BirthdayEntry> entries,
    List<int> leadDays,
    DateTime now,
  ) {
    final reminders = <PlannedReminder>[];
    for (final entry in entries) {
      if (!entry.notificationsEnabled) continue;
      for (final lead in leadDays) {
        reminders.add(
          PlannedReminder(entry, lead, _nextFire(entry, lead, now)),
        );
      }
    }
    reminders.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return reminders;
  }

  static DateTime _nextFire(BirthdayEntry entry, int lead, DateTime now) {
    for (var year = now.year; ; year++) {
      // Wer am 29. Februar geboren ist, wird sonst am 28. erinnert
      final day = min(
        entry.birthday.day,
        DateUtils.getDaysInMonth(year, entry.birthday.month),
      );
      final fireAt = DateTime(
        year,
        entry.birthday.month,
        day - lead,
        entry.notificationTime.hour,
        entry.notificationTime.minute,
      );
      if (fireAt.isAfter(now)) return fireAt;
    }
  }

  // Aufrufe laufen nacheinander, damit sich zwei Planungen nicht überlagern
  Future<void> reschedule() {
    return _pending = _pending.then((_) async {
      await init();
      try {
        await _initTimeZone();
      } catch (e) {
        debugPrint('Time zone setup failed: $e');
        return;
      }
      await _reschedule();
    });
  }

  // Beim Start nur neu planen, wenn sich seit der letzten Planung etwas
  // geändert hat oder ein neuer Tag begonnen hat
  Future<void> rescheduleIfNeeded() async {
    await init();
    if (!_ready) return;
    try {
      await _initTimeZone();
    } catch (e) {
      debugPrint('Time zone setup failed: $e');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_planSignatureKey) == _planSignature()) return;
    await reschedule();
  }

  String _planSignature() {
    final settings = AppSettings.instance;
    final today = DateUtils.dateOnly(DateTime.now()).toIso8601String();
    return jsonEncode([
      today,
      tz.local.name,
      settings.notificationsEnabled,
      settings.leadDays,
      settings.locale.languageCode,
      BirthdayStore.instance.entries.map((e) => e.toJson()).toList(),
    ]);
  }

  Future<void> _rememberPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planSignatureKey, _planSignature());
  }

  Future<void> _reschedule() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final settings = AppSettings.instance;
      if (!settings.notificationsEnabled) {
        await _rememberPlan();
        return;
      }

      final strings = AppStrings.forLocale(settings.locale);
      final details = _details(strings);
      final scheduleMode = await _scheduleMode();
      final limit = Platform.isAndroid ? _maxPendingAndroid : _maxPendingIOS;
      final reminders =
          plan(
            BirthdayStore.instance.entries,
            settings.leadDays,
            DateTime.now(),
          ).take(limit).toList();

      for (var id = 0; id < reminders.length; id++) {
        final reminder = reminders[id];
        await _plugin.zonedSchedule(
          id: id,
          title: strings.reminderTitle,
          body: strings.reminderBody(reminder.entry.name, reminder.leadDays),
          scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
          notificationDetails: details,
          androidScheduleMode: scheduleMode,
          // Der Text nennt kein Alter und bleibt daher jedes Jahr richtig
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
      }
      await _rememberPlan();
    } catch (e) {
      debugPrint('Scheduling notifications failed: $e');
    }
  }

  // Exakte Alarme können auf neueren Android-Versionen verboten sein
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails _details(AppStrings strings) {
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    );
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        strings.channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: darwin,
      macOS: darwin,
    );
  }
}
