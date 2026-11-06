import 'package:BirthdayMarker/homePage.dart';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/services/biometricService.dart';
import 'package:BirthdayMarker/services/birthdayStore.dart';
import 'package:BirthdayMarker/services/notificationService.dart';
import 'package:BirthdayMarker/screens/authLockScreen.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  await BirthdayStore.instance.load();
  await NotificationService.instance.init();
  await BiometricService().applyScreenProtection();
  runApp(BirthdayMarkerApp());
  NotificationService.instance.reschedule();
}

class BirthdayEntry {
  String name;
  DateTime birthday;
  TimeOfDay notificationTime;
  bool notificationsEnabled;
  bool yearKnown;

  BirthdayEntry({
    required this.name,
    required this.birthday,
    required this.notificationTime,
    this.notificationsEnabled = true,
    this.yearKnown = true,
  });

  // Ohne bekanntes Jahr zählt nur Tag und Monat. Das Schaltjahr 2000 erhält
  // dabei auch den 29. Februar.
  static DateTime unknownYearDate(DateTime date) =>
      DateTime(2000, date.month, date.day);

  String get formattedDate =>
      AppSettings.instance.formatDate(birthday, withYear: yearKnown);

  Map<String, dynamic> toJson() => {
    'name': name,
    'birthday': birthday.toIso8601String(),
    'notificationHour': notificationTime.hour,
    'notificationMinute': notificationTime.minute,
    'notificationsEnabled': notificationsEnabled,
    'yearKnown': yearKnown,
  };

  factory BirthdayEntry.fromJson(Map<String, dynamic> json) {
    return BirthdayEntry(
      name: json['name'] as String,
      birthday: DateTime.parse(json['birthday'] as String),
      notificationTime: TimeOfDay(
        hour: json['notificationHour'] as int,
        minute: json['notificationMinute'] as int,
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      yearKnown: json['yearKnown'] as bool? ?? true,
    );
  }
}

class BirthdayMarkerApp extends StatefulWidget {
  BirthdayMarkerApp({super.key});

  @override
  State<BirthdayMarkerApp> createState() => _BirthdayMarkerAppState();
}

class _BirthdayMarkerAppState extends State<BirthdayMarkerApp> {
  final AppSettings _settings = AppSettings.instance;
  late final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    _settings.themeMode,
  );
  late final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    _settings.locale,
  );
  late final ValueNotifier<Color> accentColorNotifier = ValueNotifier(
    _settings.accentColor,
  );
  late final ValueNotifier<bool> amoledNotifier = ValueNotifier(
    _settings.amoled,
  );

  final BiometricService _biometricService = BiometricService();

  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => _settings.themeMode = themeNotifier.value);
    accentColorNotifier.addListener(
      () => _settings.accentColor = accentColorNotifier.value,
    );
    amoledNotifier.addListener(() => _settings.amoled = amoledNotifier.value);
    localeNotifier.addListener(() {
      _settings.locale = localeNotifier.value;
      // Bereits geplante Erinnerungen sollen in der neuen Sprache erscheinen
      NotificationService.instance.reschedule();
    });
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final lockMode = await _biometricService.getLockMode();
    setState(() {
      _isAuthenticated = lockMode == LockMode.off;
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

  // AMOLED: reines Schwarz als Hintergrund, Karten bleiben knapp darüber sichtbar
  ThemeData _darkTheme(Color accentColor, bool amoled) {
    var scheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
    );
    if (amoled) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF0E0E0E),
        surfaceContainer: const Color(0xFF141414),
        surfaceContainerHigh: const Color(0xFF1C1C1C),
        surfaceContainerHighest: const Color(0xFF242424),
      );
    }
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: amoled ? Colors.black : null,
      pageTransitionsTheme: _pageTransitions,
    );
  }

  static const List<LocalizationsDelegate<dynamic>> _localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> _supportedLocales = [Locale('de'), Locale('en')];

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
        locale: localeNotifier.value,
        supportedLocales: _supportedLocales,
        localizationsDelegates: _localizationsDelegates,
        home: AuthLockScreen(onAuthenticated: _onAuthenticated),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: amoledNotifier,
      builder:
          (_, __, ___) => ValueListenableBuilder<Color>(
            valueListenable: accentColorNotifier,
            builder: (_, accentColor, __) {
              return ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, themeMode, __) {
                  return ValueListenableBuilder<Locale>(
                    valueListenable: localeNotifier,
                    builder: (_, locale, __) {
                      return MaterialApp(
                        title: AppStrings.appName,
                        debugShowCheckedModeBanner: false,
                        themeMode: themeMode,
                        theme: ThemeData(
                          useMaterial3: true,
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: accentColor,
                          ),
                          pageTransitionsTheme: _pageTransitions,
                        ),
                        darkTheme: _darkTheme(
                          accentColor,
                          amoledNotifier.value,
                        ),
                        locale: locale,
                        supportedLocales: _supportedLocales,
                        localizationsDelegates: _localizationsDelegates,
                        home: BirthdayHomePage(
                          themeNotifier: themeNotifier,
                          localeNotifier: localeNotifier,
                          accentColorNotifier: accentColorNotifier,
                          amoledNotifier: amoledNotifier,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
    );
  }
}
