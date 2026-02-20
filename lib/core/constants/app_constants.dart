/// App-wide constants for SaveStreak.
class AppConstants {
  AppConstants._();

  // ── Hive Box names ───────────────────────────────────────────────────────────
  static const String hiveBoxChallenges = 'challenges_box';
  static const String hiveBoxProfile = 'profile_box';

  // ── XP system ────────────────────────────────────────────────────────────────
  static const int xpPerUnit = 10; // 1 XP per ₹10 saved
  static const int xpPerLevel = 100; // level up every 100 XP

  // ── Challenge type display names ─────────────────────────────────────────────
  static const Map<String, String> challengeTypeNames = {
    'thirtyDay': '30-Day Fixed',
    'fiftyTwoWeek': '52-Week Challenge',
    'custom': 'Custom',
  };

  // ── 52-week total ────────────────────────────────────────────────────────────
  static const double fiftyTwoWeekTotal = 1378.0;
  static const double thirtyDayDefault = 30.0;

  // ── Route names ──────────────────────────────────────────────────────────────
  static const String splashRoute = '/';
  static const String homeRoute = '/home';
  static const String createRoute = '/create';
  static const String detailRoute = '/detail';
  static const String analyticsRoute = '/analytics';
  static const String profileRoute = '/profile';
}
