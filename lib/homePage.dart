/* =========================
   Home Page
========================= */
import 'package:BirthdayMarker/birthdayPicker.dart';
import 'package:BirthdayMarker/calendarWidget.dart';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/services/birthdayStore.dart';
import 'package:BirthdayMarker/services/homeIntegration.dart';
import 'package:BirthdayMarker/services/notificationService.dart';
import 'package:BirthdayMarker/settings.dart';
import 'package:BirthdayMarker/list.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:BirthdayMarker/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BirthdayHomePage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<Locale> localeNotifier;
  final ValueNotifier<Color> accentColorNotifier;
  final ValueNotifier<bool> amoledNotifier;

  const BirthdayHomePage({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
    required this.accentColorNotifier,
    required this.amoledNotifier,
  });

  @override
  State<BirthdayHomePage> createState() => _BirthdayHomePageState();
}

class _BirthdayHomePageState extends State<BirthdayHomePage> {
  final BirthdayStore _store = BirthdayStore.instance;

  @override
  void initState() {
    super.initState();
    HomeIntegration.instance.listen(_handleAction);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Von Widget, Kachel oder App-Shortcut gestartet: dorthin statt zur Startseite
      final action = await HomeIntegration.instance.takePendingAction();
      if (!mounted) return;
      if (action != null) {
        _handleAction(action);
      } else {
        _openStartPage();
      }
      if (AppSettings.instance.notificationsEnabled) {
        NotificationService.instance.requestPermission();
      }
    });
  }

  // -------------------
  // Hilfsfunktionen
  // -------------------

  void _handleAction(String action) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    switch (action) {
      case 'list':
        _openPage(_buildListPage);
      case 'add':
        _addEntryDialog();
      case 'search':
        _openPage(
          (context) => _buildListPage(context, openSearchOnStart: true),
        );
    }
  }

  void _openStartPage() {
    final builder = switch (AppSettings.instance.startPage) {
      StartPage.home => null,
      StartPage.list => _buildListPage,
      StartPage.calendar => _buildCalendarPage,
      StartPage.settings => _buildSettingsPage,
    };
    if (builder == null) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, __) => builder(context),
      ),
    );
  }

  void _openPage(WidgetBuilder builder) {
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }

  Widget _buildListPage(
    BuildContext context, {
    bool openSearchOnStart = false,
  }) => BirthdayListPage(
    openSearchOnStart: openSearchOnStart,
    entries: _store.entries,
    nextAge: nextAge,
    daysUntil: daysUntil,
    onUpdate: _store.save,
    onOpenCalendar: () => _openPage(_buildCalendarPage),
  );

  Widget _buildCalendarPage(BuildContext context) =>
      BirthdayCalendarPage(entries: _store.entries);

  Widget _buildSettingsPage(BuildContext context) => SettingsPage(
    themeNotifier: widget.themeNotifier,
    localeNotifier: widget.localeNotifier,
    accentColorNotifier: widget.accentColorNotifier,
    amoledNotifier: widget.amoledNotifier,
  );

  int nextAge(DateTime birthday) {
    final today = DateUtils.dateOnly(DateTime.now());
    int age = today.year - birthday.year;
    final bThisYear = DateTime(today.year, birthday.month, birthday.day);
    return today.isAfter(bThisYear) ? age + 1 : age;
  }

  int daysUntil(DateTime birthday) {
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime next = DateTime(today.year, birthday.month, birthday.day);
    if (next.isBefore(today))
      next = DateTime(today.year + 1, birthday.month, birthday.day);
    // Über UTC gerechnet, damit Zeitumstellungen keinen Tag verschlucken
    return DateTime.utc(
      next.year,
      next.month,
      next.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        final s = AppStrings.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(s.exitTitle)),
            ],
          ),
          content: Text(s.exitMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.no),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(s.yes),
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }

    return false;
  }

  void _addEntryDialog() {
    final nameCtrl = TextEditingController();
    DateTime? birthday;
    TimeOfDay time = AppSettings.instance.defaultNotificationTime;
    bool yearKnown = true;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (dialogContext, setD) {
              final s = AppStrings.of(dialogContext);
              return AlertDialog(
                title: Text(s.addBirthday),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: s.name),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final pick = await showBirthdayPicker(
                          dialogContext,
                          initialDate: birthday,
                          yearKnown: yearKnown,
                        );
                        if (pick != null) {
                          setD(() {
                            birthday = pick.date;
                            yearKnown = pick.yearKnown;
                          });
                        }
                      },
                      child: Text(
                        birthday == null
                            ? s.chooseBirthday
                            : AppSettings.instance.formatDate(
                              birthday!,
                              withYear: yearKnown,
                            ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: dialogContext,
                          initialTime: time,
                        );
                        if (t != null) setD(() => time = t);
                      },
                      child: Text(s.reminderAt(time.format(dialogContext))),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(s.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isEmpty || birthday == null) return;
                      _store.entries.add(
                        BirthdayEntry(
                          name: nameCtrl.text,
                          birthday:
                              yearKnown
                                  ? birthday!
                                  : BirthdayEntry.unknownYearDate(birthday!),
                          notificationTime: time,
                          yearKnown: yearKnown,
                        ),
                      );
                      _store.save();
                      Navigator.pop(dialogContext);
                      showFeedback(context, s.entrySaved(nameCtrl.text));
                    },
                    child: Text(s.save),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: _addEntryDialog,
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () => _openPage(_buildListPage),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _openPage(_buildSettingsPage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
