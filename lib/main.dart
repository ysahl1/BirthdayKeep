import 'package:flutter/material.dart';

void main() {
  runApp(BirthdayMarkerApp());
}

class BirthdayEntry {
  String name;
  DateTime birthday;
  DateTime notification;

  BirthdayEntry({
    required this.name,
    required this.birthday,
    required this.notification,
  });
}

class BirthdayMarkerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BirthdayMarker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BirthdayHomePage(),
    );
  }
}

class BirthdayHomePage extends StatefulWidget {
  @override
  _BirthdayHomePageState createState() => _BirthdayHomePageState();
}

class _BirthdayHomePageState extends State<BirthdayHomePage> {
  List<BirthdayEntry> entries = [];

  void _showAddEntryDialog() {
    final nameController = TextEditingController();
    DateTime? birthday;
    DateTime? notification;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Neuen Eintrag hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) birthday = picked;
                  },
                  child: Text('Geburtstag auswählen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) notification = picked;
                  },
                  child: Text('Benachrichtigung auswählen'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    birthday != null &&
                    notification != null) {
                  setState(() {
                    entries.add(BirthdayEntry(
                      name: nameController.text,
                      birthday: birthday!,
                      notification: notification!,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }

  void _showEntriesList() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              title: Text(entry.name),
              subtitle: Text(
                  'Geburtstag: ${entry.birthday.toLocal().toString().split(' ')[0]}, Benachrichtigung: ${entry.notification.toLocal().toString().split(' ')[0]}'),
            );
          },
        );
      },
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Einstellungen'),
        content: Text('Hier kannst du Einstellungen vornehmen (noch leer)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BirthdayMarker'),
      ),
      body: Center(
        child: Text(
          'Willkommen zu BirthdayMarker!',
          style: TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.list),
                onPressed: _showEntriesList,
              ),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: _showSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}