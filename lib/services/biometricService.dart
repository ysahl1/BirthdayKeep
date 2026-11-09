import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/services/homeIntegration.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// device: System-Dialog mit Geräte-PIN/Muster (nur noch aus älteren Versionen)
// biometric: Fingerabdruck
// pin: eigene Zahlen-PIN der App
// face: Gesichtserkennung
enum LockMode { off, device, biometric, pin, face }

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const MethodChannel _biometricsChannel = MethodChannel(
    'birthdaykeep/biometrics',
  );
  static const String _legacyEnabledKey = 'biometric_enabled';
  static const String _lockModeKey = 'lock_mode';
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const int _pinHashRounds = 20000;

  // Gibt verfügbare Biometrie-Typen zurück
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Welche biometrischen Sperren dieses Gerät anbietet
  Future<({bool fingerprint, bool face})> getBiometricOptions() async {
    final available = await getAvailableBiometrics();
    if (available.isEmpty) return (fingerprint: false, face: false);
    if (!Platform.isAndroid) {
      return (
        fingerprint: available.contains(BiometricType.fingerprint),
        face: available.contains(BiometricType.face),
      );
    }
    try {
      final options = await _biometricsChannel.invokeMapMethod<String, bool>(
        'getOptions',
      );
      return (
        fingerprint: options?['fingerprint'] ?? false,
        face: options?['face'] ?? false,
      );
    } on PlatformException catch (e) {
      debugPrint('Reading biometric options failed: $e');
      return (fingerprint: false, face: false);
    }
  }

  // Authentifizierung durchführen
  Future<bool> authenticate({LockMode? mode}) async {
    final lockMode = mode ?? await getLockMode();
    // Wurden alle Fingerabdrücke entfernt, darf die App nicht unzugänglich werden
    final biometricOnly =
        (lockMode == LockMode.biometric || lockMode == LockMode.face) &&
        (await getAvailableBiometrics()).isNotEmpty;
    try {
      return await _localAuth.authenticate(
        localizedReason:
            AppStrings.forLocale(AppSettings.instance.locale).authReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  // Speichert die gewählte App-Sperre
  Future<void> setLockMode(LockMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lockModeKey, mode.index);
    if (mode != LockMode.pin) {
      await prefs.remove(_pinHashKey);
      await prefs.remove(_pinSaltKey);
    }
    await applyScreenProtection();
    // Widgets zeigen bei aktiver Sperre keine Namen
    await HomeIntegration.instance.refreshWidgets();
  }

  // Bei aktiver Sperre bleibt der Inhalt auf Screenshots und in der
  // App-Übersicht verborgen
  Future<void> applyScreenProtection() async {
    if (!Platform.isAndroid) return;
    final locked = await getLockMode() != LockMode.off;
    try {
      await _biometricsChannel.invokeMethod<void>(
        'setScreenProtection',
        locked,
      );
    } on PlatformException catch (e) {
      debugPrint('Setting screen protection failed: $e');
    }
  }

  // -------------------
  // Zahlen-PIN
  // -------------------

  // Die PIN selbst wird nie gespeichert, nur ihr Hash
  static String _hashPin(String pin, String salt) {
    var digest = utf8.encode('$salt:$pin');
    for (var i = 0; i < _pinHashRounds; i++) {
      digest = Uint8List.fromList(sha256.convert(digest).bytes);
    }
    return base64Encode(digest);
  }

  Future<void> enablePin(String pin) async {
    final random = Random.secure();
    final salt = base64Encode(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinSaltKey, salt);
    await prefs.setString(_pinHashKey, _hashPin(pin, salt));
    await setLockMode(LockMode.pin);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_pinSaltKey);
    final hash = prefs.getString(_pinHashKey);
    if (salt == null || hash == null) return false;
    return _hashPin(pin, salt) == hash;
  }

  // Liest die gewählte App-Sperre
  Future<LockMode> getLockMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_lockModeKey);
    if (stored != null) return LockMode.values[stored];
    // Ältere Versionen kannten nur "Sperre an/aus" und erlaubten dabei auch die PIN
    return (prefs.getBool(_legacyEnabledKey) ?? false)
        ? LockMode.device
        : LockMode.off;
  }
}
