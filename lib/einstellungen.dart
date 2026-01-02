import 'package:flutter/material.dart';
import 'package:BirthdayMarker/datenschutzEinstellungen.dart';
import 'package:BirthdayMarker/design.dart';

class SettingsPage extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<Locale> localeNotifier;

  const SettingsPage({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
  });

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
            const PrivacySecurityPage(),
          ),
          _card(
            context,
            Icons.notifications,
            'Notification',
            const PlaceholderPage(title: 'Notification') as Widget,
          ),
          _card(
            context,
            Icons.palette,
            'Design',
            ThemeSettingsPage(
              themeNotifier: themeNotifier,
            ),
          ),
          _card(
            context,
            Icons.language,
            'Language',
            LanguageSettingsPage(
              localeNotifier: localeNotifier,
            ),
          ),
          _card(
            context,
            Icons.info_outline,
            'About Birthday Marker',
            const PlaceholderPage(title: 'About Birthday Marker') as Widget,
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
        trailing: const Icon(Icons.arrow_forward),
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