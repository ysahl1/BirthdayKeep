import 'package:flutter/material.dart';

/* =========================
   Texte (Deutsch/Englisch)
========================= */
class AppStrings {
  final bool _de;
  const AppStrings._(this._de);

  static AppStrings forLocale(Locale locale) =>
      AppStrings._(locale.languageCode == 'de');

  static AppStrings of(BuildContext context) =>
      forLocale(Localizations.localeOf(context));

  String _t(String de, String en) => _de ? de : en;

  // Allgemein
  static const String appName = 'BirthdayKeep';
  String get yes => _t('Ja', 'Yes');
  String get no => _t('Nein', 'No');
  String get cancel => _t('Abbrechen', 'Cancel');
  String get save => _t('Speichern', 'Save');
  String get close => _t('Schließen', 'Close');
  String get name => 'Name';

  // Beenden
  String get exitTitle => _t('$appName beenden', 'Exit $appName');
  String get exitMessage => _t(
    'Möchtest du die App wirklich schließen?',
    'Are you sure you want to close the application?',
  );

  // Eintrag hinzufügen/bearbeiten
  String get addBirthday => _t('Geburtstag hinzufügen', 'Add Birthday');
  String get editBirthday => _t('Geburtstag bearbeiten', 'Edit Birthday');
  String get chooseBirthday => _t('Geburtstag wählen', 'Choose Birthday');
  String reminderAt(String time) =>
      _t('Erinnerung um $time', 'Reminder at $time');

