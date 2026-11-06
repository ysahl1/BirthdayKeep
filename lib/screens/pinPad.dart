import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/services/biometricService.dart';
import 'package:flutter/material.dart';

/* =========================
   Zahlenfeld für die App-PIN
========================= */
class PinPad extends StatefulWidget {
  static const int minLength = 4;
  static const int maxLength = 8;

  final String title;
  final String? error;
  final Color? color;
  final bool enabled;
  final bool scramble;
  final ValueChanged<String> onSubmit;

  const PinPad({
    super.key,
    required this.title,
    required this.onSubmit,
    this.error,
    this.color,
    this.enabled = true,
    this.scramble = false,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  static const List<String> _orderedKeys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
  ];

  String _digits = '';
  late List<String> _keys = _arrangeKeys();

  // Gemischt kann niemand aus Fingerspuren oder Zusehen die PIN ablesen
  List<String> _arrangeKeys() =>
      widget.scramble ? (List.of(_orderedKeys)..shuffle()) : _orderedKeys;

  void _addDigit(String digit) {
    if (_digits.length >= PinPad.maxLength) return;
    setState(() => _digits += digit);
  }

  void _removeDigit() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _submit() {
    final pin = _digits;
    setState(() {
      _digits = '';
      _keys = _arrangeKeys();
    });
    widget.onSubmit(pin);
  }

  Widget _key({required Widget child, required VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 72,
        height: 72,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: widget.color,
            shape: const CircleBorder(),
          ),
          onPressed: widget.enabled ? onPressed : null,
          child: child,
        ),
      ),
    );
  }

  Widget _digitKey(String digit) => _key(
    onPressed: () => _addDigit(digit),
    child: Text(digit, style: const TextStyle(fontSize: 28)),
  );

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.onSurface;
    final s = AppStrings.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: color),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _digits.length; i++)
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 24,
          child: Text(
            widget.error ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          ),
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < 3; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children:
                _keys.sublist(row * 3, row * 3 + 3).map(_digitKey).toList(),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _key(
              onPressed: _digits.isEmpty ? null : _removeDigit,
              child: Icon(
                Icons.backspace_outlined,
                semanticLabel: s.deleteDigit,
              ),
            ),
            _digitKey(_keys[9]),
            _key(
              onPressed: _digits.length >= PinPad.minLength ? _submit : null,
              child: Icon(Icons.check, semanticLabel: s.confirm),
            ),
          ],
        ),
      ],
    );
  }
}

/* =========================
   PIN festlegen
========================= */

// Gibt die zweimal gleich eingegebene PIN zurück, bei Abbruch null
class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String? _firstEntry;
  String? _error;

  void _onSubmit(String pin) {
    if (_firstEntry == null) {
      setState(() {
        _firstEntry = pin;
        _error = null;
      });
    } else if (pin == _firstEntry) {
      Navigator.pop(context, pin);
    } else {
      setState(() {
        _firstEntry = null;
        _error = AppStrings.of(context).pinMismatch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.pinLock)),
      body: Center(
        child: SingleChildScrollView(
          child: PinPad(
            scramble: AppSettings.instance.pinScramble,
            title: _firstEntry == null ? s.choosePin : s.repeatPin,
            error: _error,
            onSubmit: _onSubmit,
          ),
        ),
      ),
    );
  }
}

/* =========================
   PIN bestätigen
========================= */

// Gibt true zurück, wenn die gespeicherte PIN richtig eingegeben wurde
class PinVerifyPage extends StatefulWidget {
  const PinVerifyPage({super.key});

  @override
  State<PinVerifyPage> createState() => _PinVerifyPageState();
}

class _PinVerifyPageState extends State<PinVerifyPage> {
  String? _error;

  Future<void> _onSubmit(String pin) async {
    final s = AppStrings.of(context);
    final correct = await BiometricService().verifyPin(pin);
    if (!mounted) return;
    if (correct) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = s.wrongPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.pinLock)),
      body: Center(
        child: SingleChildScrollView(
          child: PinPad(
            scramble: AppSettings.instance.pinScramble,
            title: s.enterPin,
            error: _error,
            onSubmit: _onSubmit,
          ),
        ),
      ),
    );
  }
}
