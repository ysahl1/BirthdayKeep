import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/services/birthdayStore.dart';
import 'package:BirthdayMarker/services/homeIntegration.dart';
import 'package:BirthdayMarker/services/notificationService.dart';
import 'package:BirthdayMarker/stretchListView.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final AppSettings _settings = AppSettings.instance;
  final NotificationService _notifications = NotificationService.instance;
  bool _hasPermission = true;

  static final DateTime _exampleDate = DateTime(2026, 1, 15);

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await _notifications.hasPermission();
    if (mounted) setState(() => _hasPermission = granted);
  }

  Future<void> _requestPermission() async {
    final granted = await _notifications.requestPermission();
    if (mounted) setState(() => _hasPermission = granted);
    await _notifications.reschedule();
  }

  void _showLeadTimeDialog() {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setD) {
              final selected = _settings.leadDays;
              return AlertDialog(
                title: Text(s.leadTime),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      AppSettings.leadDayOptions.map((days) {
                        final isSelected = selected.contains(days);
                        return CheckboxListTile(
                          title: Text(s.leadTimeOption(days)),
                          value: isSelected,
                          // Mindestens eine Option muss ausgewählt bleiben
                          onChanged:
                              isSelected && selected.length == 1
                                  ? null
                                  : (value) {
                                    final next = List<int>.from(selected);
                                    value! ? next.add(days) : next.remove(days);
                                    _settings.leadDays = next;
                                    setD(() {});
                                    setState(() {});
                                    _notifications.reschedule();
                                  },
                        );
                      }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(s.close),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showDateFormatDialog() {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(s.dateFormat),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    DateStyle.values.map((style) {
                      return RadioListTile<DateStyle>(
                        title: Text(style.format(_exampleDate)),
                        value: style,
                        groupValue: _settings.dateStyle,
                        onChanged: (value) {
                          setState(() => _settings.dateStyle = value!);
                          HomeIntegration.instance.refreshWidgets();
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
              ),
            ),
          ),
    );
  }

  Future<void> _pickDefaultTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _settings.defaultNotificationTime,
    );
    if (time != null) {
      setState(() => _settings.defaultNotificationTime = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final excluded =
        BirthdayStore.instance.entries
            .where((e) => !e.notificationsEnabled)
            .length;

    return Scaffold(
      appBar: AppBar(title: Text(s.notifications)),
      body: StretchListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_hasPermission)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.notifications_off),
                title: Text(s.permissionDenied),
                subtitle: Text(s.permissionDeniedHint),
                onTap: _requestPermission,
              ),
            ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.repeat),
              title: Text(s.automaticNotification),
              subtitle: Text(
                _settings.notificationsEnabled ? s.automaticOn : s.automaticOff,
              ),
              value: _settings.notificationsEnabled,
              onChanged: (value) {
                setState(() => _settings.notificationsEnabled = value);
                if (value) _requestPermission();
                _notifications.reschedule();
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.date_range),
              title: Text(s.leadTime),
              subtitle: Text(
                _settings.leadDays.map(s.leadTimeOption).join(', '),
              ),
              onTap: _showLeadTimeDialog,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(s.defaultTime),
              subtitle: Text(_settings.defaultNotificationTime.format(context)),
              onTap: _pickDefaultTime,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_note),
              title: Text(s.dateFormat),
              subtitle: Text(_settings.dateStyle.format(_exampleDate)),
              onTap: _showDateFormatDialog,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: Text(s.excludePeople),
              subtitle: Text(s.excludedCount(excluded)),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _ExcludePeoplePage()),
                );
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExcludePeoplePage extends StatefulWidget {
  const _ExcludePeoplePage();

  @override
  State<_ExcludePeoplePage> createState() => _ExcludePeoplePageState();
}

class _ExcludePeoplePageState extends State<_ExcludePeoplePage> {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final entries = List.of(BirthdayStore.instance.entries)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: Text(s.excludePeople)),
      body:
          entries.isEmpty
              ? Center(child: Text(s.noEntries))
              : StretchListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return Card(
                    child: SwitchListTile(
                      title: Text(e.name),
                      value: e.notificationsEnabled,
                      onChanged: (value) {
                        setState(() => e.notificationsEnabled = value);
                        BirthdayStore.instance.save();
                      },
                    ),
                  );
                },
              ),
    );
  }
}
