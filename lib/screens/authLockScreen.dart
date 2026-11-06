import 'package:flutter/material.dart';
import '../l10n/appStrings.dart';
import '../services/appSettings.dart';
import '../services/biometricService.dart';
import 'pinPad.dart';

class AuthLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthLockScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthLockScreen> createState() => _AuthLockScreenState();
}

class _AuthLockScreenState extends State<AuthLockScreen> {
  static const int _maxAttempts = 5;
  static const int _lockoutSeconds = 30;

  final BiometricService _biometricService = BiometricService();
  LockMode? _lockMode;
  bool _isAuthenticating = false;
  String? _pinError;
  int _failedAttempts = 0;
  bool _lockedOut = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final mode = await _biometricService.getLockMode();
    if (!mounted) return;
    setState(() => _lockMode = mode);
    if (mode != LockMode.pin) _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    final authenticated = await _biometricService.authenticate();

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (authenticated) {
      widget.onAuthenticated();
    }
  }

  Future<void> _checkPin(String pin) async {
    final s = AppStrings.of(context);
    final correct = await _biometricService.verifyPin(pin);
    if (!mounted) return;
    if (correct) {
      widget.onAuthenticated();
      return;
    }

    _failedAttempts++;
    if (_failedAttempts < _maxAttempts) {
      setState(() => _pinError = s.wrongPin);
      return;
    }
    setState(() {
      _lockedOut = true;
      _pinError = s.tryAgainIn(_lockoutSeconds);
    });
    await Future.delayed(const Duration(seconds: _lockoutSeconds));
    if (!mounted) return;
    setState(() {
      _lockedOut = false;
      _failedAttempts = 0;
      _pinError = null;
    });
  }

  // Wer die PIN vergisst, kommt über die Sperre des Geräts wieder hinein,
  // sonst wären alle Einträge verloren. Die PIN wird dabei entfernt.
  Future<void> _forgotPin() async {
    final s = AppStrings.of(context);
    setState(() => _isAuthenticating = true);
    final verified = await _biometricService.authenticate(
      mode: LockMode.device,
    );
    if (!mounted) return;
    setState(() => _isAuthenticating = false);
    if (!verified) {
      setState(() => _pinError = s.forgotPinFailed);
      return;
    }
    await _biometricService.setLockMode(LockMode.off);
    widget.onAuthenticated();
  }

  Widget _buildPinContent(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PinPad(
          title: s.enterPin,
          error: _pinError,
          color: Colors.white,
          scramble: AppSettings.instance.pinScramble,
          enabled: !_lockedOut && !_isAuthenticating,
          onSubmit: _checkPin,
        ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: _isAuthenticating ? null : _forgotPin,
          child: Text(s.forgotPin),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        width: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.of(context).appLocked,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                if (_lockMode == null)
                  const CircularProgressIndicator(color: Colors.white)
                else if (_lockMode == LockMode.pin)
                  _buildPinContent(context)
                else if (_isAuthenticating)
                  CircularProgressIndicator(color: Colors.white)
                else
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: Icon(
                      _lockMode == LockMode.face
                          ? Icons.face
                          : Icons.fingerprint,
                    ),
                    label: Text(AppStrings.of(context).unlock),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
