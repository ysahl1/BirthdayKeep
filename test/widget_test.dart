import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BirthdayMarker/aboutBirthdayMarkerPage.dart';
import 'package:BirthdayMarker/birthdayPicker.dart';
import 'package:BirthdayMarker/calendarWidget.dart';
import 'package:BirthdayMarker/homePage.dart';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/list.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:BirthdayMarker/notificationSettings.dart';
import 'package:BirthdayMarker/privacySettings.dart';
import 'package:BirthdayMarker/screenLockSettings.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/screens/authLockScreen.dart';
import 'package:BirthdayMarker/screens/pinPad.dart';
import 'package:BirthdayMarker/services/biometricService.dart';
import 'package:BirthdayMarker/services/birthdayStore.dart';
import 'package:BirthdayMarker/services/exportService.dart';
import 'package:BirthdayMarker/services/notificationService.dart';
import 'package:shared_preferences/shared_preferences.dart';

BirthdayEntry _entry(
  String name,
  DateTime birthday, {
  bool enabled = true,
  int hour = 9,
}) => BirthdayEntry(
  name: name,
  birthday: birthday,
  notificationTime: TimeOfDay(hour: hour, minute: 0),
  notificationsEnabled: enabled,
);

Widget _localized(Widget home, {Locale locale = const Locale('de')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('de'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

Widget _homePage({Locale locale = const Locale('de')}) => _localized(
  BirthdayHomePage(
    themeNotifier: ValueNotifier(ThemeMode.light),
    localeNotifier: ValueNotifier(locale),
    accentColorNotifier: ValueNotifier(Colors.blue),
    amoledNotifier: ValueNotifier(false),
  ),
  locale: locale,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.load();
    BirthdayStore.instance.entries.clear();
  });

  group('Erinnerungen planen', () {
    final now = DateTime(2026, 11, 3, 12);

    test('nimmt den nächsten Termin, die nächste Erinnerung zuerst', () {
      final plan = NotificationService.plan(
        [
          _entry('Später', DateTime(1990, 12, 24)),
          _entry('Bald', DateTime(1990, 11, 10)),
        ],
        [0, 3],
        now,
      );

      expect(plan.map((r) => r.fireAt).toList(), [
        DateTime(2026, 11, 7, 9),
        DateTime(2026, 11, 10, 9),
        DateTime(2026, 12, 21, 9),
        DateTime(2026, 12, 24, 9),
      ]);
      expect(plan.first.entry.name, 'Bald');
      expect(plan.first.leadDays, 3);
    });

    test('schiebt vergangene Termine ins nächste Jahr', () {
      final plan = NotificationService.plan(
        [_entry('Vorbei', DateTime(1990, 1, 5))],
        [0],
        now,
      );
      expect(plan.single.fireAt, DateTime(2027, 1, 5, 9));
    });

    test('Termin heute: noch ausstehend oder schon vorbei', () {
      final later = NotificationService.plan(
        [_entry('A', DateTime(1990, 11, 3), hour: 18)],
        [0],
        now,
      );
      expect(later.single.fireAt, DateTime(2026, 11, 3, 18));

      final past = NotificationService.plan(
        [_entry('B', DateTime(1990, 11, 3), hour: 8)],
        [0],
        now,
      );
      expect(past.single.fireAt, DateTime(2027, 11, 3, 8));
    });

    test('Vorlauf über den Jahreswechsel', () {
      final plan = NotificationService.plan(
        [_entry('Neujahr', DateTime(1990, 1, 2))],
        [14],
        now,
      );
      expect(plan.single.fireAt, DateTime(2026, 12, 19, 9));
    });

    test('29. Februar wird außerhalb von Schaltjahren am 28. erinnert', () {
      final plan = NotificationService.plan(
        [_entry('Schalttag', DateTime(2000, 2, 29))],
        [0],
        now,
      );
      expect(plan.single.fireAt, DateTime(2027, 2, 28, 9));
    });

    test('ausgeschlossene Personen werden übersprungen', () {
      final plan = NotificationService.plan(
        [
          _entry('Ausgeschlossen', DateTime(1990, 12, 1), enabled: false),
          _entry('Dabei', DateTime(1990, 12, 2)),
        ],
        [0],
        now,
      );
      expect(plan.single.entry.name, 'Dabei');
    });
  });

  group('Backup', () {
    test('Hin- und Rückweg erhält alle Felder', () {
      final restored = ExportService.parseBackup(
        ExportService.buildBackup([
          _entry('Jürgen', DateTime(1990, 5, 1), enabled: false, hour: 7),
        ]),
      );
      final e = restored.single;
      expect(e.name, 'Jürgen');
      expect(e.birthday, DateTime(1990, 5, 1));
      expect(e.notificationTime, const TimeOfDay(hour: 7, minute: 0));
      expect(e.notificationsEnabled, isFalse);
    });

    test('alte Einträge ohne Ausschluss-Feld bleiben aktiv', () {
      final e = BirthdayEntry.fromJson({
        'name': 'Alt',
        'birthday': '1990-05-01T00:00:00.000',
        'notificationHour': 8,
        'notificationMinute': 30,
      });
      expect(e.notificationsEnabled, isTrue);
    });

    for (final bad in [
      'kein json',
      '[]',
      '{"version":1}',
      '{"version":1,"entries":[{"name":1}]}',
    ]) {
      test('lehnt ungültige Datei ab: $bad', () {
        expect(() => ExportService.parseBackup(bad), throwsFormatException);
      });
    }
  });

  group('Zahlen-PIN', () {
    Future<void> enter(WidgetTester tester, String pin) async {
      for (final digit in pin.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
    }

    test('wird nur als Hash gespeichert und korrekt geprüft', () async {
      final service = BiometricService();
      await service.enablePin('4711');

      expect(await service.getLockMode(), LockMode.pin);
      expect(await service.verifyPin('4711'), isTrue);
      expect(await service.verifyPin('4712'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().map(prefs.get), isNot(contains('4711')));

      await service.setLockMode(LockMode.off);
      expect(await service.verifyPin('4711'), isFalse);
    });

    testWidgets('Sperrbildschirm öffnet nur mit der richtigen PIN', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await BiometricService().enablePin('1234');

      var unlocked = false;
      await tester.pumpWidget(
        _localized(AuthLockScreen(onAuthenticated: () => unlocked = true)),
      );
      await tester.pumpAndSettle();

      await enter(tester, '9999');
      expect(unlocked, isFalse);
      expect(find.text('Falsche PIN'), findsOneWidget);

      await enter(tester, '1234');
      expect(unlocked, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Festlegen verlangt zweimal dieselbe PIN', (tester) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_localized(const PinSetupPage()));
      await tester.pumpAndSettle();
      expect(find.textContaining('4 bis 8'), findsOneWidget);

      await enter(tester, '1234');
      expect(find.text('PIN wiederholen'), findsOneWidget);
      await enter(tester, '4321');
      expect(find.text('Die PINs stimmen nicht überein'), findsOneWidget);
      expect(find.textContaining('4 bis 8'), findsOneWidget);
    });
  });

  group('Bildschirmsperre', () {
    testWidgets('eine Kachel führt zu den drei Möglichkeiten', (tester) async {
      await tester.pumpWidget(_localized(const BirthdayPrivacySettings()));
      await tester.pumpAndSettle();
      expect(find.text('Bildschirmsperre'), findsOneWidget);
      expect(find.text('Aus'), findsOneWidget);
      expect(find.text('Zahlen-PIN'), findsNothing);
      expect(find.text('Fingerabdruck'), findsNothing);

      await tester.tap(find.text('Bildschirmsperre'));
      await tester.pumpAndSettle();
      expect(find.text('Zahlen-PIN'), findsOneWidget);
      expect(find.text('Fingerabdruck'), findsOneWidget);
      expect(find.text('Gesichtserkennung'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(4));
      expect(find.text('Ziffern mischen'), findsOneWidget);
    });

    testWidgets('nach dem Festlegen zeigt die Kachel die gewählte Sperre', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_localized(const BirthdayPrivacySettings()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bildschirmsperre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zahlen-PIN'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 2; i++) {
        for (final digit in '1234'.split('')) {
          await tester.tap(find.text(digit));
          await tester.pump();
        }
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
      }
      expect(await BiometricService().getLockMode(), LockMode.pin);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Zahlen-PIN'), findsOneWidget);
      expect(find.text('Aus'), findsNothing);
    });

    test('die neue Sperrart überschreibt eine vorhandene PIN', () async {
      final service = BiometricService();
      await service.enablePin('1234');
      await service.setLockMode(LockMode.face);
      expect(await service.getLockMode(), LockMode.face);
      expect(await service.verifyPin('1234'), isFalse);
    });
  });

  group('Credits', () {
    testWidgets('Kachel unter Lizenz öffnet die Seite mit allen Projekten', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_localized(const aboutBirthdayMarkerPage()));
      await tester.pump();
      final license = tester.getTopLeft(find.text('Lizenz')).dy;
      final credits = tester.getTopLeft(find.text('Credits')).dy;
      final sponsor = tester.getTopLeft(find.text('Unterstützen')).dy;
      expect(credits, greaterThan(license));
      expect(credits, lessThan(sponsor));

      await tester.tap(find.text('Credits'));
      await tester.pumpAndSettle();
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('BSD 3-Clause License'), findsWidgets);

      await tester.scrollUntilVisible(find.text('Roboto'), 200);
      expect(find.text('Roboto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Geburtsjahr optional', () {
    final entry = BirthdayEntry(
      name: 'Ohne Jahr',
      birthday: BirthdayEntry.unknownYearDate(DateTime(1995, 3, 7)),
      notificationTime: const TimeOfDay(hour: 12, minute: 0),
      yearKnown: false,
    );

    test('Datum erscheint ohne Jahr, in jedem Format', () {
      expect(entry.formattedDate, '07/03');
      AppSettings.instance.dateStyle = DateStyle.yearMonthDayDash;
      expect(entry.formattedDate, '03-07');
      AppSettings.instance.dateStyle = DateStyle.dayMonthShortYearDot;
      expect(entry.formattedDate, '07.03');
    });

    test('bleibt im Backup erhalten', () {
      final restored =
          ExportService.parseBackup(ExportService.buildBackup([entry])).single;
      expect(restored.yearKnown, isFalse);
    });

    test('Kalender zeigt ihn in jedem Jahr', () {
      expect(
        BirthdayCalendar.birthdaysOn([entry], DateTime(1950, 3, 7)),
        hasLength(1),
      );
    });

    testWidgets('Liste zeigt kein Alter', (tester) async {
      await tester.pumpWidget(
        _localized(
          BirthdayListPage(
            entries: [entry],
            nextAge: (_) => 30,
            daysUntil: (_) => 10,
            onUpdate: () {},
            onOpenCalendar: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('In 10 Tagen'), findsOneWidget);
    });
  });

  group('Liste', () {
    Widget list(List<BirthdayEntry> entries) => _localized(
      BirthdayListPage(
        entries: entries,
        nextAge: (_) => 30,
        daysUntil: (b) => b.month * 10,
        onUpdate: () {},
        onOpenCalendar: () {},
      ),
    );

    testWidgets('leere Liste zeigt einen Hinweis', (tester) async {
      await tester.pumpWidget(list([]));
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Einträge'), findsOneWidget);
    });

    testWidgets('standardmäßig Ab heute sortiert', (tester) async {
      await tester.pumpWidget(
        list([
          _entry('Spät', DateTime(1990, 9, 1)),
          _entry('Früh', DateTime(1990, 2, 1)),
        ]),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Früh')).dy,
        lessThan(tester.getTopLeft(find.text('Spät')).dy),
      );
    });

    testWidgets('Löschen lässt sich rückgängig machen', (tester) async {
      final entries = [
        _entry('Anna', DateTime(1990, 2, 1)),
        _entry('Ben', DateTime(1990, 3, 1)),
      ];
      await tester.pumpWidget(list(entries));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Anna'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(entries.map((e) => e.name), ['Ben']);
      expect(find.text('Anna gelöscht'), findsOneWidget);

      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      expect(entries.map((e) => e.name), ['Anna', 'Ben']);
      expect(find.text('Anna'), findsOneWidget);

      // Die Meldung verschwindet von selbst wieder
      await tester.tap(find.text('Anna'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(find.text('Anna gelöscht'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Anna gelöscht'), findsNothing);
    });

    testWidgets('keine unsichtbare Tippfläche mehr in den Karten', (
      tester,
    ) async {
      await tester.pumpWidget(list([_entry('Anna', DateTime(1990, 2, 1))]));
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getTopRight(find.byType(ListTile)) + const Offset(-28, 28),
      );
      await tester.pumpAndSettle();
      expect(find.text('Geburtstag bearbeiten'), findsNothing);
    });
  });

  testWidgets('Hinzufügen zeigt eine Rückmeldung und kennt das unbekannte Jahr', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_homePage());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lena');
    await tester.tap(find.text('Geburtstag wählen'));
    await tester.pumpAndSettle();
    // Jahr antippen: einspaltige Liste, unter dem aktuellen Jahr "Jahr unbekannt"
    await tester.tap(find.byKey(const Key('birthdayPickerYear')));
    await tester.pumpAndSettle();
    final currentYear = find.text(DateTime.now().year.toString()).last;
    final unknown = find.text('Jahr unbekannt').last;
    expect(
      tester.getCenter(unknown).dy,
      greaterThan(tester.getCenter(currentYear).dy),
    );
    expect(
      tester.getCenter(unknown).dx,
      moreOrLessEquals(tester.getCenter(currentYear).dx, epsilon: 1),
    );
    await tester.tap(unknown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Lena gespeichert'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    final saved = BirthdayStore.instance.entries.single;
    expect(saved.yearKnown, isFalse);
    expect(saved.birthday.year, 2000);
    expect(saved.notificationTime, const TimeOfDay(hour: 12, minute: 0));
  });

  group('Geburtstagsauswahl', () {
    Future<List<BirthdayPick?>> open(
      WidgetTester tester, {
      DateTime? initialDate,
      bool yearKnown = true,
    }) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final results = <BirthdayPick?>[];
      await tester.pumpWidget(
        _localized(
          Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () async => results.add(
                          await showBirthdayPicker(
                            context,
                            initialDate: initialDate,
                            yearKnown: yearKnown,
                          ),
                        ),
                    child: const Text('öffnen'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('Jahr aus der Liste und Tag wählen', (tester) async {
      final results = await open(tester, initialDate: DateTime(1995, 6, 10));
      await tester.tap(find.byKey(const Key('birthdayPickerYear')));
      await tester.pumpAndSettle();
      // Die Liste öffnet beim gewählten Jahr
      expect(find.text('1995'), findsWidgets);
      await tester.tap(find.text('1993'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('21'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(results.single?.date, DateTime(1993, 6, 21));
      expect(results.single?.yearKnown, isTrue);
    });

    testWidgets('ohne Jahr ist der 29. Februar wählbar', (tester) async {
      final results = await open(
        tester,
        initialDate: DateTime(2000, 2, 10),
        yearKnown: false,
      );
      expect(find.text('Februar'), findsOneWidget);
      await tester.tap(find.text('29'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(results.single?.date, DateTime(2000, 2, 29));
      expect(results.single?.yearKnown, isFalse);
    });

    testWidgets('Tage in der Zukunft sind gesperrt', (tester) async {
      final today = DateUtils.dateOnly(DateTime.now());
      if (today.day == DateUtils.getDaysInMonth(today.year, today.month)) {
        return;
      }
      final results = await open(tester, initialDate: today);
      await tester.tap(find.text('${today.day + 1}'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(results.single?.date, today);
    });
  });

  group('Verbesserungen', () {
    testWidgets('Ausschalten der PIN verlangt die PIN', (tester) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await BiometricService().enablePin('1234');
      await tester.pumpWidget(_localized(const ScreenLockSettingsPage()));
      await tester.pumpAndSettle();

      Future<void> enter(String pin) async {
        for (final digit in pin.split('')) {
          await tester.tap(find.text(digit));
          await tester.pump();
        }
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Zahlen-PIN'));
      await tester.pumpAndSettle();
      expect(find.text('PIN eingeben'), findsOneWidget);
      await enter('9999');
      expect(find.text('Falsche PIN'), findsOneWidget);
      expect(await BiometricService().getLockMode(), LockMode.pin);
      await enter('1234');
      expect(await BiometricService().getLockMode(), LockMode.off);
    });

    testWidgets('gemischte Ziffern ändern ihre Reihenfolge', (tester) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final orders = <String>{};
      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(
          _localized(
            Scaffold(
              body: PinPad(
                key: UniqueKey(),
                title: 'PIN',
                scramble: true,
                onSubmit: (_) {},
              ),
            ),
          ),
        );
        final digits =
            find.byType(TextButton).evaluate().map((e) {
              final text = find.descendant(
                of: find.byWidget(e.widget),
                matching: find.byType(Text),
              );
              return text.evaluate().isEmpty
                  ? ''
                  : (text.evaluate().first.widget as Text).data;
            }).join();
        expect(digits.split('').toSet().length, 10);
        orders.add(digits);
      }
      expect(orders.length, greaterThan(1));
    });

    testWidgets('Monats-Überschriften in der Liste', (tester) async {
      await tester.pumpWidget(
        _localized(
          BirthdayListPage(
            entries: [
              _entry('Anna', DateTime(1990, 3, 1)),
              _entry('Ben', DateTime(1990, 3, 5)),
              _entry('Carl', DateTime(1990, 4, 1)),
            ],
            nextAge: (_) => 30,
            daysUntil: (b) => b.month * 31 + b.day,
            onUpdate: () {},
            onOpenCalendar: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('März'), findsOneWidget);
      expect(find.text('April'), findsOneWidget);
      final march = tester.getTopLeft(find.text('März'));
      expect(march.dy, lessThan(tester.getTopLeft(find.text('Anna')).dy));
      expect(
        tester.getTopLeft(find.text('April')).dy,
        greaterThan(tester.getTopLeft(find.text('Ben')).dy),
      );
    });

    testWidgets('Kalender blättert per Wischen', (tester) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _localized(const Scaffold(body: BirthdayCalendar(entries: []))),
      );
      await tester.pumpAndSettle();
      final now = DateTime.now();
      String title(DateTime m) => MaterialLocalizations.of(
        tester.element(find.byType(BirthdayCalendar)),
      ).formatMonthYear(m);
      expect(find.text(title(now)), findsOneWidget);

      await tester.fling(find.byType(Card), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(
        find.text(title(DateTime(now.year, now.month + 1))),
        findsOneWidget,
      );

      await tester.fling(find.byType(Card), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      await tester.fling(find.byType(Card), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(
        find.text(title(DateTime(now.year, now.month - 1))),
        findsOneWidget,
      );
    });

    testWidgets(
      'Über-Seite scrollt bis zum Icon, neue Kachel unter Unterstützen',
      (tester) async {
        tester.view.physicalSize = const Size(412, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_localized(const aboutBirthdayMarkerPage()));
        await tester.pump();
        await tester.scrollUntilVisible(find.text('Erstellt von ysahl1'), 200);
        // Das Icon behält seine Größe und wird nicht auf die Breite gezogen
        expect(tester.getSize(find.byType(Image)).width, 72);
        expect(
          tester.getTopLeft(find.text('Vom gleichen Entwickler')).dy,
          greaterThan(tester.getTopLeft(find.text('Unterstützen')).dy),
        );
      },
    );

    testWidgets('AMOLED färbt den dunklen Hintergrund schwarz', (tester) async {
      AppSettings.instance.themeMode = ThemeMode.dark;
      AppSettings.instance.amoled = true;
      await tester.pumpWidget(BirthdayMarkerApp());
      await tester.pumpAndSettle();
      final context = tester.element(find.byIcon(Icons.add));
      expect(Theme.of(context).scaffoldBackgroundColor, Colors.black);
    });
  });

  group('Datumsformat', () {
    final date = DateTime(2026, 1, 15);

    test('alle Formate', () {
      expect(AppSettings.instance.dateStyle, DateStyle.dayMonthYearSlash);
      expect(DateStyle.dayMonthYearSlash.format(date), '15/01/2026');
      expect(DateStyle.dayMonthYearDash.format(date), '15-01-2026');
      expect(DateStyle.yearMonthDayDash.format(date), '2026-01-15');
      expect(DateStyle.yearMonthDaySlash.format(date), '2026/01/15');
      expect(DateStyle.dayMonthShortYearSlash.format(date), '15/01/26');
      expect(DateStyle.monthDayShortYearSlash.format(date), '01/15/26');
      expect(DateStyle.dayMonthYearDot.format(date), '15.01.2026');
      expect(DateStyle.monthDayYearSlash.format(date), '01/15/2026');
      expect(DateStyle.dayMonthShortYearDot.format(date), '15.01.26');
      expect(
        DateStyle.dayMonthShortYearDot.format(DateTime(2005, 3, 4)),
        '04.03.05',
      );
    });

    test('der Export nutzt das gewählte Format', () {
      AppSettings.instance.dateStyle = DateStyle.monthDayYearSlash;
      final text = ExportService.buildText([
        _entry('Anna', date),
      ], AppStrings.forLocale(const Locale('de')));
      expect(text, contains('Anna: 01/15/2026'));
    });
  });

  group('Export', () {
    test('TXT ist alphabetisch und enthält Umlaute', () {
      final text = ExportService.buildText([
        _entry('Zoe', DateTime(1990, 5, 1)),
        _entry('Änne', DateTime(1991, 12, 24)),
        _entry('adam', DateTime(1992, 1, 2)),
      ], AppStrings.forLocale(const Locale('de')));
      expect(text, contains('adam: 02/01/1992'));
      expect(text.indexOf('adam'), lessThan(text.indexOf('Zoe')));
      expect(text, contains('Änne: 24/12/1991'));
    });

    test('PDF wird mit Sonderzeichen erzeugt', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final bytes = await ExportService.buildPdf([
        _entry('Çağla Müller', DateTime(1990, 5, 1)),
      ], AppStrings.forLocale(const Locale('de')));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  group('Kalender', () {
    test('zeigt 42 verschiedene Tage ab Montag, auch bei Zeitumstellung', () {
      for (final month in [DateTime(2026, 3), DateTime(2026, 10)]) {
        final days = BirthdayCalendar.gridDays(month);
        expect(days.toSet().length, 42);
        expect(days.first.weekday, DateTime.monday);
        expect(days.every((d) => d.hour == 0), isTrue);
      }
    });

    test('ordnet Geburtstage dem richtigen Tag zu', () {
      final entries = [_entry('Anna', DateTime(1990, 5, 1))];
      expect(
        BirthdayCalendar.birthdaysOn(entries, DateTime(2026, 5, 1)),
        hasLength(1),
      );
      expect(
        BirthdayCalendar.birthdaysOn(entries, DateTime(2026, 5, 2)),
        isEmpty,
      );
      // Vor der Geburt gibt es noch keinen Geburtstag
      expect(
        BirthdayCalendar.birthdaysOn(entries, DateTime(1989, 5, 1)),
        isEmpty,
      );
    });

    test('29. Februar erscheint außerhalb von Schaltjahren am 28.', () {
      final entries = [_entry('Schalttag', DateTime(2000, 2, 29))];
      expect(
        BirthdayCalendar.birthdaysOn(entries, DateTime(2027, 2, 28)),
        hasLength(1),
      );
      expect(
        BirthdayCalendar.birthdaysOn(entries, DateTime(2028, 2, 28)),
        isEmpty,
      );
      expect(
        BirthdayCalendar.birthdaysOn(entries, DateTime(2028, 2, 29)),
        hasLength(1),
      );
    });

    testWidgets('Antippen zeigt Person und Alter, alle Wochen sind sichtbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final now = DateTime.now();
      await tester.pumpWidget(
        _localized(
          Scaffold(
            body: BirthdayCalendar(
              entries: [_entry('Anna', DateTime(now.year - 30, now.month, 15))],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Im Raster steht nur ein Punkt, der Name erst nach dem Antippen
      expect(find.text('Anna'), findsNothing);
      await tester.tap(find.text('15'));
      await tester.pump();
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Wird 30 Jahre alt'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Eine kürzere Zeile im nächsten Monat setzt die Auswahl zurück
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      expect(find.text('Wird 30 Jahre alt'), findsNothing);
    });
  });

  group('Oberfläche', () {
    testWidgets('Kalender läuft mit großer Systemschrift nicht über', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final now = DateTime.now();
      await tester.pumpWidget(
        _localized(
          Scaffold(
            body: BirthdayCalendar(
              entries: [
                _entry(
                  'Annabell-Sophie',
                  DateTime(now.year - 30, now.month, 15),
                ),
                _entry('Ben', DateTime(now.year - 20, now.month, 15)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Exit-Dialog läuft auch schmal nicht über', (tester) async {
      tester.view.physicalSize = const Size(280, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_homePage());
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('BirthdayKeep beenden'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sprache schaltet die Texte um', (tester) async {
      await tester.pumpWidget(_homePage(locale: const Locale('en')));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Exit BirthdayKeep'), findsOneWidget);
    });

    testWidgets('Hauptseite zeigt nur die drei Knöpfe, Liste den Rest', (
      tester,
    ) async {
      BirthdayStore.instance.entries.add(_entry('Anna', DateTime(1990, 5, 1)));
      await tester.pumpWidget(_homePage());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('Geburtstagsliste'), findsNothing);
      expect(find.text('Anna'), findsNothing);
      expect(find.byIcon(Icons.filter_list), findsNothing);
      expect(find.byIcon(Icons.calendar_month), findsNothing);

      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      expect(find.text('Geburtstagsliste'), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
      final filter = tester.getCenter(find.byIcon(Icons.filter_list));
      final calendar = tester.getCenter(find.byIcon(Icons.calendar_month));
      expect(filter.dx, lessThan(calendar.dx));
      expect(filter.dy, calendar.dy);
      expect(find.byIcon(Icons.list), findsNothing);

      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      expect(find.text('Kalender'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Card),
          matching: find.byIcon(Icons.chevron_left),
        ),
        findsOneWidget,
      );
      // Im Kalender gibt es unten keine Knöpfe
      expect(find.byType(BottomAppBar), findsNothing);
    });

    testWidgets(
      'Der Knopf fliegt zur Suche und beim Zurückgehen wieder zurück',
      (tester) async {
        await tester.pumpWidget(_homePage());
        await tester.pumpAndSettle();
        final addPosition = tester.getCenter(find.byIcon(Icons.add)).dx;

        await tester.tap(find.byIcon(Icons.list));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        // Mitten im Flug liegt der Knopf zwischen Mitte und rechtem Rand
        final inFlight = tester.getCenter(find.byIcon(Icons.search)).dx;
        await tester.pumpAndSettle();
        final endPosition = tester.getCenter(find.byIcon(Icons.search)).dx;
        expect(inFlight, greaterThan(addPosition + 5));
        expect(inFlight, lessThan(endPosition - 5));
        expect(find.byIcon(Icons.add), findsNothing);
        expect(find.byIcon(Icons.settings), findsNothing);

        await tester.flingFrom(
          const Offset(30, 300),
          const Offset(300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);

        // Die Zurück-Taste führt zur Hauptseite, ohne die App zu beenden
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('BirthdayKeep beenden'), findsNothing);
      },
    );

    testWidgets('Vita-Effekt auch auf Einstellungsseiten', (tester) async {
      await tester.pumpWidget(_localized(const NotificationSettingsPage()));
      await tester.pumpAndSettle();

      double gap() =>
          tester.getTopLeft(find.text('Standard-Uhrzeit')).dy -
          tester.getTopLeft(find.text('Vorlauf')).dy;
      final restingGap = gap();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Vorlauf')),
      );
      await gesture.moveBy(const Offset(0, 40));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      expect(gap(), greaterThan(restingGap + 5));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(gap(), moreOrLessEquals(restingGap));
    });

    testWidgets('gewählte Startseite öffnet sich direkt', (tester) async {
      AppSettings.instance.startPage = StartPage.calendar;
      await tester.pumpWidget(_homePage());
      await tester.pumpAndSettle();
      expect(find.text('Kalender'), findsOneWidget);

      // Zurück führt zur Hauptseite mit dem Plus-Knopf
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Benachrichtigungsseite: nur Uhrzeit, kein Test-Knopf', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_localized(const NotificationSettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('Vorlauf'), findsOneWidget);
      expect(find.textContaining('Test'), findsNothing);

      await tester.tap(find.text('Datumsformat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('01/15/2026'));
      await tester.pumpAndSettle();
      expect(AppSettings.instance.dateStyle, DateStyle.monthDayYearSlash);
      expect(find.text('01/15/2026'), findsOneWidget);
    });

    testWidgets('Abstände wachsen beim Ziehen über den oberen Rand', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localized(
          BirthdayListPage(
            entries: [
              for (var i = 0; i < 5; i++)
                _entry('P$i', DateTime(1990, 5, i + 1)),
            ],
            nextAge: (_) => 30,
            daysUntil: (_) => 10,
            onUpdate: () {},
            onOpenCalendar: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      double gap() =>
          tester.getTopLeft(find.text('P1')).dy -
          tester.getTopLeft(find.text('P0')).dy;
      final restingGap = gap();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('P1')),
      );
      await gesture.moveBy(const Offset(0, 40));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      expect(gap(), greaterThan(restingGap + 5));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(gap(), moreOrLessEquals(restingGap));
    });
  });
}
