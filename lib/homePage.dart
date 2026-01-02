/* =========================
   Home Page
========================= */
import 'package:BirthdayMarker/einstellungen.dart';
import 'package:BirthdayMarker/geburtstagsliste.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
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
                      onUpdate: () => setState(() {}),
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
          );
        }
      }