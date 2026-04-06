import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(context, Icons.date_range, 'Date Template',
              const _PlaceholderPage(title: 'Date Template')),
          _card(context, Icons.repeat, 'Automatic Notification',
              const _PlaceholderPage(title: 'Automatic Notification')),
          _card(context, Icons.notifications_active, 'Disable Notifications',
              const _PlaceholderPage(title: 'Disable Notifications')),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title, Widget page) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    ); 
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text(
          'Function incoming',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}