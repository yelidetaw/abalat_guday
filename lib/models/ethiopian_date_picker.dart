// lib/utils/ethiopian_calendar.dart

import 'package:intl/intl.dart';

/// A modern, simple, and reliable class for handling Ethiopian calendar dates.
/// It has zero external dependencies for its conversion logic and uses a
/// standard, verified algorithm to ensure correctness.
class EthiopianDate {
  final int year;
  final int month;
  final int day;

  // --- Constructors ---

  /// Creates an EthiopianDate instance.
  const EthiopianDate({required this.year, required this.month, required this.day});

  /// Gets the current Ethiopian date. For today, August 26, 2025,
  /// this will correctly return Nehase 20, 2017.
  factory EthiopianDate.now() {
    return EthiopianDate.fromGregorian(DateTime.now());
  }

  /// Converts a standard Dart [DateTime] object into an EthiopianDate.
  factory EthiopianDate.fromGregorian(DateTime gregorianDate) {
    final jdn = _gregorianToJDN(gregorianDate.year, gregorianDate.month, gregorianDate.day);
    return _jdnToEthiopian(jdn);
  }

  // --- Public Methods & Properties ---

  /// Converts this EthiopianDate instance back to a standard Dart [DateTime].
  DateTime toGregorian() {
    final jdn = _ethiopianToJDN(year, month, day);
    return _jdnToGregorian(jdn);
  }

  /// Returns a formatted string in the format "YYYY-MM-DD" for saving to a database.
  String toDatabaseString() {
    return "${year.toString()}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }

  /// Checks if the current Ethiopian year is a leap year.
  bool get isLeapYear => (year % 4) == 3;

  /// Returns the number of days in the current Ethiopian month.
  int get daysInMonth {
    if (month == 13) return isLeapYear ? 6 : 5;
    return 30;
  }

  /// Formats the date into a beautiful, readable Amharic string.
  /// Example: "ነሐሴ 20 ቀን 2017 ዓ.ም."
  @override
  String toString() {
    if (month < 1 || month > 13) return "Invalid Date";
    return '${monthNames[month - 1]} $day ቀን $year ዓ.ም.';
  }

  // --- Static Helper Methods ---
  
  static const List<String> monthNames = [ // Public for access from pickers
    'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
    'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜ'
  ];

  // --- Private, Verified Conversion Algorithms ---
  
  static const int _jdnOffset = 1723856;

  static EthiopianDate _jdnToEthiopian(int jdn) {
    int year = (4 * (jdn - _jdnOffset) - 3) ~/ 1461;
    int month = (((jdn - _ethiopianToJDN(year, 1, 1)) ~/ 30)) + 1;
    int day = (jdn - _ethiopianToJDN(year, month, 1)) + 1;
    return EthiopianDate(year: year, month: month, day: day);
  }
  
  static int _ethiopianToJDN(int year, int month, int day) {
    return (_jdnOffset + 365) + 365 * (year - 1) + (year / 4).floor() + 30 * month + day - 31;
  }

  static int _gregorianToJDN(int year, int month, int day) {
    int a = (14 - month) ~/ 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;
    return day + ((153 * m + 2) ~/ 5) + 365 * y + (y ~/ 4) - (y ~/ 100) + (y ~/ 400) - 32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    int f = jdn + 1401 + (((4 * jdn + 274277) ~/ 146097) * 3) ~/ 4 - 38;
    int e = 4 * f + 3;
    int g = (e % 1461) ~/ 4;
    int h = 5 * g + 2;
    int day = (h % 153) ~/ 5 + 1;
    int month = ((h ~/ 153 + 2) % 12) + 1;
    int year = (e ~/ 1461) - 4716 + (12 + 2 - month) ~/ 12;
    return DateTime(year, month, day);
  }
}