/* =========================
   Geburtstagsliste
========================= */
import 'package:BirthdayMarker/birthdayPicker.dart';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:BirthdayMarker/services/appSettings.dart';
import 'package:BirthdayMarker/stretchListView.dart';
import 'package:BirthdayMarker/feedback.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthdayListPage extends StatefulWidget {
  final List<BirthdayEntry> entries;
  final int Function(DateTime) nextAge;
  final int Function(DateTime) daysUntil;
  final VoidCallback onUpdate;
  final VoidCallback onOpenCalendar;

  const BirthdayListPage({
    super.key,
    required this.entries,
    required this.nextAge,
    required this.daysUntil,
    required this.onUpdate,
    required this.onOpenCalendar,
  });

  @override
  State<BirthdayListPage> createState() => _BirthdayListPageState();
}

class _BirthdayListPageState extends State<BirthdayListPage> {
  SortOption _currentSort = SortOption.upcomingFromToday;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadSortSettings();
  }

  void _notifyUpdate() {
    widget.onUpdate();
    if (mounted) setState(() {});
  }

  void _openSearch(AppStrings s) {
    showSearch(
      context: context,
      delegate: BirthdaySearchDelegate(
        entries: widget.entries,
        labels: s,
        onSelect: (e) => _showDetails(context, e),
      ),
    );
  }

  // -------------------
  // Einstellungen laden
  // -------------------
  Future<void> _loadSortSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final sortIndex =
          prefs.getInt('sortOption') ?? SortOption.upcomingFromToday.index;
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
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21))
      return 'Scorpio';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21))
      return 'Sagittarius';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19))
      return 'Capricorn';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18))
      return 'Aquarius';
    return 'Pisces';
  }

  // -------------------
  // Sortierte Liste
  // -------------------
  List<BirthdayEntry> get _sortedEntries {
    final list = List<BirthdayEntry>.from(widget.entries);

    switch (_currentSort) {
      case SortOption.name:
        list.sort(
          (a, b) =>
              _isAscending
                  ? a.name.compareTo(b.name)
                  : b.name.compareTo(a.name),
        );
        break;

      case SortOption.birthdayYear:
        list.sort((a, b) {
          // Einträge ohne Jahr stehen immer am Ende
          if (a.yearKnown != b.yearKnown) return a.yearKnown ? -1 : 1;
          return _isAscending
              ? a.birthday.year.compareTo(b.birthday.year)
              : b.birthday.year.compareTo(a.birthday.year);
        });
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
      builder:
          (context) => AlertDialog(
            title: Text(AppStrings.of(context).sort),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSortOption(
                        icon: Icons.check,
                        label: AppStrings.of(context).name,
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
                        label: AppStrings.of(context).sortBirthYear,
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
                        label: AppStrings.of(context).sortRecentlyAdded,
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
                        label: AppStrings.of(context).sortFromToday,
                        isSelected:
                            _currentSort == SortOption.upcomingFromToday,
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
                        label: AppStrings.of(context).ascending,
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
                        label: AppStrings.of(context).descending,
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
                child: Text(AppStrings.of(context).close),
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
              color:
                  isSelected
                      ? (isDarkMode
                          ? Colors.white
                          : Theme.of(context).primaryColor)
                      : Colors.transparent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isSelected
                          ? (isDarkMode
                              ? Colors.white
                              : Theme.of(context).primaryColor)
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
    final entry =
        e ??
        BirthdayEntry(
          name: '',
          birthday: DateTime.now(),
          notificationTime: TimeOfDay.now(),
        );
    final nameCtrl = TextEditingController(text: entry.name);
    DateTime birthday = entry.birthday;
    TimeOfDay time = entry.notificationTime;
    bool yearKnown = entry.yearKnown;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setD) => AlertDialog(
                  title: Text(AppStrings.of(context).editBirthday),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.of(context).name,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final pick = await showBirthdayPicker(
                            context,
                            initialDate: birthday,
                            yearKnown: yearKnown,
                          );
                          if (pick != null) {
                            setD(() {
                              birthday = pick.date;
                              yearKnown = pick.yearKnown;
                            });
                          }
                        },
                        child: Text(
                          AppSettings.instance.formatDate(
                            birthday,
                            withYear: yearKnown,
                          ),
                        ),
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
                      child: Text(AppStrings.of(context).cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        entry.name = nameCtrl.text;
                        entry.birthday =
                            yearKnown
                                ? birthday
                                : BirthdayEntry.unknownYearDate(birthday);
                        entry.yearKnown = yearKnown;
                        entry.notificationTime = time;
                        _notifyUpdate();
                        Navigator.pop(context);
                      },
                      child: Text(AppStrings.of(context).save),
                    ),
                  ],
                ),
          ),
    );
  }

  // -------------------
  // Löschen mit Rückgängig
  // -------------------
  void _deleteEntry(BirthdayEntry e, AppStrings s) {
    final index = widget.entries.indexOf(e);
    widget.entries.remove(e);
    _notifyUpdate();
    showFeedback(
      context,
      s.entryDeleted(e.name),
      type: FeedbackType.info,
      icon: Icons.delete_outline_rounded,
      action: SnackBarAction(
        label: s.undo,
        onPressed: () {
          widget.entries.insert(index, e);
          _notifyUpdate();
        },
      ),
    );
  }

  // -------------------
  // Detail-Popup
  // -------------------
  void _showDetails(BuildContext context, BirthdayEntry e) {
    final age = widget.nextAge(e.birthday);
    final days = widget.daysUntil(e.birthday);
    final s = AppStrings.of(context);
    final zodiac = s.zodiac(_getZodiacSign(e.birthday));

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(e.name, overflow: TextOverflow.ellipsis)),
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
                Text(s.birthdayLabel(e.formattedDate)),
                const SizedBox(height: 6),
                Text(s.reminderLabel(e.notificationTime.format(context))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(s.zodiacLabel),
                    Text(
                      zodiac,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  days == 0
                      ? s.todayIsBirthday
                      : e.yearKnown
                      ? s.inDaysYearsOld(days, age)
                      : s.inDays(days),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteEntry(e, s);
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.close),
              ),
            ],
          ),
    );
  }

  Widget _monthHeader(BuildContext context, AppStrings s, int month) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(
        s.months[month - 1],
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // -------------------
  // Build
  // -------------------
  @override
  Widget build(BuildContext context) {
    final sortedEntries = _sortedEntries;
    final s = AppStrings.of(context);

    // Bei "Ab heute" steht über jedem Monat klein sein Name
    final rows = <Object>[];
    for (final e in sortedEntries) {
      final month = e.birthday.month;
      final previous = rows.isEmpty ? null : rows.last;
      if (_currentSort == SortOption.upcomingFromToday &&
          (previous is! BirthdayEntry || previous.birthday.month != month)) {
        rows.add(month);
      }
      rows.add(e);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.birthdayList),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: s.sort,
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: s.calendar,
            onPressed: widget.onOpenCalendar,
          ),
        ],
      ),
      body: GestureDetector(
        // Auch auf der leeren Fläche soll Zurückwischen funktionieren
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 200) {
            Navigator.maybePop(context);
          }
        },
        child:
            sortedEntries.isEmpty
                ? Center(child: Text(s.noEntries))
                : StretchListView.builder(
                  // Unten Platz lassen, damit der Such-Knopf keine Karte verdeckt
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    if (row is int) return _monthHeader(context, s, row);
                    final e = row as BirthdayEntry;
                    final d = widget.daysUntil(e.birthday);
                    final age = widget.nextAge(e.birthday);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text(e.name),
                        subtitle: Text(
                          e.yearKnown
                              ? (d == 0
                                  ? s.todayTurns(age)
                                  : s.inDaysTurns(d, age))
                              : (d == 0 ? s.today : s.inDays(d)),
                        ),
                        onTap: () => _showDetails(context, e),
                      ),
                    );
                  },
                ),
      ),
      // Der Knopf fliegt beim Seitenwechsel von selbst zur Mitte der Hauptseite
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSearch(s),
        child: const Icon(Icons.search),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// -------------------
// Sortier-Optionen
// -------------------
enum SortOption { name, birthdayYear, recentlyAdded, upcomingFromToday }

// -------------------
// Suchfunktion
// -------------------
class BirthdaySearchDelegate extends SearchDelegate<BirthdayEntry?> {
  final List<BirthdayEntry> entries;
  final AppStrings labels;
  final void Function(BirthdayEntry) onSelect;

  BirthdaySearchDelegate({
    required this.entries,
    required this.labels,
    required this.onSelect,
  });

  @override
  String get searchFieldLabel => labels.searchName;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
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
    final results =
        entries
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
    final suggestions =
        entries
            .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return _buildList(context, suggestions);
  }

  Widget _buildList(BuildContext context, List<BirthdayEntry> list) {
    if (list.isEmpty) return Center(child: Text(labels.noResults));

    return StretchListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        return ListTile(
          title: Text(e.name),
          subtitle: Text(e.formattedDate),
          onTap: () {
            close(context, e);
            onSelect(e);
          },
        );
      },
    );
  }
}
