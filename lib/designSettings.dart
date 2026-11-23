import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/feedback.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/services/homeIntegration.dart';
import 'package:BirthdayMarker/stretchListView.dart';
import 'package:flutter/material.dart';

class BirthdayDesignSettings extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<Locale> localeNotifier;
  final ValueNotifier<Color> accentColorNotifier;
  final ValueNotifier<bool> amoledNotifier;

  const BirthdayDesignSettings({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
    required this.accentColorNotifier,
    required this.amoledNotifier,
  });

  @override
  State<BirthdayDesignSettings> createState() => _BirthdayDesignSettingsState();
}

class _BirthdayDesignSettingsState extends State<BirthdayDesignSettings> {
  ValueNotifier<ThemeMode> get themeNotifier => widget.themeNotifier;
  ValueNotifier<Locale> get localeNotifier => widget.localeNotifier;
  ValueNotifier<Color> get accentColorNotifier => widget.accentColorNotifier;
  ValueNotifier<bool> get amoledNotifier => widget.amoledNotifier;

  static const List<_AccentColor> _accentColors = [
    _AccentColor('Blue', Color(0xFF2196F3)),
    _AccentColor('Violet', Color(0xFF7C3AED)),
    _AccentColor('Pink', Color(0xFFE91E8C)),
    _AccentColor('Green', Color(0xFF4CAF50)),
    _AccentColor('Teal', Color(0xFF009688)),
    _AccentColor('Red', Color(0xFFF44336)),
    _AccentColor('Orange', Color(0xFFFF9800)),
    _AccentColor('Yellow', Color(0xFFFFC107)),
    _AccentColor('Beige', Color(0xFFD4A373)),
    _AccentColor('Brown', Color(0xFF795548)),
  ];

  AppIcon _appIcon = AppIcon.cake;

  @override
  void initState() {
    super.initState();
    HomeIntegration.instance.getAppIcon().then((icon) {
      if (mounted) setState(() => _appIcon = icon);
    });
  }

  void _showAppIconDialog(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(s.chooseAppIcon),
            content: SizedBox(
              width: 280,
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  for (final icon in AppIcon.values)
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        if (icon == _appIcon) return;
                        await HomeIntegration.instance.setAppIcon(icon);
                        if (!mounted) return;
                        setState(() => _appIcon = icon);
                        showFeedback(this.context, s.appIconChanged);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                width: 3,
                                color:
                                    icon == _appIcon
                                        ? colors.primary
                                        : Colors.transparent,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                icon.asset,
                                width: 72,
                                height: 72,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.appIconName(icon),
                            style: TextStyle(
                              fontWeight:
                                  icon == _appIcon
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.design)),
      body: StretchListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Icon Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: Text(s.appIcon),
              subtitle: Text(s.appIconName(_appIcon)),
              onTap: () => _showAppIconDialog(context),
            ),
          ),

          // Appearance Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.light_mode),
              title: Text(s.appearance),
              subtitle: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, mode, __) {
                  return Text(
                    mode == ThemeMode.dark
                        ? s.dark
                        : mode == ThemeMode.light
                        ? s.light
                        : s.system,
                  );
                },
              ),
              onTap: () => _showThemeDialog(context),
            ),
          ),

          // Accent Color Card
          Card(
            child: ValueListenableBuilder<Color>(
              valueListenable: accentColorNotifier,
              builder: (_, color, __) {
                final colorName =
                    _accentColors
                        .firstWhere(
                          (c) => c.color.toARGB32() == color.toARGB32(),
                          orElse: () => _AccentColor(s.custom, color),
                        )
                        .name;
                return ListTile(
                  leading: const Icon(Icons.brush),
                  title: Text(s.themeColor),
                  subtitle: Text(s.colorName(colorName)),
                  onTap: () => _showAccentColorDialog(context),
                );
              },
            ),
          ),

          // AMOLED Card
          Card(
            child: ValueListenableBuilder<bool>(
              valueListenable: amoledNotifier,
              builder: (_, amoled, __) {
                return ListTile(
                  leading: const Icon(Icons.contrast),
                  title: Text(s.amoled),
                  subtitle: Text(amoled ? s.on : s.off),
                  onTap: () => _showAmoledDialog(context),
                );
              },
            ),
          ),

          // Language Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(s.language),
              subtitle: ValueListenableBuilder<Locale>(
                valueListenable: localeNotifier,
                builder: (_, locale, __) {
                  return Text(
                    locale.languageCode == 'de' ? 'Deutsch' : 'English',
                  );
                },
              ),
              onTap: () => _showLanguageDialog(context),
            ),
          ),

          // Start Page Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(s.startPage),
              subtitle: Text(
                _startPageLabel(s, AppSettings.instance.startPage),
              ),
              onTap: () => _showStartPageDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  String _startPageLabel(AppStrings s, StartPage page) {
    return switch (page) {
      StartPage.home => s.pageHome,
      StartPage.list => s.birthdayList,
      StartPage.calendar => s.calendar,
      StartPage.settings => s.settings,
    };
  }

  void _showStartPageDialog(BuildContext context) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(s.chooseStartPage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  StartPage.values.map((page) {
                    return RadioListTile<StartPage>(
                      title: Text(_startPageLabel(s, page)),
                      value: page,
                      groupValue: AppSettings.instance.startPage,
                      onChanged: (value) {
                        setState(() => AppSettings.instance.startPage = value!);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _showAccentColorDialog(BuildContext context) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder:
          (context) => ValueListenableBuilder<Color>(
            valueListenable: accentColorNotifier,
            builder: (_, selectedColor, __) {
              return AlertDialog(
                title: Text(s.chooseThemeColor),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      _accentColors.map((accentColor) {
                        final isSelected =
                            accentColor.color.toARGB32() ==
                            selectedColor.toARGB32();
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
                                  border:
                                      isSelected
                                          ? Border.all(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            width: 2,
                                          )
                                          : null,
                                ),
                              ),
                              Text(s.colorName(accentColor.name)),
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

  void _showAmoledDialog(BuildContext context) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(s.amoled),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.amoledHint),
                const SizedBox(height: 8),
                for (final value in const [true, false])
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(value ? s.on : s.off),
                    value: value,
                    groupValue: amoledNotifier.value,
                    onChanged: (selected) {
                      amoledNotifier.value = selected!;
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(s.chooseAppearance),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(s.light),
                  value: ThemeMode.light,
                  groupValue: themeNotifier.value,
                  onChanged: (value) {
                    themeNotifier.value = value!;
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(s.dark),
                  value: ThemeMode.dark,
                  groupValue: themeNotifier.value,
                  onChanged: (value) {
                    themeNotifier.value = value!;
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(s.system),
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
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(s.chooseLanguage),
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
