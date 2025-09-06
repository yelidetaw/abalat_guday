// lib/ethiopian_calendar/ethiopian_date_picker.dart

import 'package:flutter/material.dart';

// Global constant for Ethiopian month names
const List<String> ethiopianMonths = [
  "መስከረም", "ጥቅምት", "ኅዳር", "ታኅሣሥ", "ጥር", "የካቲት",
  "መጋቢት", "ሚያዝያ", "ግንቦт", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜን"
];

// Helper function to show the Ethiopian Date Picker dialog
Future<EtDateTime?> showEthiopianDatePicker({
  required BuildContext context,
  EtDateTime? initialDate,
  EtDateTime? firstDate,
  EtDateTime? lastDate,
  String helpText = 'ቀን ይምረጡ', // "Select Date"
}) {
  final now = EthiopianCalendar.now();
  
  // Set default values if not provided
  initialDate ??= now;
  firstDate ??= EtDateTime(year: now.year - 100, month: 1, day: 1);
  lastDate ??= EtDateTime(year: now.year + 100, month: 13, day: 5);

  return showDialog<EtDateTime>(
    context: context,
    builder: (BuildContext context) {
      return _EthiopianDatePickerDialog(
        initialDate: initialDate!,
        firstDate: firstDate!,
        lastDate: lastDate!,
        helpText: helpText,
      );
    },
  );
}

// The internal stateful widget for the date picker dialog
class _EthiopianDatePickerDialog extends StatefulWidget {
  final EtDateTime initialDate;
  final EtDateTime firstDate;
  final EtDateTime lastDate;
  final String helpText;

  const _EthiopianDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.helpText,
  });

  @override
  State<_EthiopianDatePickerDialog> createState() => _EthiopianDatePickerDialogState();
}

class _EthiopianDatePickerDialogState extends State<_EthiopianDatePickerDialog> {
  late EtDateTime _selectedDate;
  late EtDateTime _currentDisplayedMonth;
  late int _selectedYear;
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    // Use the provided initial date (which defaults to current date)
    _selectedDate = widget.initialDate;
    
    // Set the displayed month to the initial date's month and year
    _currentDisplayedMonth = EtDateTime(
      year: widget.initialDate.year, 
      month: widget.initialDate.month
    );
    
    _selectedYear = widget.initialDate.year;
    _years = [for (var i = widget.firstDate.year; i <= widget.lastDate.year; i++) i];
  }

  void _changeMonth(int amount) {
    setState(() {
      int newMonth = _currentDisplayedMonth.month + amount;
      int newYear = _currentDisplayedMonth.year;

      if (newMonth > 13) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 13;
        newYear--;
      }
      
      final newDate = EtDateTime(year: newYear, month: newMonth);

      // Ensure the new month is within the valid range before updating
      if (!newDate.isAfter(widget.lastDate) && !newDate.isBefore(widget.firstDate)) {
        _currentDisplayedMonth = newDate;
        _selectedYear = newYear;
      }
    });
  }

  void _changeYear(int? year) {
    if (year == null) return;
    setState(() {
      _selectedYear = year;
      int newMonth = _currentDisplayedMonth.month;

      // Adjust month if the new year makes the current month out of bounds
      if (_selectedYear == widget.firstDate.year && newMonth < widget.firstDate.month) {
        newMonth = widget.firstDate.month;
      }
      if (_selectedYear == widget.lastDate.year && newMonth > widget.lastDate.month) {
        newMonth = widget.lastDate.month;
      }
      
      _currentDisplayedMonth = EtDateTime(year: _selectedYear, month: newMonth);
    });
  }

  Widget _buildDaysGrid() {
    final daysInMonth = EthiopianCalendar.getDaysInMonth(_currentDisplayedMonth.year, _currentDisplayedMonth.month);
    final firstDayOfMonth = EtDateTime(year: _currentDisplayedMonth.year, month: _currentDisplayedMonth.month, day: 1);
    
    // The weekday of the first day of the month (Sunday=0, Monday=1, ...)
    final firstDayWeekday = EthiopianCalendar.toGregorian(firstDayOfMonth).weekday % 7;

    List<Widget> dayWidgets = List.generate(firstDayWeekday, (_) => Container());

    // Add the actual day widgets
    for (int day = 1; day <= daysInMonth; day++) {
      final date = EtDateTime(year: _currentDisplayedMonth.year, month: _currentDisplayedMonth.month, day: day);
      final isSelected = date == _selectedDate;
      final isDisabled = date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);

      dayWidgets.add(
        InkWell(
          onTap: isDisabled ? null : () {
            setState(() => _selectedDate = date);
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : (isDisabled ? Colors.grey[400] : Colors.black),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: dayWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.helpText, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                Row(
                  children: [
                    Text(
                      '${ethiopianMonths[_currentDisplayedMonth.month - 1]} ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      value: _selectedYear,
                      items: _years.map((int year) => DropdownMenuItem<int>(value: year, child: Text(year.toString()))).toList(),
                      onChanged: _changeYear,
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('እ', style: TextStyle(fontWeight: FontWeight.bold)), // Sun
                Text('ሰ', style: TextStyle(fontWeight: FontWeight.bold)), // Mon
                Text('ማ', style: TextStyle(fontWeight: FontWeight.bold)), // Tue
                Text('ረ', style: TextStyle(fontWeight: FontWeight.bold)), // Wed
                Text('ሐ', style: TextStyle(fontWeight: FontWeight.bold)), // Thu
                Text('አ', style: TextStyle(fontWeight: FontWeight.bold)), // Fri
                Text('ቅ', style: TextStyle(fontWeight: FontWeight.bold)), // Sat
              ],
            ),
            const SizedBox(height: 10),
            _buildDaysGrid(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ይቅር')), // "Cancel"
                TextButton(onPressed: () => Navigator.of(context).pop(_selectedDate), child: const Text('እሺ')), // "OK"
              ],
            )
          ],
        ),
      ),
    );
  }
}

