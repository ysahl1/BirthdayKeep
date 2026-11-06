import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/services/externalLinks.dart';
import 'package:BirthdayMarker/stretchListView.dart';
import 'package:flutter/material.dart';

class _Credit {
  final String name;
  final String license;
  final String url;
  const _Credit(this.name, this.license, this.url);
}

const String _apache = 'Apache License, Version 2.0';
const String _bsd3 = 'BSD 3-Clause License';
const String _bsd2 = 'BSD 2-Clause License';
const String _mit = 'MIT License';

const List<_Credit> _credits = [
  _Credit('Flutter', _bsd3, 'https://github.com/flutter/flutter'),
  _Credit('Kotlin', _apache, 'https://github.com/JetBrains/kotlin'),
  _Credit(
    'crypto',
    _bsd3,
    'https://github.com/dart-lang/core/tree/main/pkgs/crypto',
  ),
  _Credit(
    'file_picker',
    _mit,
    'https://github.com/vicajilau/flutter_file_picker',
  ),
  _Credit(
    'flutter_local_notifications',
    _bsd3,
    'https://github.com/MaikuB/flutter_local_notifications',
  ),
  _Credit(
    'flutter_timezone',
    _apache,
    'https://github.com/tjarvstrand/flutter_timezone',
  ),
  _Credit(
    'local_auth',
    _bsd3,
    'https://github.com/flutter/packages/tree/main/packages/local_auth',
  ),
  _Credit(
    'package_info_plus',
    _bsd3,
    'https://github.com/fluttercommunity/plus_plugins',
  ),
  _Credit('pdf', _apache, 'https://github.com/DavBfr/dart_pdf'),
  _Credit(
    'shared_preferences',
    _bsd3,
    'https://github.com/flutter/packages/tree/main/packages/shared_preferences',
  ),
  _Credit(
    'timezone',
    _bsd2,
    'https://github.com/dart-lang/labs/tree/main/pkgs/timezone',
  ),
  _Credit(
    'url_launcher',
    _bsd3,
    'https://github.com/flutter/packages/tree/main/packages/url_launcher',
  ),
  _Credit(
    'Material Icons',
    'Creative Commons Attribution 4.0',
    'https://github.com/google/material-design-icons',
  ),
  _Credit('Roboto', _apache, 'https://github.com/googlefonts/roboto'),
];

/* =========================
   Credits
========================= */
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.credits)),
      body: StretchListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/BDMIcon.png',
                      width: 96,
                      height: 96,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.creditsThanks,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          for (final credit in _credits)
            Card(
              child: ListTile(
                title: Text(credit.name),
                subtitle: Text(credit.license),
                onTap: () => openExternalUrl(credit.url),
              ),
            ),
        ],
      ),
    );
  }
}
