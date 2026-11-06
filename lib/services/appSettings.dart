import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StartPage { home, list, calendar, settings }

enum DateStyle {
  dayMonthYearSlash('dd/MM/yyyy'),
  dayMonthYearDot('dd.MM.yyyy'),
  dayMonthYearDash('dd-MM-yyyy'),
  monthDayYearSlash('MM/dd/yyyy'),
  yearMonthDayDash('yyyy-MM-dd'),
  yearMonthDaySlash('yyyy/MM/dd'),
  dayMonthShortYearSlash('dd/MM/yy'),
  dayMonthShortYearDot('dd.MM.yy'),
  monthDayShortYearSlash('MM/dd/yy');

  final String pattern;
  const DateStyle(this.pattern);

  String format(DateTime d, {bool withYear = true}) {
    final template =
        withYear ? pattern : pattern.replaceAll(RegExp(r'[./-]?y+[./-]?'), '');
    return template
        .replaceAll('yyyy', d.year.toString())
        .replaceAll('yy', (d.year % 100).toString().padLeft(2, '0'))
        .replaceAll('MM', d.month.toString().padLeft(2, '0'))
        .replaceAll('dd', d.day.toString().padLeft(2, '0'));
  }
}

class AppSettings {
  final SharedPreferences _prefs;
  AppSettings._(this._prefs);

  static late AppSettings instance;

  static const List<int> leadDayOptions = [0, 1, 3, 7, 14];

  static Future<void> load() async {
    instance = AppSettings._(await SharedPreferences.getInstance());
  }

  // -------------------
  // Design
  // -------------------
  ThemeMode get themeMode =>
      ThemeMode.values[_prefs.getInt('themeMode') ?? ThemeMode.system.index];
  set themeMode(ThemeMode mode) => _prefs.setInt('themeMode', mode.index);

  Color get accentColor => Color(_prefs.getInt('accentColor') ?? 0xFF2196F3);
  set accentColor(Color color) =>
      _prefs.setInt('accentColor', color.toARGB32());

  // Ohne gespeicherte Auswahl gilt die Sprache des Geräts
  Locale get locale {
    final code =
        _prefs.getString('language') ??
        PlatformDispatcher.instance.locale.languageCode;
    return Locale(code == 'de' ? 'de' : 'en');
  }

  set locale(Locale locale) =>
      _prefs.setString('language', locale.languageCode);

  bool get amoled => _prefs.getBool('amoled') ?? false;
  set amoled(bool enabled) => _prefs.setBool('amoled', enabled);

  bool get pinScramble => _prefs.getBool('pinScramble') ?? false;
  set pinScramble(bool enabled) => _prefs.setBool('pinScramble', enabled);

  StartPage get startPage =>
      StartPage.values.asNameMap()[_prefs.getString('startPageName')] ??
      StartPage.home;
  set startPage(StartPage page) => _prefs.setString('startPageName', page.name);

  DateStyle get dateStyle =>
      DateStyle.values.asNameMap()[_prefs.getString('dateStyle')] ??
      DateStyle.dayMonthYearSlash;
  set dateStyle(DateStyle style) => _prefs.setString('dateStyle', style.name);

  String formatDate(DateTime date, {bool withYear = true}) =>
      dateStyle.format(date, withYear: withYear);

  // -------------------
  // Benachrichtigungen
  // -------------------
  bool get notificationsEnabled =>
      _prefs.getBool('notificationsEnabled') ?? true;
  set notificationsEnabled(bool enabled) =>
      _prefs.setBool('notificationsEnabled', enabled);

  List<int> get leadDays {
    final stored = _prefs.getStringList('leadDays') ?? const ['0'];
    return stored.map(int.parse).toList()..sort();
  }

  set leadDays(List<int> days) =>
      _prefs.setStringList('leadDays', days.map((d) => '$d').toList());

  TimeOfDay get defaultNotificationTime => TimeOfDay(
    hour: _prefs.getInt('defaultNotificationHour') ?? 12,
    minute: _prefs.getInt('defaultNotificationMinute') ?? 0,
  );

  set defaultNotificationTime(TimeOfDay time) {
    _prefs.setInt('defaultNotificationHour', time.hour);
    _prefs.setInt('defaultNotificationMinute', time.minute);
  }
}
