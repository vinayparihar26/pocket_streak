/// Type of savings challenge the user has chosen.
enum ChallengeType { thirtyDay, fiftyTwoWeek, custom }

/// Extension to get user-friendly display names for each [ChallengeType].
extension ChallengeTypeExt on ChallengeType {
  String get displayName {
    switch (this) {
      case ChallengeType.thirtyDay:
        return '30-Day Fixed';
      case ChallengeType.fiftyTwoWeek:
        return '52-Week Challenge';
      case ChallengeType.custom:
        return 'Custom';
    }
  }

  /// The raw string key used in JSON serialisation.
  String get key {
    switch (this) {
      case ChallengeType.thirtyDay:
        return 'thirtyDay';
      case ChallengeType.fiftyTwoWeek:
        return 'fiftyTwoWeek';
      case ChallengeType.custom:
        return 'custom';
    }
  }
}

/// A single savings challenge created by the user.
class ChallengeModel {
  ChallengeModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.challengeType,
    required this.startDate,
    required this.streak,
    required this.xp,
    required this.savingsLog,
    this.lastSavedDate,
  });

  /// Unique identifier (UUID v4).
  final String id;

  /// User-given name for the challenge.
  final String title;

  /// Total savings goal in local currency.
  final double targetAmount;

  /// Amount saved so far.
  double savedAmount;

  /// The flavour of challenge.
  final ChallengeType challengeType;

  /// Date the challenge was created / started.
  final DateTime startDate;

  /// Number of consecutive days the user has saved.
  int streak;

  /// Total XP accumulated = savedAmount / 10.
  int xp;

  /// Log of (date → amount) entries to render charts.
  /// Key: ISO-8601 date string ("2025-01-04"), Value: amount saved that day.
  final Map<String, double> savingsLog;

  /// The last date on which the user made a deposit (for streak calculation).
  DateTime? lastSavedDate;

  // ─── Derived ────────────────────────────────────────────────────────────────

  /// Current level derived from XP.
  int get level => (xp / 100).floor();

  /// Progress as a ratio in [0, 1].
  double get progressRatio =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;

  // ─── Serialisation ──────────────────────────────────────────────────────────

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num).toDouble(),
      challengeType: _typeFromKey(json['challengeType'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      streak: json['streak'] as int,
      xp: json['xp'] as int,
      savingsLog: (json['savingsLog'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      lastSavedDate: json['lastSavedDate'] != null
          ? DateTime.parse(json['lastSavedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'challengeType': challengeType.key,
    'startDate': startDate.toIso8601String(),
    'streak': streak,
    'xp': xp,
    'savingsLog': savingsLog,
    'lastSavedDate': lastSavedDate?.toIso8601String(),
  };

  /// Create a copy with some fields overridden.
  ChallengeModel copyWith({
    double? savedAmount,
    int? streak,
    int? xp,
    Map<String, double>? savingsLog,
    DateTime? lastSavedDate,
  }) {
    return ChallengeModel(
      id: id,
      title: title,
      targetAmount: targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      challengeType: challengeType,
      startDate: startDate,
      streak: streak ?? this.streak,
      xp: xp ?? this.xp,
      savingsLog: savingsLog ?? this.savingsLog,
      lastSavedDate: lastSavedDate ?? this.lastSavedDate,
    );
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static ChallengeType _typeFromKey(String key) {
    switch (key) {
      case 'thirtyDay':
        return ChallengeType.thirtyDay;
      case 'fiftyTwoWeek':
        return ChallengeType.fiftyTwoWeek;
      case 'custom':
      default:
        return ChallengeType.custom;
    }
  }
}
