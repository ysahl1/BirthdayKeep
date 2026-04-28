/* =========================
   Geburtstagsliste
========================= */
import 'package:BirthdayMarker/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthdayListPage extends StatefulWidget {
  final List<BirthdayEntry> entries;
  final int Function(DateTime) nextAge;
  final int Function(DateTime) daysUntil;
  final VoidCallback onUpdate;

  const BirthdayListPage({
    super.key,
    required this.entries,
    required this.nextAge,
    required this.daysUntil,
    required this.onUpdate,
  });

  @override
  State<BirthdayListPage> createState() => _BirthdayListPageState();
}

class _BirthdayListPageState extends State<BirthdayListPage> {
  SortOption _currentSort = SortOption.name;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadSortSettings();
  }

  // -------------------
  // Einstellungen laden
  // -------------------
  Future<void> _loadSortSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final sortIndex = prefs.getInt('sortOption') ?? 0;
      _currentSort = SortOption.values[sortIndex];
      _isAscending = prefs.getBool('isAscending') ?? true;
    });
  }

  // -------------------
  // Einstellungen speichern
  // -------------------
  Future<void> _saveSortSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortOption', _currentSort.index);
    await prefs.setBool('isAscending', _isAscending);
  }

  // -------------------
  // Zodiac Sign
  // -------------------
  String _getZodiacSign(DateTime birthday) {
    final month = birthday.month;
    final day = birthday.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Aries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Taurus';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gemini';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Cancer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leo';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgo';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Scorpio';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagittarius';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Capricorn';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquarius';
    return 'Pisces';
  }

  // -------------------
  // Sortierte Liste
  // -------------------
  List<BirthdayEntry> get _sortedEntries {
    final list = List<BirthdayEntry>.from(widget.entries);

    switch (_currentSort) {
      case SortOption.name:
        list.sort((a, b) => _isAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;

      case SortOption.birthdayYear:
        list.sort((a, b) => _isAscending
            ? a.birthday.year.compareTo(b.birthday.year)
            : b.birthday.year.compareTo(a.birthday.year));
        break;

      case SortOption.recentlyAdded:
        if (!_isAscending) {
          return list.reversed.toList();
        }
        break;

      case SortOption.upcomingFromToday:
        list.sort((a, b) {
          final dA = widget.daysUntil(a.birthday);
          final dB = widget.daysUntil(b.birthday);
          return _isAscending ? dA.compareTo(dB) : dB.compareTo(dA);
        });
        break;
    }

    return list;
  }

  // -------------------
  // Filter-Dialog
  // -------------------
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption(
                icon: Icons.check,
                label: 'Name',
                isSelected: _currentSort == SortOption.name,
                onTap: () {
                  setDialogState(() {
                    setState(() {
                      _currentSort = SortOption.name;
                    });
                  });
                  _saveSortSettings();
                },
              ),
              _buildSortOption(
                icon: Icons.check,
                label: 'Geburtsjahr',
                isSelected: _currentSort == SortOption.birthdayYear,
                onTap: () {
                  setDialogState(() {
                    setState(() {
                      _currentSort = SortOption.birthdayYear;
                    });
                  });
                  _saveSortSettings();
                },
              ),
              _buildSortOption(
                icon: Icons.check,
                label: 'Zuletzt hinzugefügt',
                isSelected: _currentSort == SortOption.recentlyAdded,
                onTap: () {
                  setDialogState(() {
                    setState(() {
                      _currentSort = SortOption.recentlyAdded;
                    });
                  });
                  _saveSortSettings();
                },
              ),
              _buildSortOption(
                icon: Icons.check,
                label: 'Ab heute',
                isSelected: _currentSort == SortOption.upcomingFromToday,
                onTap: () {
                  setDialogState(() {
                    setState(() {
                      _currentSort = SortOption.upcomingFromToday;
                    });
                  });
                  _saveSortSettings();
                },
              ),
              const Divider(height: 32),
              _buildSortOption(
                icon: Icons.check,
                label: 'Aufsteigend',
                isSelected: _isAscending,
                onTap: () {
                  setDialogState(() {
                    setState(() {
                      _isAscending = true;
                    });
                  });
                  _saveSortSettings();
                },
              ),
              _buildSortOption(
                icon: Icons.check,
                label: 'Absteigend',
                isSelected: !_isAscending,
                onTap: () {
                  setDialogState(() {
                    setState(() {
                      _isAscending = false;
                    });
                  });
                  _saveSortSettings();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDarkMode ? Colors.white : Theme.of(context).primaryColor)
                  : Colors.transparent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected
                      ? (isDarkMode ? Colors.white : Theme.of(context).primaryColor)
                      : (isDarkMode ? Colors.grey : null),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------
  // Edit-Dialog
  // -------------------
  void _editPerson(BuildContext context, BirthdayEntry? e) {
    final entry = e ??
        BirthdayEntry(
            name: '', birthday: DateTime.now(), notificationTime: TimeOfDay.now());
    final nameCtrl = TextEditingController(text: entry.name);
    DateTime birthday = entry.birthday;
    TimeOfDay time = entry.notificationTime;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('Edit Birthday'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: birthday,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setD(() => birthday = d);
                },
                child: Text('${birthday.day}.${birthday.month}.${birthday.year}'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (t != null) setD(() => time = t);
                },
                child: Text(time.format(context)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                entry.name = nameCtrl.text;
                entry.birthday = birthday;
                entry.notificationTime = time;
                widget.onUpdate();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------
  // Detail-Popup
  // -------------------
  void _showDetails(BuildContext context, BirthdayEntry e) {
    final age = widget.nextAge(e.birthday);
    final days = widget.daysUntil(e.birthday);
    final zodiac = _getZodiacSign(e.birthday);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                e.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pop(context);
                _editPerson(context, e);
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Birthday: ${e.birthday.day}.${e.birthday.month}.${e.birthday.year}'),
            const SizedBox(height: 6),
            Text('Reminder: ${e.notificationTime.format(context)}'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Zodiac Sign:  '),
                Text(
                  zodiac,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              days == 0
                  ? 'Today is the birthday!'
                  : 'In $days Days ($age years old)',
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                widget.entries.remove(e);
              });
              widget.onUpdate();
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // -------------------
  // Build
  // -------------------
  @override
  Widget build(BuildContext context) {
    final sortedEntries = _sortedEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthday List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedEntries.length,
        itemBuilder: (context, i) {
          final e = sortedEntries[i];
          final d = widget.daysUntil(e.birthday);

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(e.name),
              subtitle: Text(d == 0
                  ? 'Today ${widget.nextAge(e.birthday)}'
                  : 'In $d Days (${widget.nextAge(e.birthday)})'),
              trailing: GestureDetector(
                onTap: () => _editPerson(context, e),
                child: const SizedBox(width: 24, height: 24),
              ),
              onTap: () => _showDetails(context, e),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () {
          showSearch(
            context: context,
            delegate: BirthdaySearchDelegate(
              entries: widget.entries,
              onSelect: (e) => _showDetails(context, e),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// -------------------
// Sortier-Optionen
// -------------------
enum SortOption {
  name,
  birthdayYear,
  recentlyAdded,
  upcomingFromToday,
}

// -------------------
// Suchfunktion
// -------------------
class BirthdaySearchDelegate extends SearchDelegate<BirthdayEntry?> {
  final List<BirthdayEntry> entries;
  final void Function(BirthdayEntry) onSelect;

  BirthdaySearchDelegate({
    required this.entries,
    required this.onSelect,
  });

  @override
  String get searchFieldLabel => 'Search Name';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = entries
        .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildList(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(' ', style: TextStyle(color: Colors.grey)),
      );
    }
    final suggestions = entries
        .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildList(context, suggestions);
  }

  Widget _buildList(BuildContext context, List<BirthdayEntry> list) {
    if (list.isEmpty) return const Center(child: Text('No results'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        return ListTile(
          title: Text(e.name),
          subtitle: Text('${e.birthday.day}.${e.birthday.month}.${e.birthday.year}'),
          onTap: () {
            close(context, e);
            onSelect(e);
          },
        );
      },
    );
  }
}