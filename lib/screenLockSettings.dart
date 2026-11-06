import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/screens/pinPad.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/services/biometricService.dart';
import 'package:BirthdayMarker/stretchListView.dart';
import 'package:BirthdayMarker/feedback.dart';
import 'package:flutter/material.dart';

/* =========================
   Bildschirmsperre
========================= */
class ScreenLockSettingsPage extends StatefulWidget {
  const ScreenLockSettingsPage({super.key});

  @override
  State<ScreenLockSettingsPage> createState() => _ScreenLockSettingsPageState();
}

class _ScreenLockSettingsPageState extends State<ScreenLockSettingsPage> {
  final BiometricService _biometricService = BiometricService();
  LockMode _lockMode = LockMode.off;
  bool _fingerprintAvailable = false;
  bool _faceAvailable = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Die Sperre zuerst laden: Die Biometrie-Abfrage kann auf manchen
  // Geräten dauern und soll den PIN-Schalter nicht aufhalten
  Future<void> _load() async {
    final lockMode = await _biometricService.getLockMode();
    if (!mounted) return;
    setState(() => _lockMode = lockMode);
    final options = await _biometricService.getBiometricOptions();
    if (!mounted) return;
    setState(() {
      _fingerprintAvailable = options.fingerprint;
      _faceAvailable = options.face;
    });
  }

  void _showResult(bool enabled) {
    if (!mounted) return;
    final s = AppStrings.of(context);
    showFeedback(
      context,
      enabled ? s.lockEnabled : s.lockDisabled,
      type: enabled ? FeedbackType.success : FeedbackType.info,
      icon: enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
    );
  }

  // Wer eine aktive Sperre ändert oder ausschaltet, muss sie zuerst bestätigen
  Future<bool> _confirmCurrentLock() async {
    switch (_lockMode) {
      case LockMode.off:
        return true;
      case LockMode.pin:
        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const PinVerifyPage()),
        );
        return verified ?? false;
      case LockMode.device || LockMode.biometric || LockMode.face:
        return _biometricService.authenticate(mode: _lockMode);
    }
  }

  Future<void> _disable() async {
    if (!await _confirmCurrentLock()) return;
    await _biometricService.setLockMode(LockMode.off);
    if (!mounted) return;
    setState(() => _lockMode = LockMode.off);
    _showResult(false);
  }

  Future<void> _setPinLock(bool enable) async {
    if (!enable) return _disable();
    if (!await _confirmCurrentLock()) return;
    if (!mounted) return;
    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PinSetupPage()),
    );
    if (pin == null) return;
    await _biometricService.enablePin(pin);
    if (!mounted) return;
    setState(() => _lockMode = LockMode.pin);
    _showResult(true);
  }

  Future<void> _setBiometricLock(LockMode mode, bool enable) async {
    if (!enable) return _disable();
    if (!await _confirmCurrentLock()) return;
    // Erst authentifizieren bevor aktiviert wird
    final authenticated = await _biometricService.authenticate(mode: mode);
    if (!authenticated) return;
    await _biometricService.setLockMode(mode);
    if (!mounted) return;
    setState(() => _lockMode = mode);
    _showResult(true);
  }

  Widget _biometricCard({
    required IconData icon,
    required String name,
    required LockMode mode,
    required bool available,
    required AppStrings s,
  }) {
    final active = _lockMode == mode;
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(name),
        subtitle: Text(
          !available
              ? s.notAvailable
              : active
              ? s.biometricLockOn(name)
              : s.biometricLockOff(name),
        ),
        value: active,
        onChanged: available ? (value) => _setBiometricLock(mode, value) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final pinActive = _lockMode == LockMode.pin || _lockMode == LockMode.device;

    return Scaffold(
      appBar: AppBar(title: Text(s.screenLock)),
      body: StretchListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.pin),
              title: Text(s.pinLock),
              subtitle: Text(pinActive ? s.pinLockOn : s.pinLockOff),
              value: pinActive,
              onChanged: _setPinLock,
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.shuffle_rounded),
              title: Text(s.scramblePin),
              subtitle: Text(s.scramblePinHint),
              value: AppSettings.instance.pinScramble,
              onChanged:
                  pinActive
                      ? (value) => setState(
                        () => AppSettings.instance.pinScramble = value,
                      )
                      : null,
            ),
          ),
          _biometricCard(
            icon: Icons.fingerprint,
            name: s.fingerprint,
            mode: LockMode.biometric,
            available: _fingerprintAvailable,
            s: s,
          ),
          _biometricCard(
            icon: Icons.face,
            name: s.faceRecognition,
            mode: LockMode.face,
            available: _faceAvailable,
            s: s,
          ),
        ],
      ),
    );
  }
}
