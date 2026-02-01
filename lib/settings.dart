import 'package:flutter/material.dart';
import 'package:BirthdayMarker/privacySettings.dart';
import 'package:BirthdayMarker/designSettings.dart';


class SettingsPage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<Locale> localeNotifier;

  const SettingsPage({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            context,
            Icons.security,
            'Privacy & Security',
            const BirthdayPrivacySettings(),
          ),
          _card(
            context,
            Icons.notifications,
            'Notification',
            const PlaceholderPage(title: 'Notification'),
          ),
          _card(
            context,
            Icons.palette,
            'Design',
            BirthdayDesignSettings(
              themeNotifier: widget.themeNotifier,
              localeNotifier: widget.localeNotifier,
            ),
          ),
          _card(
            context,
            Icons.info_outline,
            'About Birthday Marker',
            const PlaceholderPage(title: 'About Birthday Marker'),
          ),
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

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}