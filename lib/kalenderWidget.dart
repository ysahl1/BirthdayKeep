import 'package:flutter/material.dart';
import 'package:BirthdayMarker/main.dart';
/* =========================
   Kalender Page
========================= */
class BirthdayCalendarPage extends StatelessWidget {
  final List<BirthdayEntry> entries;
  const BirthdayCalendarPage({super.key, required this.entries, required List<BirthdayEntry> birthdayEntries});

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

  const BirthdayCalendar({super.key, required this.entries, required this.shortDate});

  @override
  State<BirthdayCalendar> createState() => _BirthdayCalendarState();
}

class _BirthdayCalendarState extends State<BirthdayCalendar> {
  DateTime month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)),
            ),
            Text('${month.month}.${month.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)),
            ),
          ],
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: days + offset,
            itemBuilder: (_, i) {
              if (i < offset) return const SizedBox();
              final day = DateTime(month.year, month.month, i - offset + 1);
              final birthdays = widget.entries.where((e) => e.birthday.day == day.day && e.birthday.month == day.month);

              return Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: birthdays.isNotEmpty ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.day}'),
                    if (birthdays.isNotEmpty)
                      Text(widget.shortDate(day), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
