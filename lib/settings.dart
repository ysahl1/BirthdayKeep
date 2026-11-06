import 'package:BirthdayMarker/stretchListView.dart';
import 'package:flutter/material.dart';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/privacySettings.dart';
import 'package:BirthdayMarker/designSettings.dart';
import 'package:BirthdayMarker/notificationSettings.dart';
import 'package:BirthdayMarker/aboutBirthdayMarkerPage.dart';

class SettingsPage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<Locale> localeNotifier;
  final ValueNotifier<Color> accentColorNotifier;
  final ValueNotifier<bool> amoledNotifier;

  const SettingsPage({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
    required this.accentColorNotifier,
    required this.amoledNotifier,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: StretchListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            context,
            Icons.security,
            s.privacy,
            const BirthdayPrivacySettings(),
          ),
          _card(
            context,
            Icons.notifications,
            s.notifications,
            const NotificationSettingsPage(),
          ),
          _card(
            context,
            Icons.palette,
            s.design,
            BirthdayDesignSettings(
              themeNotifier: widget.themeNotifier,
              localeNotifier: widget.localeNotifier,
              accentColorNotifier: widget.accentColorNotifier,
              amoledNotifier: widget.amoledNotifier,
            ),
          ),
          _card(
            context,
            Icons.info_outline,
            s.about,
            const aboutBirthdayMarkerPage(),
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
