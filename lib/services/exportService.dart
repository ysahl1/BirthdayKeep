import 'dart:convert';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:file_picker/file_picker.dart';
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
