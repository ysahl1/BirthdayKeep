import 'dart:typed_data';
import 'package:BirthdayMarker/stretchListView.dart';
import 'package:BirthdayMarker/feedback.dart';
import 'package:flutter/material.dart';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/screenLockSettings.dart';
import 'package:BirthdayMarker/services/biometricService.dart';
import 'package:BirthdayMarker/services/birthdayStore.dart';
import 'package:BirthdayMarker/services/exportService.dart';

class BirthdayPrivacySettings extends StatefulWidget {
  const BirthdayPrivacySettings({super.key});

  @override
  State<BirthdayPrivacySettings> createState() => privacySettingsState();
}

class privacySettingsState extends State<BirthdayPrivacySettings> {
  final BiometricService _biometricService = BiometricService();
  final BirthdayStore _store = BirthdayStore.instance;
  LockMode _lockMode = LockMode.off;

  @override
  void initState() {
    super.initState();
    _loadLockMode();
  }

  Future<void> _loadLockMode() async {
    final lockMode = await _biometricService.getLockMode();
    if (!mounted) return;
    setState(() => _lockMode = lockMode);
  }

  String _lockModeLabel(AppStrings s) {
    return switch (_lockMode) {
      LockMode.off => s.screenLockOff,
      LockMode.device || LockMode.pin => s.pinLock,
      LockMode.biometric => s.fingerprint,
      LockMode.face => s.faceRecognition,
    };
  }

  void _showMessage(
    String message, {
    FeedbackType type = FeedbackType.success,
  }) {
    if (!mounted) return;
    showFeedback(context, message, type: type);
  }

  // -------------------
  // Export & Backup
  // -------------------
  void _showExportDialog() {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(s.exportFormat),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(s.txtFile),
                  onTap: () {
                    Navigator.pop(context);
                    _saveFile(
                      'BirthdayKeep.txt',
                      'text/plain',
                      () async => ExportService.encodeText(
                        ExportService.buildText(_store.entries, s),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(s.pdfFile),
                  onTap: () {
                    Navigator.pop(context);
                    _saveFile(
                      'BirthdayKeep.pdf',
                      'application/pdf',
                      () => ExportService.buildPdf(_store.entries, s),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveFile(
    String fileName,
    String mimeType,
    Future<Uint8List> Function() buildBytes,
  ) async {
    final s = AppStrings.of(context);
    try {
      final saved = await ExportService.saveFile(
        fileName,
        mimeType,
        await buildBytes(),
      );
      if (saved) _showMessage(s.saved);
    } catch (e) {
      debugPrint('Saving $fileName failed: $e');
      _showMessage(s.saveFailed, type: FeedbackType.error);
    }
  }

  Future<void> _restoreBackup() async {
    final s = AppStrings.of(context);
    try {
      final content = await ExportService.pickTextFile();
      if (content == null) return;
      final entries = ExportService.parseBackup(content);
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(s.backupRestore),
              content: Text(s.backupRestoreConfirm(entries.length)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(s.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(s.restore),
                ),
              ],
            ),
      );
      if (confirmed != true) return;

      await _store.replaceAll(entries);
      _showMessage(s.restored(entries.length));
    } on FormatException {
      _showMessage(s.invalidBackup, type: FeedbackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.privacy)),
      body: StretchListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Screen Lock Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(s.screenLock),
              subtitle: Text(_lockModeLabel(s)),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScreenLockSettingsPage(),
                  ),
                );
                _loadLockMode();
              },
            ),
          ),
          // Export Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(s.exportList),
              subtitle: Text(s.exportListHint),
              onTap: _showExportDialog,
            ),
          ),
          // Backup Cards
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(s.backupCreate),
              subtitle: Text(s.backupCreateHint),
              onTap:
                  () => _saveFile(
                    'BirthdayKeep-Backup.json',
                    'application/json',
                    () async => ExportService.encodeText(
                      ExportService.buildBackup(_store.entries),
                    ),
                  ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: Text(s.backupRestore),
              subtitle: Text(s.backupRestoreHint),
              onTap: _restoreBackup,
            ),
          ),
        ],
      ),
    );
  }
}