  // Liste
  String get birthdayList => _t('Geburtstagsliste', 'Birthday List');
  String get sort => _t('Sortieren', 'Sort');
  String get sortBirthYear => _t('Geburtsjahr', 'Birth year');
  String get sortRecentlyAdded => _t('Zuletzt hinzugefügt', 'Recently added');
  String get sortFromToday => _t('Ab heute', 'From today');
  String get ascending => _t('Aufsteigend', 'Ascending');
  String get descending => _t('Absteigend', 'Descending');
  String todayTurns(int age) => _t('Heute ($age)', 'Today ($age)');
  String inDaysTurns(int days, int age) =>
      days == 1
          ? _t('Morgen ($age)', 'Tomorrow ($age)')
          : _t('In $days Tagen ($age)', 'In $days days ($age)');
  String get favorite => _t('Favorit', 'Favorite');
  String get today => _t('Heute', 'Today');
  String inDays(int days) =>
      days == 1
          ? _t('Morgen', 'Tomorrow')
          : _t('In $days Tagen', 'In $days days');
  String get yearUnknownShort => _t('Jahr unbekannt', 'Year unknown');
  String get ok => 'OK';
  List<String> get months =>
      _de
          ? const [
            'Januar',
            'Februar',
            'März',
            'April',
            'Mai',
            'Juni',
            'Juli',
            'August',
            'September',
            'Oktober',
            'November',
            'Dezember',
          ]
          : const [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
  String entrySaved(String name) => _t('$name gespeichert', '$name saved');
  String entryDeleted(String name) => _t('$name gelöscht', '$name deleted');
  String get undo => _t('Rückgängig', 'Undo');
  String get searchName => _t('Name suchen', 'Search name');
  String get noResults => _t('Keine Ergebnisse', 'No results');

  // Details
  String birthdayLabel(String date) =>
      _t('Geburtstag: $date', 'Birthday: $date');
  String reminderLabel(String time) =>
      _t('Erinnerung: $time', 'Reminder: $time');
  String get zodiacLabel => _t('Sternzeichen:  ', 'Zodiac sign:  ');
  String get todayIsBirthday =>
      _t('Heute ist der Geburtstag!', 'Today is the birthday!');
  String inDaysYearsOld(int days, int age) =>
      days == 1
          ? _t('Morgen (wird $age Jahre alt)', 'Tomorrow ($age years old)')
          : _t(
            'In $days Tagen (wird $age Jahre alt)',
            'In $days days ($age years old)',
          );

  String zodiac(String sign) {
    if (!_de) return sign;
    const german = {
      'Aries': 'Widder',
      'Taurus': 'Stier',
      'Gemini': 'Zwillinge',
      'Cancer': 'Krebs',
      'Leo': 'Löwe',
      'Virgo': 'Jungfrau',
      'Libra': 'Waage',
      'Scorpio': 'Skorpion',
      'Sagittarius': 'Schütze',
      'Capricorn': 'Steinbock',
      'Aquarius': 'Wassermann',
      'Pisces': 'Fische',
    };
    return german[sign] ?? sign;
  }

  // Kalender
  String get calendar => _t('Kalender', 'Calendar');
  List<String> get weekdays =>
      _de
          ? const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
          : const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  String turnsAge(int age) =>
      age == 0
          ? _t('Wird geboren', 'Is born')
          : _t('Wird $age Jahre alt', 'Turns $age');

  String get hasBirthday => _t('Hat Geburtstag', 'Has a birthday');

  // Einstellungen
  String get settings => _t('Einstellungen', 'Settings');
  String get privacy => _t('Datenschutz', 'Privacy & Security');
  String get notifications => _t('Benachrichtigungen', 'Notifications');
  String get design => 'Design';
  String get about => _t('Über $appName', 'About $appName');

  // Datenschutz
  String get pinLock => _t('Zahlen-PIN', 'Number PIN');
  String get pinLockOn =>
      _t('App ist mit einer PIN geschützt', 'App is protected with a PIN');
  String get pinLockOff =>
      _t('App mit einer eigenen PIN schützen', 'Protect app with your own PIN');
  String get fingerprint => _t('Fingerabdruck', 'Fingerprint');
  String get faceRecognition => _t('Gesichtserkennung', 'Face Recognition');
  String get screenLock => _t('Bildschirmsperre', 'Screen Lock');
  String get screenLockOff => _t('Aus', 'Off');
  String biometricLockOn(String type) =>
      _t('App ist mit $type geschützt', 'App is protected with $type');
  String biometricLockOff(String type) =>
      _t('App mit $type schützen', 'Protect app with $type');
  String get notAvailable =>
      _t('Auf diesem Gerät nicht verfügbar', 'Not available on this device');
  String get lockEnabled => _t('Sperre aktiviert', 'Security lock enabled');
  String get lockDisabled => _t('Sperre deaktiviert', 'Security lock disabled');
  String get exportList => _t('Liste exportieren', 'Export List');
  String get exportListHint =>
      _t('Als TXT oder PDF speichern', 'Save as TXT or PDF');
  String get exportFormat => _t('Format wählen', 'Choose format');
  String get txtFile => _t('Textdatei (.txt)', 'Text file (.txt)');
  String get pdfFile => _t('PDF-Datei (.pdf)', 'PDF file (.pdf)');
  String get backupCreate => _t('Backup erstellen', 'Create Backup');
  String get backupCreateHint => _t(
    'Alle Geburtstage als unverschlüsselte Datei',
    'All birthdays as an unencrypted file',
  );
  String get backupRestore => _t('Backup wiederherstellen', 'Restore Backup');
  String get backupRestoreHint => _t(
    'Geburtstage aus einer Backup-Datei laden',
    'Load birthdays from a backup file',
  );
  String backupRestoreConfirm(int count) => _t(
    'Das Backup enthält $count Einträge. Die aktuelle Liste wird dabei ersetzt.',
    'The backup contains $count entries. This replaces your current list.',
  );
  String get importText =>
      _t('Aus Textdatei importieren', 'Import from Text File');
  String get importTextHint => _t(
    'Eine Zeile pro Person, z. B. Anna: 01/12/2001',
    'One line per person, e.g. Anna: 01/12/2001',
  );
  String importConfirm(int found, int skipped) => _t(
    '$found Geburtstage gefunden, $skipped Zeilen übersprungen.',
    'Found $found birthdays, skipped $skipped lines.',
  );
  String get importAdd => _t('Hinzufügen', 'Add');
  String imported(int count) =>
      _t('$count Geburtstage hinzugefügt', 'Added $count birthdays');
  String get importNothing => _t(
    'Keine neuen Geburtstage in der Datei gefunden',
    'No new birthdays found in the file',
  );
  String get restore => _t('Wiederherstellen', 'Restore');
  String get saved => _t('Datei gespeichert', 'File saved');
  String get saveFailed =>
      _t('Datei konnte nicht gespeichert werden', 'Could not save the file');
  String restored(int count) =>
      _t('$count Einträge wiederhergestellt', 'Restored $count entries');
  String get invalidBackup =>
      _t('Keine gültige Backup-Datei', 'Not a valid backup file');
  String get exportHeading => _t('Geburtstage', 'Birthdays');
  String get birthdayColumn => _t('Geburtstag', 'Birthday');

  // PIN
  String get choosePin =>
      _t('PIN festlegen (4 bis 8 Ziffern)', 'Choose a PIN (4 to 8 digits)');
  String get repeatPin => _t('PIN wiederholen', 'Repeat PIN');
  String get pinMismatch =>
      _t('Die PINs stimmen nicht überein', 'The PINs do not match');
  String get enterPin => _t('PIN eingeben', 'Enter PIN');
  String get wrongPin => _t('Falsche PIN', 'Wrong PIN');
  String tryAgainIn(int seconds) => _t(
    'Zu viele Versuche. Noch $seconds s warten',
    'Too many attempts. Wait $seconds s',
  );
  String get forgotPin => _t('PIN vergessen?', 'Forgot PIN?');
  String get forgotPinFailed => _t(
    'Das Gerät konnte dich nicht bestätigen',
    'Your device could not verify you',
  );
  String get scramblePin => _t('Ziffern mischen', 'Scramble Digits');
  String get scramblePinHint => _t(
    'Das Zahlenfeld wird bei jeder Eingabe neu angeordnet',
    'The number pad is rearranged for every entry',
  );
  String get deleteDigit => _t('Ziffer löschen', 'Delete digit');
  String get confirm => _t('Bestätigen', 'Confirm');

  // Sperrbildschirm
  String get appLocked => _t('App ist gesperrt', 'App is locked');
  String get unlock => _t('Entsperren', 'Unlock');
  String get authReason => _t(
    'Bitte anmelden, um $appName zu öffnen',
    'Please authenticate to access $appName',
  );

  // Benachrichtigungen
  String get leadTime => _t('Vorlauf', 'Advance Notice');
  String leadTimeOption(int days) {
    if (days == 0) return _t('Am Tag selbst', 'On the day');
    if (days == 1) return _t('1 Tag vorher', '1 day before');
    return _t('$days Tage vorher', '$days days before');
  }

  String get automaticNotification =>
      _t('Automatische Benachrichtigung', 'Automatic Notification');
  String get automaticOn => _t(
    'Alle Geburtstage werden automatisch erinnert',
    'All birthdays are reminded automatically',
  );
  String get automaticOff =>
      _t('Es werden keine Erinnerungen geplant', 'No reminders are scheduled');
  String get defaultTime => _t('Standard-Uhrzeit', 'Default Time');
  String get excludePeople => _t('Personen ausschließen', 'Exclude People');
  String excludedCount(int count) =>
      _t('$count ausgeschlossen', '$count excluded');
  String get noEntries => _t('Noch keine Einträge', 'No entries yet');
  String get dateFormat => _t('Datumsformat', 'Date Format');
  String get permissionDenied =>
      _t('Benachrichtigungen sind blockiert', 'Notifications are blocked');
  String get permissionDeniedHint => _t(
    'Tippe hier, um sie zu erlauben. Falls nichts passiert, erlaube sie in den Systemeinstellungen.',
    'Tap to allow them. If nothing happens, allow them in your system settings.',
  );
  String get channelName => _t('Geburtstagserinnerungen', 'Birthday reminders');
  String get reminderTitle => _t('Geburtstagserinnerung', 'Birthday reminder');
  String reminderBody(String name, int leadDays) {
    if (leadDays == 0) {
      return _t('$name hat heute Geburtstag!', "It's $name's birthday today!");
    }
    if (leadDays == 1) {
      return _t(
        '$name hat morgen Geburtstag.',
        "It's $name's birthday tomorrow.",
      );
    }
    return _t(
      '$name hat in $leadDays Tagen Geburtstag.',
      "It's $name's birthday in $leadDays days.",
    );
  }

  // Design
  String get appearance => _t('Erscheinungsbild', 'Appearance');
  String get chooseAppearance =>
      _t('Erscheinungsbild wählen', 'Choose Appearance');
  String get light => _t('Hell', 'Light');
  String get dark => _t('Dunkel', 'Dark');
  String get system => 'System';
  String get themeColor => _t('Designfarbe', 'Theme Color');
  String get chooseThemeColor => _t('Designfarbe wählen', 'Choose Theme Color');
  String get custom => _t('Benutzerdefiniert', 'Custom');
  String colorName(String english) {
    if (!_de) return english;
    const german = {
      'Blue': 'Blau',
      'Violet': 'Violett',
      'Pink': 'Pink',
      'Green': 'Grün',
      'Teal': 'Petrol',
      'Red': 'Rot',
      'Orange': 'Orange',
      'Yellow': 'Gelb',
      'Beige': 'Beige',
      'Brown': 'Braun',
    };
    return german[english] ?? english;
  }

  String get amoled => _t('AMOLED-Schwarz', 'AMOLED Black');
  String get amoledHint => _t(
    'Reines Schwarz im dunklen Modus, schont den Akku bei OLED-Displays',
    'Pure black in dark mode, saves battery on OLED displays',
  );
  String get on => _t('An', 'On');
  String get off => _t('Aus', 'Off');
  String get language => _t('Sprache', 'Language');
  String get chooseLanguage => _t('Sprache wählen', 'Choose Language');
  String get startPage => _t('Startseite beim Öffnen', 'Start Page');
  String get chooseStartPage => _t('Startseite wählen', 'Choose Start Page');
  String get pageHome => _t('Hauptseite', 'Home');

  // Über die App
  String get changeLog => _t('Änderungsverlauf', 'Change Log');
  String get issueTracker => _t('Fehler melden', 'Issue Tracker');
  String get issueTrackerHint => _t(
    'Fehler melden oder Funktionen vorschlagen',
    'Report bugs or request features',
  );
  String get license => _t('Lizenz', 'License');
  String get credits => 'Credits';
  String get creditsHint =>
      _t('Verwendete Open-Source-Projekte', 'Open source projects used');
  String get creditsThanks => _t(
    'Danke an alle Open-Source-Projekte, die diese App möglich machen.',
    'Thanks to all the open source projects that make this app possible.',
  );
  String get sponsor => _t('Unterstützen', 'Sponsor');
  String get sponsorHint => _t(
    'Unterstütze diese App mit einer Spende',
    'Support this App with a donation',
  );
  String get moreFromDeveloper =>
      _t('Vom gleichen Entwickler', 'More from the developer');
  String get moreFromDeveloperHint =>
      _t('Weitere Projekte auf GitHub', 'More projects on GitHub');
  String get createdBy => _t('Erstellt von ysahl1', 'Created by ysahl1');
}
