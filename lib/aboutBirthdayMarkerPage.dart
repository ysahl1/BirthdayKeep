import 'package:BirthdayMarker/creditsPage.dart';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/services/externalLinks.dart';
import 'package:BirthdayMarker/stretchListView.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class aboutBirthdayMarkerPage extends StatelessWidget {
  const aboutBirthdayMarkerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.about)),
      body: StretchListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Links Row: GitHub + F-Droid
          Row(
            children: [
              Expanded(
                child: _linkButton(
                  context,
                  label: 'GitHub',
                  onTap:
                      () => openExternalUrl(
                        'https://github.com/ysahl1/BirthdayKeep',
                      ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _linkButton(
                  context,
                  label: 'F-Droid',
                  onTap:
                      () => openExternalUrl(
                        'https://f-droid.org/packages/com.ysahl1.birthdaykeep/',
                      ),
                ),
              ),
            ],
          ),

          // Change Log
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(s.changeLog),
              subtitle: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder:
                    (_, info) => Text(
                      info.hasData ? 'Version ${info.data!.version}' : '',
                    ),
              ),
              onTap:
                  () => openExternalUrl(
                    'https://github.com/ysahl1/BirthdayKeep/releases',
                  ),
            ),
          ),

          // Issue Tracker
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(s.issueTracker),
              subtitle: Text(s.issueTrackerHint),
              onTap:
                  () => openExternalUrl(
                    'https://github.com/ysahl1/BirthdayKeep/issues',
                  ),
            ),
          ),

          // License
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(s.license),
              subtitle: const Text('MIT License 2025'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const _LicensePage()),
                );
              },
            ),
          ),

          // Credits
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(s.credits),
              subtitle: Text(s.creditsHint),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreditsPage()),
                );
              },
            ),
          ),

          // Sponsor
          Card(
            child: ListTile(
              leading: const Icon(Icons.volunteer_activism, size: 26),
              title: Text(s.sponsor),
              subtitle: Text(s.sponsorHint),
              onTap: () => openExternalUrl('https://buymeacoffee.com/ysahl1'),
            ),
          ),

          // More from the developer
          Card(
            child: ListTile(
              leading: const Icon(Icons.apps_rounded),
              title: Text(s.moreFromDeveloper),
              subtitle: Text(s.moreFromDeveloperHint),
              onTap: () => openExternalUrl('https://github.com/ysahl1'),
            ),
          ),

          // App Icon
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon/BDMIcon.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.cake,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                ),
              ),
            ),
          ),

          // Credits Footer
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copyright, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  s.createdBy,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkButton(
    BuildContext context, {
    required String label,
    required VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------
// License Page
// -------------------
class _LicensePage extends StatelessWidget {
  const _LicensePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).license)),
      body: StretchListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MIT License',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Copyright © 2025 ysahl1\n\n'
                    'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\n'
                    'The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\n'
                    'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
