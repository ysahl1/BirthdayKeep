import 'package:flutter/material.dart';
import 'package:BirthdayMarker/main.dart';

/* =========================
   Kalender Page
========================= */
class BirthdayCalendarWidget extends StatelessWidget {
  final List<BirthdayEntry> entries;
  const BirthdayCalendarWidget({super.key, required this.entries});

  String shortDate(DateTime d) {
    const weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final wd = weekdays[d.weekday - 1];
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year % 100} $wd';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: BirthdayCalendar(entries: entries, shortDate: shortDate),
    );
  }
}

/* =========================
   Kalender Widget
========================= */
class BirthdayCalendar extends StatefulWidget {
  final List<BirthdayEntry> entries;
  final String Function(DateTime) shortDate;

  const BirthdayCalendar({
    super.key,
    required this.entries,
    required this.shortDate,
  });

  @override
  State<BirthdayCalendar> createState() => _BirthdayCalendarState();
}

class _BirthdayCalendarState extends State<BirthdayCalendar> {
  DateTime month = DateTime.now();
  DateTime? selectedDay;

  int nextAge(DateTime birthday) {
    if (selectedDay == null) return 0;
    int age = selectedDay!.year - birthday.year;
    final bThisYear =
        DateTime(selectedDay!.year, birthday.month, birthday.day);
    return selectedDay!.isBefore(bThisYear) ? age : age + 1;
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // -------------------
        // Monatsnavigation
        // -------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month - 1)),
            ),
            Text(
              '${month.month}/${month.year}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month + 1)),
            ),
          ],
        ),

        // -------------------
        // Wochentags-Header
        // -------------------
        Row(
          children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),

        // -------------------
        // Kalender Grid (FIXE HÖHE)
        // -------------------
        SizedBox(
          height: 280, // <- reduzierte Höhe
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: 42,
            itemBuilder: (_, i) {
              final firstOfMonth = DateTime(month.year, month.month, 1);
              final startDay = firstOfMonth
                  .subtract(Duration(days: firstOfMonth.weekday - 1));
              final day = startDay.add(Duration(days: i));
              final isCurrentMonth = day.month == month.month;

              final birthdays = widget.entries.where(
                (e) =>
                    e.birthday.day == day.day &&
                    e.birthday.month == day.month,
              ).toList();

              final textColor = isCurrentMonth
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : Colors.grey;

              return GestureDetector(
                onTap: birthdays.isNotEmpty
                    ? () {
                        setState(() {
                          selectedDay = day;
                        });
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: birthdays.isNotEmpty
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (birthdays.isNotEmpty)
                        Flexible(
                          child: Text(
                            widget.shortDate(day),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: textColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // -------------------
        // Geburtstagsliste UNTER dem Kalender
        // -------------------
        if (selectedDay != null)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: widget.entries
                      .where(
                        (e) =>
                            e.birthday.day == selectedDay!.day &&
                            e.birthday.month == selectedDay!.month,
                      )
                      .isEmpty
                  ? Center(
                      child: Text(
                        'No birthdays on ${selectedDay!.day}.${selectedDay!.month}.${selectedDay!.year}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.entries
                          .where(
                            (e) =>
                                e.birthday.day == selectedDay!.day &&
                                e.birthday.month == selectedDay!.month,
                          )
                          .length,
                      itemBuilder: (context, index) {
                        final birthdaysOnDay = widget.entries
                            .where(
                              (e) =>
                                  e.birthday.day == selectedDay!.day &&
                                  e.birthday.month == selectedDay!.month,
                            )
                            .toList();
                        final e = birthdaysOnDay[index];
                        final age = nextAge(e.birthday);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            title:
                                Text('${e.name} becomes $age years old'),
                          ),
                        );
                      },
                    ),
            ),
          ),
      ],
    );
  }
}