import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class aboutBirthdayMarkerPage extends StatelessWidget {
  const aboutBirthdayMarkerPage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Birthday Marker')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),

                // Links Row: GitHub + F-Droid
                Row(
                  children: [
                    Expanded(
                      child: _linkButton(
                        context,
                        label: 'GitHub',
                        onTap: () => _launchUrl(
                            'https://github.com/ysahl1/BirthdayMarker'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _linkButton(
                        context,
                        label: 'F-Droid',
                        onTap: () => _launchUrl(
                            'https://f-droid.org/packages/com.ysahl1.birthdaymarker/'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Change Log
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Change Log'),
                    subtitle: const Text('Version 1.0.0'),
                    onTap: () => _launchUrl(
                        'https://github.com/ysahl1/BirthdayMarker/commits/main/'),
                  ),
                ),
                const SizedBox(height: 4),

                // Issue Tracker
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Issue Tracker'),
                    subtitle: const Text('Report bugs or request features'),
                    onTap: () => _launchUrl(
                        'https://github.com/ysahl1/BirthdayMarker/issues'),
                  ),
                ),
                const SizedBox(height: 4),

                // License
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('License'),
                    subtitle: const Text('MIT License 2025'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const _LicensePage()));
                    },
                  ),
                ),
                const SizedBox(height: 4),

                // Sponsor
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.volunteer_activism, size: 26),
                    title: const Text('Sponsor'),
                    subtitle: const Text('Support this App with a donation'),
                    onTap: () =>
                        _launchUrl('https://buymeacoffee.com/ysahl1'),
                  ),
                ),
              ],
            ),
          ),

          // App Icon
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/BDMIcon_2.png',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
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

          // Credits Footer
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stars_rounded,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Created by ysahl1',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
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
// GitHub Icon
// -------------------
class _GitHubIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(
      Icons.code,
      size: 22,
      color: isDark ? Colors.white : Colors.black87,
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
      appBar: AppBar(title: const Text('License')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MIT License',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Copyright © 2025 ysahl1\n\n'
                    'Permission is hereby granted, free of charge, to any person obtaining a copy '
                    'of this software and associated documentation files (the "Software"), to deal '
                    'in the Software without restriction, including without limitation the rights '
                    'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
                    'copies of the Software.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
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