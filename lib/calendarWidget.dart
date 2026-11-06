import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:BirthdayMarker/main.dart';
import 'package:BirthdayMarker/stretchListView.dart';
import 'package:flutter/material.dart';

/* =========================
   Kalender Page
========================= */
class BirthdayCalendarPage extends StatelessWidget {
  final List<BirthdayEntry> entries;
  const BirthdayCalendarPage({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).calendar)),
      body: BirthdayCalendar(entries: entries),
    );
  }
}

/* =========================
   Kalender Widget
========================= */
class BirthdayCalendar extends StatefulWidget {
  final List<BirthdayEntry> entries;

  const BirthdayCalendar({super.key, required this.entries});

  // Die 42 Tage der Monatsansicht, beginnend mit dem Montag der ersten Woche.
  // Über Kalendertage gerechnet, damit Zeitumstellungen keinen Tag doppeln.
  static List<DateTime> gridDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    return List.generate(
      42,
      (i) => DateTime(first.year, first.month, 1 - (first.weekday - 1) + i),
    );
  }

  // Wer am 29. Februar geboren ist, erscheint sonst am 28., wie bei der
  // Erinnerung. Tage vor der Geburt bleiben leer.
  @visibleForTesting
  static List<BirthdayEntry> birthdaysOn(
    List<BirthdayEntry> entries,
    DateTime day,
  ) {
    return entries.where((e) {
      if (e.yearKnown && day.year < e.birthday.year) return false;
      if (e.birthday.month != day.month) return false;
      final lastDay = DateUtils.getDaysInMonth(day.year, day.month);
      final birthdayDay = e.birthday.day > lastDay ? lastDay : e.birthday.day;
      return birthdayDay == day.day;
    }).toList();
  }

  @override
  State<BirthdayCalendar> createState() => _BirthdayCalendarState();
}

class _BirthdayCalendarState extends State<BirthdayCalendar> {
  DateTime month = DateTime.now();
  DateTime? selectedDay;

  // Richtung des letzten Monatswechsels, für die Schiebe-Animation
  int _direction = 1;

  void _changeMonth(int delta) {
    _direction = delta;
    setState(() {
      month = DateTime(month.year, month.month + delta);
      selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final days = BirthdayCalendar.gridDays(month);
    final birthdaysOnSelectedDay =
        selectedDay == null
            ? const <BirthdayEntry>[]
            : BirthdayCalendar.birthdaysOn(widget.entries, selectedDay!);

    return StretchListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 200) _changeMonth(-1);
            if (velocity < -200) _changeMonth(1);
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // -------------------
                  // Monatsnavigation
                  // -------------------
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Expanded(
                        child: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMonthYear(month),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),

                  // -------------------
                  // Wochentags-Header
                  // -------------------
                  Row(
                    children:
                        s.weekdays
                            .map(
                              (d) => Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 4),

                  // -------------------
                  // Kalender Grid
                  // -------------------
                  ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        final incoming = child.key == ValueKey(month);
                        final offset = Tween<Offset>(
                          begin: Offset(
                            incoming
                                ? _direction.toDouble()
                                : -_direction.toDouble(),
                            0,
                          ),
                          end: Offset.zero,
                        ).animate(animation);
                        return SlideTransition(position: offset, child: child);
                      },
                      child: KeyedSubtree(
                        key: ValueKey(month),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 0.9,
                              ),
                          itemCount: days.length,
                          itemBuilder: (_, i) {
                            final day = days[i];
                            final isCurrentMonth = day.month == month.month;
                            final isSelected = day == selectedDay;
                            final birthdays = BirthdayCalendar.birthdaysOn(
                              widget.entries,
                              day,
                            );
                            final textColor =
                                isCurrentMonth ? colors.onSurface : Colors.grey;

                            return GestureDetector(
                              onTap:
                                  birthdays.isNotEmpty
                                      ? () => setState(() => selectedDay = day)
                                      : null,
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      isSelected
                                          ? colors.primary.withValues(
                                            alpha: 0.3,
                                          )
                                          : null,
                                  border:
                                      day == today
                                          ? Border.all(
                                            color: colors.primary,
                                            width: 2,
                                          )
                                          : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Große Systemschrift darf nicht aus der Zelle laufen
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${day.day}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (birthdays.isNotEmpty)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // -------------------
        // Geburtstagsliste UNTER dem Kalender
        // -------------------
        for (final e in birthdaysOnSelectedDay)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(e.name),
              subtitle: Text(
                e.yearKnown
                    ? s.turnsAge(selectedDay!.year - e.birthday.year)
                    : s.hasBirthday,
              ),
            ),
          ),
      ],
    );
  }
}
