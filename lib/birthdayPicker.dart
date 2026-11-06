import 'dart:math';
import 'package:BirthdayMarker/calendarWidget.dart';
import 'package:BirthdayMarker/l10n/appStrings.dart';
import 'package:flutter/material.dart';

typedef BirthdayPick = ({DateTime date, bool yearKnown});

// Ohne Jahr wird in einem Schaltjahr gerechnet, damit es den 29. Februar gibt
const int _unknownYear = 2000;
const int _firstYear = 1900;
const double _bodyHeight = 320;

Future<BirthdayPick?> showBirthdayPicker(
  BuildContext context, {
  DateTime? initialDate,
  bool yearKnown = true,
}) {
  return showDialog<BirthdayPick>(
    context: context,
    builder:
        (_) => _BirthdayPickerDialog(
          initialDate: initialDate ?? DateUtils.dateOnly(DateTime.now()),
          yearKnown: yearKnown,
        ),
  );
}

/* =========================
   Geburtstag wählen
========================= */
class _BirthdayPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final bool yearKnown;

  const _BirthdayPickerDialog({
    required this.initialDate,
    required this.yearKnown,
  });

  @override
  State<_BirthdayPickerDialog> createState() => _BirthdayPickerDialogState();
}

class _BirthdayPickerDialogState extends State<_BirthdayPickerDialog> {
  final DateTime _today = DateUtils.dateOnly(DateTime.now());
  late int? _year = widget.yearKnown ? widget.initialDate.year : null;
  late DateTime _selected = DateTime(
    _year ?? _unknownYear,
    widget.initialDate.month,
    widget.initialDate.day,
  );
  late DateTime _month = DateTime(_selected.year, _selected.month);
  bool _yearMode = false;

  bool _isSelectable(DateTime day) => _year == null || !day.isAfter(_today);

  void _changeMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    setState(() {
      if (_year == null) {
        // Ohne Jahr nur durch die zwölf Monate blättern
        _month = DateTime(_unknownYear, (next.month - 1) % 12 + 1);
      } else if (!next.isBefore(DateTime(_firstYear)) &&
          !next.isAfter(DateTime(_today.year, _today.month))) {
        _month = next;
      }
    });
  }

  void _chooseYear(int? year) {
    final targetYear = year ?? _unknownYear;
    final lastDay = DateUtils.getDaysInMonth(targetYear, _selected.month);
    var date = DateTime(
      targetYear,
      _selected.month,
      min(_selected.day, lastDay),
    );
    if (year != null && date.isAfter(_today)) date = _today;
    setState(() {
      _year = year;
      _selected = date;
      _month = DateTime(date.year, date.month);
      _yearMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------
          // Kopf: Jahr und Datum
          // -------------------
          Container(
            color: colors.surfaceContainerHighest,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  key: const Key('birthdayPickerYear'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _yearMode = !_yearMode),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _year?.toString() ?? s.yearUnknownShort,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Icon(
                        _yearMode ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _year == null
                        ? localizations.formatShortMonthDay(_selected)
                        : localizations.formatMediumDate(_selected),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: _bodyHeight,
            child:
                _yearMode ? _buildYearList(s, colors) : _buildDays(s, colors),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.cancel),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.pop(context, (
                        date: _selected,
                        yearKnown: _year != null,
                      )),
                  child: Text(s.ok),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------
  // Jahresliste: eine Spalte, unter dem aktuellen Jahr "Jahr unbekannt"
  // -------------------
  Widget _buildYearList(AppStrings s, ColorScheme colors) {
    const itemHeight = 56.0;
    final years = _today.year - _firstYear + 1;
    final selectedIndex = _year == null ? years : _year! - _firstYear;
    final controller = ScrollController(
      initialScrollOffset: max(
        0,
        selectedIndex * itemHeight - (_bodyHeight - itemHeight) / 2,
      ),
    );

    return ListView.builder(
      controller: controller,
      itemExtent: itemHeight,
      itemCount: years + 1,
      itemBuilder: (context, i) {
        final year = i < years ? _firstYear + i : null;
        final selected = i == selectedIndex;
        return InkWell(
          onTap: () => _chooseYear(year),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration:
                  selected
                      ? BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(20),
                      )
                      : null,
              child: Text(
                year?.toString() ?? s.yearUnknownShort,
                style: TextStyle(
                  fontSize: 18,
                  color: selected ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------
  // Tage des Monats
  // -------------------
  Widget _buildDays(AppStrings s, ColorScheme colors) {
    final monthTitle =
        _year == null
            ? s.months[_month.month - 1]
            : MaterialLocalizations.of(context).formatMonthYear(_month);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Expanded(
                child: Text(
                  monthTitle,
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
          Row(
            children:
                s.weekdays
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / 7;
                final cellHeight = min(cellWidth, constraints.maxHeight / 6);
                final days = BirthdayCalendar.gridDays(_month);
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: cellWidth / cellHeight,
                  ),
                  itemCount: days.length,
                  itemBuilder: (_, i) {
                    final day = days[i];
                    if (day.month != _month.month) return const SizedBox();
                    final selectable = _isSelectable(day);
                    final selected = day == _selected;
                    return InkWell(
                      customBorder: const CircleBorder(),
                      onTap:
                          selectable
                              ? () => setState(() => _selected = day)
                              : null,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration:
                            selected
                                ? BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                )
                                : null,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color:
                                    selected
                                        ? colors.onPrimary
                                        : selectable
                                        ? colors.onSurface
                                        : colors.onSurface.withValues(
                                          alpha: 0.3,
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
