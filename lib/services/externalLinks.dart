import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Bewusst ohne canLaunchUrl: Ab Android 11 meldet es ohne eigene
// Manifest-Einträge false, obwohl der Browser den Link öffnen könnte
Future<void> openExternalUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } on PlatformException catch (e) {
    debugPrint('Opening $url failed: $e');
  }
}
