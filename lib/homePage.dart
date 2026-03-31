/* =========================
   Home Page
========================= */
import 'dart:convert';
import 'package:BirthdayMarker/settings.dart';
import 'package:BirthdayMarker/list.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthdayHomePage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<Locale> localeNotifier;

  const BirthdayHomePage({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
  });

  @override
  State<BirthdayHomePage> createState() => _BirthdayHomePageState();
}

class _BirthdayHomePageState extends State<BirthdayHomePage> {
  final List<BirthdayEntry> entries = [];
  static const String _storageKey = 'birthday_entries';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  // -------------------
  // Laden & Speichern
  // -------------------

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        entries.clear();
        entries.addAll(jsonList.map((e) => BirthdayEntry.fromJson(e as Map<String, dynamic>)));
      });
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  // -------------------
  // Hilfsfunktionen
  // -------------------

  int nextAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    final bThisYear = DateTime(now.year, birthday.month, birthday.day);
    return now.isBefore(bThisYear) ? age : age + 1;
  }

  int daysUntil(DateTime birthday) {
    final now = DateTime.now();
    DateTime next = DateTime(now.year, birthday.month, birthday.day);
    if (next.isBefore(now)) next = DateTime(now.year + 1, birthday.month, birthday.day);
    return next.difference(now).inDays;
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Exit BirthdayMarker'),
          ],
        ),
        content: const Text('Are you sure you want to close the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
    
    return false;
  }

  void _addEntryDialog() {
    final nameCtrl = TextEditingController();
    DateTime? birthday;
    TimeOfDay? time;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('Add Birthday'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2027),
                  );
                  if (d != null) setD(() => birthday = d);
                },
                child: Text(birthday == null
                    ? 'Choose Birthday'
                    : '${birthday!.day}.${birthday!.month}.${birthday!.year}'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (t != null) setD(() => time = t);
                },
                child: Text(time == null ? 'Time of Reminder' : time!.format(context)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && birthday != null && time != null) {
                  setState(() {
                    entries.add(BirthdayEntry(
                      name: nameCtrl.text,
                      birthday: birthday!,
                      notificationTime: time!,
                    ));
                  });
                  _saveEntries(); // ← nach jedem Hinzufügen speichern
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: _addEntryDialog,
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BirthdayListPage(
                        entries: entries,
                        nextAge: nextAge,
                        daysUntil: daysUntil,
                        onUpdate: () {
                          setState(() {});
                          _saveEntries(); // ← nach jedem Edit speichern
                        },
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(
                        themeNotifier: widget.themeNotifier,
                        localeNotifier: widget.localeNotifier,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}