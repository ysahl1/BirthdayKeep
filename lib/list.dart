/* =========================
   Geburtstagsliste
========================= */
import 'package:BirthdayMarker/main.dart';
import 'package:flutter/material.dart';
import 'calendarWidget.dart';

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

  // -------------------
  // Edit-Dialog für Person
  // -------------------

  void _editPerson(BuildContext context, BirthdayEntry? e) {
    final entry = e ??
        BirthdayEntry(
            name: '', birthday: DateTime.now(), notificationTime: TimeOfDay.now());
    final nameCtrl = TextEditingController(text: entry.name);
    DateTime birthday = entry.birthday;
    TimeOfDay time = entry.notificationTime;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('Edit Birthday'),
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
                  final t = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (t != null) setD(() => time = t);
                },
                child: Text(time.format(context)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                entry.name = nameCtrl.text;
                entry.birthday = birthday;
                entry.notificationTime = time;
                onUpdate(); // Speichert den Eintrag
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------
  // Popup mit Details
  // -------------------
  void _showDetails(BuildContext context, BirthdayEntry e) {
    final age = nextAge(e.birthday);
    final days = daysUntil(e.birthday);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                e.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pop(context); // Popup schließen
                _editPerson(context, e); // Edit-Dialog öffnen
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Birthday: ${e.birthday.day}.${e.birthday.month}.${e.birthday.year}'),
            Text('Reminder: ${e.notificationTime.format(context)}'),
            const SizedBox(height: 8),
            Text(
              days == 0
                  ? "Today is the birthday!"
                  : 'In $days Days (${age} years old)',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // -------------------
  // Build
  // -------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthday List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BirthdayCalendarPage(birthdayEntries: entries, entries: entries),
                ),
              );
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(e.name),
              subtitle: Text(d == 0
                  ? 'Today ${nextAge(e.birthday)}'
                  : 'In $d Days (${nextAge(e.birthday)})'),
              trailing: GestureDetector(
                onTap: () {
                print("Invisible area pressed!");
              _editPerson(context, e);
          },
            child: const SizedBox(
            width: 24,
            height: 24,
  ),
),
              onTap: () => _showDetails(context, e),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () {
         showSearch(
           context: context,
            delegate: BirthdaySearchDelegate(
             entries: entries,
             onSelect: (e) => _showDetails(context, e),
      ),
    );
  },
),    
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// -------------------
// Suchfunktion
// -------------------
class BirthdaySearchDelegate extends SearchDelegate<BirthdayEntry?> {
  final List<BirthdayEntry> entries;
  final void Function(BirthdayEntry) onSelect;

  BirthdaySearchDelegate({
    required this.entries,
    required this.onSelect,
  });

  @override
  String get searchFieldLabel => 'Search Name';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = entries
        .where(
          (e) => e.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return _buildList(context, results);
  }

  @override
Widget buildSuggestions(BuildContext context) {
  if (query.isEmpty) {
    return const Center(
      child: Text(
        ' ',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  final suggestions = entries
      .where(
        (e) => e.name.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();

  return _buildList(context, suggestions);
}

  Widget _buildList(BuildContext context, List<BirthdayEntry> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        return ListTile(
          title: Text(e.name),
          subtitle: Text(
            '${e.birthday.day}.${e.birthday.month}.${e.birthday.year}',
          ),
          onTap: () {
            close(context, e);
            onSelect(e); // 🔥 öffnet Detail-Popup
          },
        );
      },
    );
  }
}

// -------------------
// Kalender-Seite
// -------------------
class BirthdayCalendarPage extends StatelessWidget {
  final List<BirthdayEntry> birthdayEntries;
  
  final dynamic entries;
  const BirthdayCalendarPage({super.key, required this.entries, required this.birthdayEntries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardCalendar(context, ' ', birthdayEntries),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
    
  Widget _cardCalendar(BuildContext context, String title, List<BirthdayEntry> entries) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 350, // Höhe des Kalenders, kann angepasst werden
              child: BirthdayCalendar(
                entries: entries,
                shortDate: (d) {
                  const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
                  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year % 100} ${weekdays[d.weekday - 1]}';
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}