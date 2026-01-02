import 'package:flutter/material.dart';

/* =========================
   Theme Settings
========================= */
class ThemeSettingsPage extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const ThemeSettingsPage({
    super.key,
    required this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Design")),
      body: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text("System"),
            value: ThemeMode.system,
            groupValue: themeNotifier.value,
            onChanged: (value) => themeNotifier.value = value!,
          ),
          RadioListTile<ThemeMode>(
            title: const Text("Light"),
            value: ThemeMode.light,
            groupValue: themeNotifier.value,
            onChanged: (value) => themeNotifier.value = value!,
          ),
          RadioListTile<ThemeMode>(
            title: const Text("Dark"),
            value: ThemeMode.dark,
            groupValue: themeNotifier.value,
            onChanged: (value) => themeNotifier.value = value!,
          ),
        ],
      ),
    );
  }
}
/* =========================
   Language Settings
========================= */
class LanguageSettingsPage extends StatelessWidget {
  final ValueNotifier<Locale> localeNotifier;

  const LanguageSettingsPage({
    super.key,
    required this.localeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Language")),
      body: Column(
        children: [
          RadioListTile<Locale>(
            title: const Text("Deutsch"),
            value: const Locale('de'),
            groupValue: localeNotifier.value,
            onChanged: (value) => localeNotifier.value = value!,
          ),
          RadioListTile<Locale>(
            title: const Text("English"),
            value: const Locale('en'),
            groupValue: localeNotifier.value,
            onChanged: (value) => localeNotifier.value = value!,
          ),
        ],
      ),
    );
  }
}