// A class to represent a date in the Ethiopian Calendar.
class EtDateTime {
  final int year;
  final int month;
  final int day;

  EtDateTime({required this.year, required this.month, this.day = 1});

  bool isBefore(EtDateTime other) {
    if (year < other.year) return true;
    if (year == other.year && month < other.month) return true;
    if (year == other.year && month == other.month && day < other.day) return true;
    return false;
  }

  bool isAfter(EtDateTime other) {
    if (year > other.year) return true;
    if (year == other.year && month > other.month) return true;
    if (year == other.year && month == other.month && day > other.day) return true;
    return false;
  }

  @override
  bool operator ==(Object other) =>
      other is EtDateTime && year == other.year && month == other.month && day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;
}


// Handles all the conversion logic between Gregorian and Ethiopian calendars.
class EthiopianCalendar {
  // JDN (Julian Day Number) constants for calendar epochs
  static const int _gregorianEpoch = 1721426;
  static const int _ethiopianEpoch = 1724221;

  static bool isLeapYear(int year) => (year % 4) == 3;

  static int getDaysInMonth(int year, int month) {
    if (month < 1 || month > 13) throw ArgumentError('Invalid month: $month');
    if (month == 13) return isLeapYear(year) ? 6 : 5;
    return 30;
  }

  static EtDateTime now() => fromGregorian(DateTime.now());

  static EtDateTime fromGregorian(DateTime gregDate) {
    // Convert UTC DateTime to JDN
    final gregDateUtc = DateTime.utc(gregDate.year, gregDate.month, gregDate.day);
    int jdn = gregDateUtc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay + 2440588 - _gregorianEpoch;

    // Convert JDN to Ethiopian Date using a standard algorithm
    int n = 4 * (jdn - _ethiopianEpoch) + 1463;
    int year = n ~/ 1461;
    int dayOfYear = (n % 1461) ~/ 4;
    
    int month = (dayOfYear ~/ 30) + 1;
    int day = (dayOfYear % 30) + 1;
    
    return EtDateTime(year: year, month: month, day: day);
  }
  
  static DateTime toGregorian(EtDateTime etDate) {
    // Convert Ethiopian Date to JDN
    int jdn = (_ethiopianEpoch - 1) +
              365 * (etDate.year - 1) +
              (etDate.year ~/ 4) +
              30 * (etDate.month - 1) +
              etDate.day;

    // Convert JDN to UTC Gregorian DateTime
    int milliseconds = (jdn - 2440588) * Duration.millisecondsPerDay;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }
}