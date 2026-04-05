import 'package:BirthdayMarker/homePage.dart';
import 'package:BirthdayMarker/services/biometricService.dart';
import 'package:BirthdayMarker/screens/authLockScreen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(BirthdayMarkerApp());
}

class BirthdayEntry {
  String name;
  DateTime birthday;
  TimeOfDay notificationTime;

  BirthdayEntry({
    required this.name,
    required this.birthday,
    required this.notificationTime,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'birthday': birthday.toIso8601String(),
        'notificationHour': notificationTime.hour,
        'notificationMinute': notificationTime.minute,
      };

  factory BirthdayEntry.fromJson(Map<String, dynamic> json) {
    return BirthdayEntry(
      name: json['name'] as String,
      birthday: DateTime.parse(json['birthday'] as String),
      notificationTime: TimeOfDay(
        hour: json['notificationHour'] as int,
        minute: json['notificationMinute'] as int,
      ),
    );
  }
}

class BirthdayMarkerApp extends StatefulWidget {
  BirthdayMarkerApp({super.key});

  @override
  State<BirthdayMarkerApp> createState() => _BirthdayMarkerAppState();
}

class _BirthdayMarkerAppState extends State<BirthdayMarkerApp> {
  final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);
  final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));
  final ValueNotifier<Color> accentColorNotifier =
      ValueNotifier(Colors.blue);

  final BiometricService _biometricService = BiometricService();

  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final biometricEnabled = await _biometricService.isBiometricEnabled();
    setState(() {
      _isAuthenticated = !biometricEnabled;
      _isCheckingAuth = false;
    });
  }

  void _onAuthenticated() {
    setState(() => _isAuthenticated = true);
  }

  PageTransitionsTheme get _pageTransitions => const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      );

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (!_isAuthenticated) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 51, 37, 185),
            brightness: Brightness.dark,
          ),
        ),
        home: AuthLockScreen(onAuthenticated: _onAuthenticated),
      );
    }

    return ValueListenableBuilder<Color>(
      valueListenable: accentColorNotifier,
      builder: (_, accentColor, __) {
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
                  theme: ThemeData(
                    useMaterial3: true,
                    colorScheme:
                        ColorScheme.fromSeed(seedColor: accentColor),
                    pageTransitionsTheme: _pageTransitions,
                  ),
                  darkTheme: ThemeData(
                    useMaterial3: true,
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: accentColor,
                      brightness: Brightness.dark,
                    ),
                    pageTransitionsTheme: _pageTransitions,
                  ),
                  locale: locale,
                  supportedLocales: const [
                    Locale('de'),
                    Locale('en'),
                  ],
                  home: BirthdayHomePage(
                    themeNotifier: themeNotifier,
                    localeNotifier: localeNotifier,
                    accentColorNotifier: accentColorNotifier,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}