extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension DateUtilsExtensions on DateTime {
  bool get isLeapYear {
    bool leapYear = false;

    bool leap = ((year % 100 == 0) && (year % 400 != 0));
    if (leap == true) {
      return false;
    } else if (year % 4 == 0) {
      return true;
    }

    return leapYear;
  }

  DateTime toFirstDayOfNextMonth() => DateTime(
        year,
        month + 1,
      );

  DateTime get nextDay => DateTime(year, month, day + 1);

  bool isSameDayOrAfter(DateTime other) => isAfter(other) || isSameDay(other);

  bool isSameDayOrBefore(DateTime other) => isBefore(other) || isSameDay(other);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  DateTime removeTime() => DateTime(year, month, day);

  DateTime firstDayOfMonth() => DateTime(year, month, 1);

  DateTime lastDayOfMonth() => DateTime(year, month + 1, 0);

  /// Returns the first day of the week based on the provided [weekdayStart].
  DateTime firstDayOfWeek(int weekdayStart) {
    int daysToSubtract = (weekday - weekdayStart) % 7;
    return subtract(Duration(days: daysToSubtract));
  }

  /// Returns the last day of the week based on the provided [weekdayEnd].
  DateTime lastDayOfWeek(int weekdayEnd) {
    int daysToAdd = (weekdayEnd - weekday) % 7;
    return add(Duration(days: daysToAdd));
  }
}
