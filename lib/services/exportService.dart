import 'dart:convert';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  static const int _backupVersion = 1;

  static List<BirthdayEntry> _sorted(List<BirthdayEntry> entries) {
    return List<BirthdayEntry>.from(entries)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  // -------------------
  // Dateiinhalte
  // -------------------
  static String buildText(List<BirthdayEntry> entries, AppStrings s) {
    final lines = _sorted(entries).map((e) => '${e.name}: ${e.formattedDate}');
    return '${AppStrings.appName} - ${s.exportHeading}\n\n${lines.join('\n')}\n';
  }

  static Future<Uint8List> buildPdf(
    List<BirthdayEntry> entries,
    AppStrings s,
  ) async {
    // Die eingebauten PDF-Schriften können keine Umlaute und Sonderzeichen
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (_) => [
              pw.Header(
                level: 0,
                child: pw.Text('${AppStrings.appName} - ${s.exportHeading}'),
              ),
              pw.TableHelper.fromTextArray(
                headers: [s.name, s.birthdayColumn],
                data:
                    _sorted(
                      entries,
                    ).map((e) => [e.name, e.formattedDate]).toList(),
              ),
            ],
      ),
    );
    return doc.save();
  }

  static String buildBackup(List<BirthdayEntry> entries) {
    return jsonEncode({
      'app': AppStrings.appName,
      'version': _backupVersion,
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  // Wirft eine FormatException, wenn die Datei kein gültiges Backup ist
  static List<BirthdayEntry> parseBackup(String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (data['version'] is! int || data['entries'] is! List) {
        throw const FormatException('Missing backup fields');
      }
      return (data['entries'] as List)
          .map((e) => BirthdayEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on TypeError {
      throw const FormatException('Unexpected backup structure');
    }
  }

  // -------------------
  // Import aus Textdatei
  // -------------------
  static final RegExp _importLine = RegExp(
    r'^(.*?\S)[\s:;,\-–]+(\d{1,4}[./-]\d{1,2}(?:[./-]\d{1,4})?)\.?\s*$',
  );

  // Erwartet pro Zeile Name und Datum. Doppelte Einträge werden übersprungen.
  static ({List<BirthdayEntry> entries, int skipped}) parseTextImport(
    String content,
    List<BirthdayEntry> existing,
    DateTime now,
  ) {
    final settings = AppSettings.instance;
    final seen = {
      for (final e in existing)
        _importKey(e.name, e.birthday.month, e.birthday.day),
    };
    final entries = <BirthdayEntry>[];
    var skipped = 0;

    for (final line in const LineSplitter().convert(content)) {
      if (line.trim().isEmpty) continue;
      final match = _importLine.firstMatch(line.trim());
      final date =
          match == null
              ? null
              : _parseImportDate(match.group(2)!, settings.dateStyle, now);
      if (match == null || date == null) {
        skipped++;
        continue;
      }
      final name = match.group(1)!.trim();
      if (!seen.add(_importKey(name, date.date.month, date.date.day))) {
        skipped++;
        continue;
      }
      entries.add(
        BirthdayEntry(
          name: name,
          birthday: date.date,
          notificationTime: settings.defaultNotificationTime,
          yearKnown: date.yearKnown,
        ),
      );
    }
    return (entries: entries, skipped: skipped);
  }

  static String _importKey(String name, int month, int day) =>
      '${name.toLowerCase()}|$month|$day';

  static ({DateTime date, bool yearKnown})? _parseImportDate(
    String token,
    DateStyle style,
    DateTime now,
  ) {
    final parts = token.split(RegExp(r'[./-]'));
    final numbers = parts.map(int.parse).toList();
    final monthFirst = style.pattern.startsWith('MM');

    DateTime? valid(int year, int month, int day) {
      if (month < 1 || month > 12 || day < 1) return null;
      if (day > DateUtils.getDaysInMonth(year, month)) return null;
      final date = DateTime(year, month, day);
      return date.isAfter(now) ? null : date;
    }

    if (parts.length == 2) {
      if (parts[0].length > 2 || parts[1].length > 2) return null;
      final date =
          monthFirst
              ? valid(2000, numbers[0], numbers[1]) ??
                  valid(2000, numbers[1], numbers[0])
              : valid(2000, numbers[1], numbers[0]) ??
                  valid(2000, numbers[0], numbers[1]);
      return date == null ? null : (date: date, yearKnown: false);
    }

    DateTime? date;
    if (parts[0].length == 4) {
      date = valid(numbers[0], numbers[1], numbers[2]);
    } else if (parts[2].length == 2 || parts[2].length == 4) {
      var year = numbers[2];
      if (parts[2].length == 2) {
        year += 2000;
        if (year > now.year) year -= 100;
      }
      date =
          monthFirst
              ? valid(year, numbers[0], numbers[1]) ??
                  valid(year, numbers[1], numbers[0])
              : valid(year, numbers[1], numbers[0]) ??
                  valid(year, numbers[0], numbers[1]);
    }
    return date == null ? null : (date: date, yearKnown: true);
  }

  // -------------------
  // Datei speichern/öffnen
  // -------------------

  // Gibt false zurück, wenn der Dialog abgebrochen wurde
  static Future<bool> saveFile(
    String fileName,
    String mimeType,
    Uint8List bytes,
  ) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
    );
    return uri != null;
  }

  static Uint8List encodeText(String text) =>
      Uint8List.fromList(utf8.encode(text));

  // Gibt null zurück, wenn der Dialog abgebrochen wurde
  static Future<String?> pickTextFile() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return null;
    final bytes = await files.single.readAsBytes();
    return utf8.decode(bytes, allowMalformed: true);
  }
}
