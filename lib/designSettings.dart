import 'package:flutter/material.dart';

class BirthdayDesignSettings extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<Locale> localeNotifier;

  const BirthdayDesignSettings({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Card with Routine Icon
          Card(
            child: ListTile(
              leading: const Icon(Icons.light_mode), // Routine Icon
              title: const Text('Appearance'),
              subtitle: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, mode, __) {
                  return Text(mode == ThemeMode.dark
                      ? 'Dark'
                      : mode == ThemeMode.light
                          ? 'Light'
                          : 'System');
                },
              ),
              onTap: () => _showThemeDialog(context),
            ),
          ),
          const SizedBox(height: 8),
          // Language Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: ValueListenableBuilder<Locale>(
                valueListenable: localeNotifier,
                builder: (_, locale, __) {
                  return Text(locale.languageCode == 'de' ? 'Deutsch' : 'English');
                },
              ),
              onTap: () => _showLanguageDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Appearance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeNotifier.value,
              onChanged: (value) {
                themeNotifier.value = value!;
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeNotifier.value,
              onChanged: (value) {
                themeNotifier.value = value!;
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: themeNotifier.value,
              onChanged: (value) {
                themeNotifier.value = value!;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale>(
              title: const Text('English'),
              value: const Locale('en'),
              groupValue: localeNotifier.value,
              onChanged: (value) {
                localeNotifier.value = value!;
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale>(
              title: const Text('Deutsch'),
              value: const Locale('de'),
              groupValue: localeNotifier.value,
              onChanged: (value) {
                localeNotifier.value = value!;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}