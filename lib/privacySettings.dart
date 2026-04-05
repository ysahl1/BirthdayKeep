import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:BirthdayMarker/services/biometricService.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthdayPrivacySettings extends StatefulWidget {
  const BirthdayPrivacySettings({super.key});

  @override
  State<BirthdayPrivacySettings> createState() => privacySettingsState();
}

class privacySettingsState extends State<BirthdayPrivacySettings> {
  final BiometricService _biometricService = BiometricService();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final enabled = await _biometricService.isBiometricEnabled();
    final available = await _biometricService.isBiometricAvailable();
    final biometrics = await _biometricService.getAvailableBiometrics();

    setState(() {
      _biometricEnabled = enabled;
      _biometricAvailable = available;
      _availableBiometrics = biometrics;
    });
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'PIN/Pattern';
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Erst authentifizieren bevor aktiviert wird
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        await _biometricService.setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Security lock enabled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      await _biometricService.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security lock disabled'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PIN Lock Card
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.pin),
              title: const Text('PIN Lock'),
              subtitle: Text(
                _biometricEnabled && !_availableBiometrics.contains(BiometricType.fingerprint) && !_availableBiometrics.contains(BiometricType.face)
                    ? 'App is protected with PIN'
                    : 'Protect app with PIN',
              ),
              value: _biometricEnabled && _biometricAvailable,
              onChanged: _biometricAvailable ? _toggleBiometric : null,
            ),
          ),
          const SizedBox(height: 8),
          // Fingerprint/Biometric Lock Card
          Card(
            child: SwitchListTile(
              secondary: Icon(
                _availableBiometrics.contains(BiometricType.face)
                    ? Icons.face
                    : Icons.fingerprint,
              ),
              title: Text('${_getBiometricTypeText()} Lock'),
              subtitle: Text(
                _biometricEnabled
                    ? 'App is protected with ${_getBiometricTypeText()}'
                    : _biometricAvailable
                        ? 'Protect app with ${_getBiometricTypeText()}'
                        : 'Not available on this device',
              ),
              value: _biometricEnabled,
              onChanged: _biometricAvailable ? _toggleBiometric : null,
            ),
          ),
          const SizedBox(height: 8),
          // Export Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export List'),
              subtitle: const Text('Save as TXT or PDF'),
              onTap: () {
                // Handle export functionality
              },
            ),
          ),
        ],
      ),
    );
  }
}