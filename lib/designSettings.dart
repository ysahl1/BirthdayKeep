import 'package:flutter/material.dart';

class BirthdayDesignSettings extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<Locale> localeNotifier;
  final ValueNotifier<Color> accentColorNotifier;

  const BirthdayDesignSettings({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
    required this.accentColorNotifier,
  });

  static const List<_AccentColor> _accentColors = [
    _AccentColor('Blue',    Color(0xFF2196F3)),
    _AccentColor('Violet',  Color(0xFF7C3AED)),
    _AccentColor('Pink',    Color(0xFFE91E8C)),
    _AccentColor('Green',   Color(0xFF4CAF50)),
    _AccentColor('Teal',    Color(0xFF009688)),
    _AccentColor('Red',     Color(0xFFF44336)),
    _AccentColor('Orange',  Color(0xFFFF9800)),
    _AccentColor('Yellow',  Color(0xFFFFC107)),
    _AccentColor('Beige',   Color(0xFFD4A373)),
    _AccentColor('Brown',   Color(0xFF795548)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.light_mode),
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

          // Accent Color Card
          Card(
            child: ValueListenableBuilder<Color>(
              valueListenable: accentColorNotifier,
              builder: (_, color, __) {
                final colorName = _accentColors
                    .firstWhere(
                      (c) => c.color.value == color.value,
                      orElse: () => _AccentColor('Custom', color),
                    )
                    .name;
                return ListTile(
                  leading: const Icon(Icons.brush),
                  title: const Text('Theme Color'),
                  subtitle: Text(colorName),
                  onTap: () => _showAccentColorDialog(context),
                );
              },
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
                  return Text(
                      locale.languageCode == 'de' ? 'Deutsch' : 'English');
                },
              ),
              onTap: () => _showLanguageDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccentColorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ValueListenableBuilder<Color>(
        valueListenable: accentColorNotifier,
        builder: (_, selectedColor, __) {
          return AlertDialog(
            title: const Text('Choose Theme Color'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: _accentColors.map((accentColor) {
                final isSelected =
                    accentColor.color.value == selectedColor.value;
                return RadioListTile<Color>(
                  value: accentColor.color,
                  groupValue: selectedColor,
                  onChanged: (value) {
                    accentColorNotifier.value = value!;
                    Navigator.pop(context);
                  },
                  title: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: accentColor.color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                      ),
                      Text(accentColor.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
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

class _AccentColor {
  final String name;
  final Color color;
  const _AccentColor(this.name, this.color);
}