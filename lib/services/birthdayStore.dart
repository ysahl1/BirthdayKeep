import 'dart:convert';
import 'package:BirthdayMarker/main.dart';
import 'package:BirthdayMarker/services/homeIntegration.dart';
import 'package:BirthdayMarker/services/notificationService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthdayStore {
  BirthdayStore._();
  static final BirthdayStore instance = BirthdayStore._();

  static const String _storageKey = 'birthday_entries';

  final List<BirthdayEntry> entries = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    entries.clear();
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      entries.addAll(
        jsonList.map((e) => BirthdayEntry.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  // Speichert die Liste und plant alle Erinnerungen neu
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
    await NotificationService.instance.reschedule();
    await HomeIntegration.instance.refreshWidgets();
  }

  Future<void> replaceAll(List<BirthdayEntry> newEntries) async {
    entries
      ..clear()
      ..addAll(newEntries);
    await save();
  }
}
