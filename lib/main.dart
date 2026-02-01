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
}

class BirthdayMarkerApp extends StatefulWidget {
  BirthdayMarkerApp({super.key});

  @override
  State<BirthdayMarkerApp> createState() => _BirthdayMarkerAppState();
}

class _BirthdayMarkerAppState extends State<BirthdayMarkerApp> {
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
  final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));
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

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
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
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                  },
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                  },
                ),
              ),
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