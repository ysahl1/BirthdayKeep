/* =========================
   Datenschutz
========================= */
import 'package:flutter/material.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datenschutz & Sicherheit')),
      body: const Center(child: Text('Alle Daten bleiben lokal auf dem Gerät')),
    );
  }
}