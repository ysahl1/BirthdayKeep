import 'package:flutter/material.dart';

void main() {
  runApp(const BirthdayMarkerApp());
}

/* =========================
   Datenmodell
========================= */
class BirthdayEntry {
  String name;
  DateTime birthday;
  TimeOfDay notificationTime;

  BirthdayEntry({
    required this.name,
    required this.birthday,
    required this.notificationTime,
  });
}

/* =========================
   App
========================= */
class BirthdayMarkerApp extends StatelessWidget {
  const BirthdayMarkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BirthdayMarker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const BirthdayHomePage(),
    );
  }
}

/* =========================
   Home Page
========================= */
class BirthdayHomePage extends StatefulWidget {
  const BirthdayHomePage({super.key});

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
          title: const Text('Geburtstag hinzufügen'),
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
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setD(() => birthday = d);
                },
                child: Text(birthday == null
                    ? 'Geburtstag wählen'
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
                child: Text(time == null ? 'Erinnerungszeit' : time!.format(context)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
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
              child: const Text('Speichern'),
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
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   Geburtstagsliste
========================= */
class BirthdayListPage extends StatelessWidget {
  final List<BirthdayEntry> entries;
  final int Function(DateTime) nextAge;
  final int Function(DateTime) daysUntil;
  final VoidCallback onUpdate;

  const BirthdayListPage({
    super.key,
    required this.entries,
    required this.nextAge,
    required this.daysUntil,
    required this.onUpdate,
  });

  void _editPerson(BuildContext context, BirthdayEntry e) async {
    final nameCtrl = TextEditingController(text: e.name);
    DateTime birthday = e.birthday;
    TimeOfDay time = e.notificationTime;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('Bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              ElevatedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: birthday,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setD(() => birthday = d);
                },
                child: Text('${birthday.day}.${birthday.month}.${birthday.year}'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final t = await showTimePicker(context: context, initialTime: time);
                  if (t != null) setD(() => time = t);
                },
                child: Text(time.format(context)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                e.name = nameCtrl.text;
                e.birthday = birthday;
                e.notificationTime = time;
                onUpdate();
                Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, BirthdayEntry e) {
    final age = nextAge(e.birthday);
    final days = daysUntil(e.birthday);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(e.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎂 Wird $age Jahre alt'),
            Text('⏰ Erinnerung: ${e.notificationTime.format(context)}'),
            const SizedBox(height: 8),
            Text(days == 0 ? '🎉 Geburtstag ist heute!' : '⏳ In $days Tagen'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geburtstage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BirthdayCalendarPage(entries: entries)));
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          final d = daysUntil(e.birthday);

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(e.name),
              subtitle: Text(d == 0 ? '🎉 Heute ${nextAge(e.birthday)}' : 'In $d Tagen (${nextAge(e.birthday)})'),
              trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _editPerson(context, e)),
              onTap: () => _showDetails(context, e),
            ),
          );
        },
      ),
    );
  }
}

/* =========================
   Kalender Screen
========================= */
class BirthdayCalendarPage extends StatelessWidget {
  final List<BirthdayEntry> entries;
  const BirthdayCalendarPage({super.key, required this.entries});

  String shortDate(DateTime d) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final wd = weekdays[d.weekday - 1];
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year % 100} $wd';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: BirthdayCalendar(entries: entries, shortDate: shortDate),
    );
  }
}

/* =========================
   Kalender Widget
========================= */
class BirthdayCalendar extends StatefulWidget {
  final List<BirthdayEntry> entries;
  final String Function(DateTime) shortDate;

  const BirthdayCalendar({super.key, required this.entries, required this.shortDate});

  @override
  State<BirthdayCalendar> createState() => _BirthdayCalendarState();
}

class _BirthdayCalendarState extends State<BirthdayCalendar> {
  DateTime month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)),
            ),
            Text('${month.month}.${month.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)),
            ),
          ],
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: days + offset,
            itemBuilder: (_, i) {
              if (i < offset) return const SizedBox();
              final day = DateTime(month.year, month.month, i - offset + 1);
              final birthdays = widget.entries.where((e) => e.birthday.day == day.day && e.birthday.month == day.month);

              return Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: birthdays.isNotEmpty ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.day}'),
                    if (birthdays.isNotEmpty)
                      Text(widget.shortDate(day), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* =========================
   Einstellungen
========================= */
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(context, Icons.security, 'Datenschutz & Sicherheit', const PrivacySecurityPage()),
          _card(context, Icons.notifications, 'Erinnerungen', const PlaceholderPage(title: 'Erinnerungen')),
          _card(context, Icons.palette, 'Design', const PlaceholderPage(title: 'Design')),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title, Widget page) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}

/* =========================
   Datenschutz
========================= */
class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datenschutz & Sicherheit')),
      body: const Center(child: Text('Alle Daten bleiben lokal auf dem Gerät')),
    );
  }
}

/* =========================
   Platzhalter
========================= */
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Kommt noch')),
    );
  }
}