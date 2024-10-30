import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_clean_calendar/utils/extensions.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CleanCalendarController extends ChangeNotifier {
  /// Obrigatory: The mininimum date to show
  final DateTime minDate;

  /// Obrigatory: The maximum date to show
  final DateTime maxDate;

  /// Whether to hide entire weeks if any days in them
  /// fall before the [minDate].
  final bool hideWeeksOutOfMinDate;

  /// Whether to hide entire weeks if any days in them
  /// fall after the [maxDate].
  final bool hideWeeksOutOfMaxDate;

  /// If the range is enabled
  final bool rangeMode;

  /// If the calendar is readOnly
  final bool readOnly;

  /// In what weekday position the calendar is going to start
  final int weekdayStart;

  /// Function when a day is tapped
  final Function(DateTime date)? onDayTapped;

  /// Function when a range is selected
  final Function(DateTime minDate, DateTime? maxDate)? onRangeSelected;

  /// When a date before the min date is tapped
  final Function(DateTime date)? onPreviousMinDateTapped;

  /// When a date after max date is tapped
  final Function(DateTime date)? onAfterMaxDateTapped;

  /// An initial selected date
  final DateTime? initialDateSelected;

  /// The end of selected range
  final DateTime? endDateSelected;

  /// An initial fucus date
  final DateTime? initialFocusDate;

  late int weekdayEnd;
  List<DateTime> months = [];

  /// The item scroll controller
  final ItemScrollController itemScrollController = ItemScrollController();

  CleanCalendarController({
    required this.minDate,
    required this.maxDate,
    this.rangeMode = true,
    this.readOnly = false,
    this.endDateSelected,
    this.initialDateSelected,
    this.onDayTapped,
    this.onRangeSelected,
    this.onAfterMaxDateTapped,
    this.onPreviousMinDateTapped,
    this.weekdayStart = DateTime.monday,
    this.initialFocusDate,
    this.hideWeeksOutOfMinDate = false,
    this.hideWeeksOutOfMaxDate = false,
  })  : assert(weekdayStart <= DateTime.sunday),
        assert(weekdayStart >= DateTime.monday) {
    final x = weekdayStart - 1;
    weekdayEnd = x == 0 ? 7 : x;

    DateTime currentDate = DateTime(minDate.year, minDate.month);
    months.add(currentDate);

    while (!(currentDate.year == maxDate.year &&
        currentDate.month == maxDate.month)) {
      currentDate = DateTime(currentDate.year, currentDate.month + 1);
      months.add(currentDate);
    }

    if (initialDateSelected != null &&
        (initialDateSelected!.isAfter(minDate) ||
            initialDateSelected!.isSameDay(minDate))) {
      onDayClick(initialDateSelected!, update: false);
    }

    if (endDateSelected != null &&
        (endDateSelected!.isBefore(maxDate) ||
            endDateSelected!.isSameDay(maxDate))) {
      onDayClick(endDateSelected!, update: false);
    }
  }

  DateTime? rangeMinDate;
  DateTime? rangeMaxDate;

  List<String> getDaysOfWeek([String locale = 'pt']) {
    var today = DateTime.now();

    while (today.weekday != weekdayStart) {
      today = today.subtract(const Duration(days: 1));
    }
    final dateFormat = DateFormat(DateFormat.ABBR_WEEKDAY, locale);
    final daysOfWeek = [
      dateFormat.format(today),
      dateFormat.format(today.add(const Duration(days: 1))),
      dateFormat.format(today.add(const Duration(days: 2))),
      dateFormat.format(today.add(const Duration(days: 3))),
      dateFormat.format(today.add(const Duration(days: 4))),
      dateFormat.format(today.add(const Duration(days: 5))),
      dateFormat.format(today.add(const Duration(days: 6)))
    ];

    return daysOfWeek;
  }

  void onDayClick(DateTime date, {bool update = true}) {
    if (rangeMode) {
      if (rangeMinDate == null || rangeMaxDate != null) {
        rangeMinDate = date;
        rangeMaxDate = null;
      } else if (date.isBefore(rangeMinDate!)) {
        rangeMaxDate = rangeMinDate;
        rangeMinDate = date;
      } else if (date.isAfter(rangeMinDate!) || date.isSameDay(rangeMinDate!)) {
        rangeMaxDate = date;
      }
    } else {
      rangeMinDate = date;
      rangeMaxDate = date;
    }

    if (update) {
      notifyListeners();

      if (onDayTapped != null) {
        onDayTapped!(date);
      }

      if (onRangeSelected != null) {
        onRangeSelected!(rangeMinDate!, rangeMaxDate);
      }
    }
  }

  void clearSelectedDates() {
    rangeMaxDate = null;
    rangeMinDate = null;

    notifyListeners();
  }

  /// Scroll to [date.month].
  ///
  /// Animate the list over [duration] using the given [curve] such that the
  /// item at [index] ends up with its leading edge at the given [alignment].
  /// See [jumpTo] for an explanation of alignment.
  ///
  /// The [duration] must be greater than 0; otherwise, use [jumpTo].
  ///
  /// When item position is not available, because it's too far, the scroll
  /// is composed into three phases:
  ///
  ///  1. The currently displayed list view starts scrolling.
  ///  2. Another list view, which scrolls with the same speed, fades over the
  ///     first one and shows items that are close to the scroll target.
  ///  3. The second list view scrolls and stops on the target.
  ///
  /// The [opacityAnimationWeights] can be used to apply custom weights to these
  /// three stages of this animation. The default weights, `[40, 20, 40]`, are
  /// good with default [Curves.linear].  Different weights might be better for
  /// other cases.  For example, if you use [Curves.easeOut], consider setting
  /// [opacityAnimationWeights] to `[20, 20, 60]`.
  Future<void> scrollToMonth({
    required DateTime date,
    double alignment = 0,
    required Duration duration,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const [40, 20, 40],
  }) async {
    if (!(date.year >= minDate.year &&
        (date.year > minDate.year || date.month >= minDate.month) &&
        date.year <= maxDate.year &&
        (date.year < maxDate.year || date.month <= maxDate.month))) {
      return;
    }
    final month =
        ((date.year - minDate.year) * 12) - minDate.month + date.month;
    await itemScrollController.scrollTo(
        index: month,
        alignment: alignment,
        duration: duration,
        curve: curve,
        opacityAnimationWeights: opacityAnimationWeights);
  }

  /// Jump to [date.month].
  ///
  /// Immediately, without animation, reconfigure the list so that the item at
  /// [index]'s leading edge is at the given [alignment].
  ///
  /// The [alignment] specifies the desired position for the leading edge of the
  /// item.  The [alignment] is expected to be a value in the range \[0.0, 1.0\]
  /// and represents a proportion along the main axis of the viewport.
  ///
  /// For a vertically scrolling view that is not reversed:
  /// * 0 aligns the top edge of the item with the top edge of the view.
  /// * 1 aligns the top edge of the item with the bottom of the view.
  /// * 0.5 aligns the top edge of the item with the center of the view.
  ///
  /// For a horizontally scrolling view that is not reversed:
  /// * 0 aligns the left edge of the item with the left edge of the view
  /// * 1 aligns the left edge of the item with the right edge of the view.
  /// * 0.5 aligns the left edge of the item with the center of the view.
  void jumpToMonth({required DateTime date, double alignment = 0}) {
    if (!(date.year >= minDate.year &&
        (date.year > minDate.year || date.month >= minDate.month) &&
        date.year <= maxDate.year &&
        (date.year < maxDate.year || date.month <= maxDate.month))) {
      return;
    }
    final month =
        ((date.year - minDate.year) * 12) - minDate.month + date.month;
    itemScrollController.jumpTo(index: month, alignment: alignment);
  }
}
