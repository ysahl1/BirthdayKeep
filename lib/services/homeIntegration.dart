import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Verbindung zu Widgets, Schnelleinstellungen und App-Shortcuts (Android)
class HomeIntegration {
  HomeIntegration._();
  static final HomeIntegration instance = HomeIntegration._();

  static const MethodChannel _channel = MethodChannel('birthdaykeep/home');

  void listen(ValueChanged<String> onAction) {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'actionAvailable') return;
      final action = await takePendingAction();
      if (action != null) onAction(action);
    });
  }

  Future<String?> takePendingAction() async {
    if (!Platform.isAndroid) return null;
    return _channel.invokeMethod<String>('takePendingAction');
  }

  Future<void> refreshWidgets() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('refreshWidgets');
    } on PlatformException catch (e) {
      debugPrint('Refreshing widgets failed: $e');
    }
  }
}
