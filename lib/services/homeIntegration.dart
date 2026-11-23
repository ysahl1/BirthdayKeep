import 'dart:io';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppIcon {
  cake,
  balloons,
  calendar,
  cupcake;

  String get asset => 'assets/icon/app_icon_$name.png';
}

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

  // Zuletzt bekanntes Icon, damit Bilder ohne Flackern das richtige zeigen
  AppIcon currentAppIcon = AppIcon.cake;

  Future<AppIcon> getAppIcon() async {
    if (!Platform.isAndroid) return currentAppIcon;
    final name = await _channel.invokeMethod<String>('getAppIcon');
    return currentAppIcon = AppIcon.values.asNameMap()[name] ?? AppIcon.cake;
  }

  Future<void> setAppIcon(AppIcon icon) async {
    currentAppIcon = icon;
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setAppIcon', icon.name);
  }

  // Leiser Zweiklang nach dem Speichern eines Geburtstags
  Future<void> playSaveSound() async {
    if (!Platform.isAndroid || !AppSettings.instance.saveSound) return;
    try {
      await _channel.invokeMethod<void>('playSaveSound');
    } on PlatformException catch (e) {
      debugPrint('Playing save sound failed: $e');
    }
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
