import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Utility functions for formatting values used throughout the app.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFmt = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'en_IN',
  );

  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDateFmt = DateFormat('dd MMM');

  /// Format a double as Indian-locale currency string (e.g. ₹1,200).
  static String formatCurrency(double amount) =>
      _currencyFmt.format(amount.toInt());

  /// Format a DateTime as e.g. "05 Jan 2025".
  static String formatDate(DateTime date) => _dateFmt.format(date);

  /// Format a DateTime as e.g. "05 Jan" (no year).
  static String formatShortDate(DateTime date) => _shortDateFmt.format(date);

  /// Compute XP from saved amount.
  static int calculateXP(double savedAmount) =>
      (savedAmount / AppConstants.xpPerUnit).floor();

  /// Compute level from XP.
  static int calculateLevel(int xp) => (xp / AppConstants.xpPerLevel).floor();

  /// Progress percentage clamped to [0, 1].
  static double progressRatio(double saved, double target) {
    if (target <= 0) return 0;
    return (saved / target).clamp(0.0, 1.0);
  }

  /// Days elapsed since [start].
  static int daysElapsed(DateTime start) =>
      DateTime.now().difference(start).inDays + 1;
}
