import 'package:BirthdayMarker/homePage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(BirthdayMarkerApp());
}

/* =========================
   Datenmodell
========================= */
class BirthdayEntry {
  String name;
  DateTime birthday;
  TimeOfDay notificationTime;

  BirthdayEntry({
    required this.name,
    required this.birthday,
    required this.notificationTime,
  });
}

/* =========================
   App
========================= */
class BirthdayMarkerApp extends StatelessWidget {
   BirthdayMarkerApp({super.key});
  
  final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.system);
  final ValueNotifier<Locale> localeNotifier =
    ValueNotifier(const Locale('en'));

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
  valueListenable: themeNotifier,
  builder: (_, themeMode, __) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (_, locale, __) {
        return MaterialApp(
          title: 'BirthdayMarker',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
          darkTheme: ThemeData.dark(useMaterial3: true),
          locale: locale,
          supportedLocales: const [
            Locale('de'),
            Locale('en'),
          ],
          home: BirthdayHomePage(
            themeNotifier: themeNotifier,
            localeNotifier: localeNotifier,
      ),
        );
      },
    );
  },
    );
  }
}