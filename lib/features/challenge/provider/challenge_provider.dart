import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/hive/hive_service.dart';
import '../model/challenge_model.dart';

/// Manages all challenge state, persists to Hive.
class ChallengeProvider extends ChangeNotifier {
  ChallengeProvider() {
    _load();
  }

  List<ChallengeModel> _challenges = [];
  bool _isLoading = true;

  List<ChallengeModel> get challenges => List.unmodifiable(_challenges);
  bool get isLoading => _isLoading;

  ChallengeModel? getById(String id) {
    try {
      return _challenges.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  Future<void> addChallenge({
    required String title,
    required double targetAmount,
    required ChallengeType challengeType,
  }) async {
    final challenge = ChallengeModel(
      id: const Uuid().v4(),
      title: title,
      targetAmount: targetAmount,
      savedAmount: 0,
      challengeType: challengeType,
      startDate: DateTime.now(),
      streak: 0,
      xp: 0,
      savingsLog: {},
    );
    _challenges.add(challenge);
    notifyListeners();
    await _save();
  }

  Future<void> updateProgress(String id, double amount) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1) return;

    final old = _challenges[idx];
    final today = _todayKey();
    final newSaved = (old.savedAmount + amount).clamp(0, old.targetAmount);

    // Update savings log
    final log = Map<String, double>.from(old.savingsLog);
    log[today] = (log[today] ?? 0) + amount;

    // XP
    final newXp = old.xp + _calcXp(amount);

    // Streak
    final newStreak = _calcStreak(old, today);

    _challenges[idx] = old.copyWith(
      savedAmount: newSaved.toDouble(),
      xp: newXp,
      streak: newStreak,
      savingsLog: log,
    );
    notifyListeners();
    await _save();
  }

  Future<void> deleteChallenge(String id) async {
    _challenges.removeWhere((c) => c.id == id);
    notifyListeners();
    await _save();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .toIso8601String()
        .split('T')
        .first;
  }

  int _calcXp(double amount) =>
      (amount / AppConstants.xpPerUnit).floor().clamp(1, 9999);

  int _calcStreak(ChallengeModel old, String todayKey) {
    if (old.savingsLog.containsKey(todayKey)) {
      return old.streak; // already counted today
    }

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayKey =
        DateTime(yesterday.year, yesterday.month, yesterday.day)
            .toIso8601String()
            .split('T')
            .first;

    // If yesterday had a deposit, extend streak; else reset to 1
    return old.savingsLog.containsKey(yesterdayKey) ? old.streak + 1 : 1;
  }

  // ── Persistence ──────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final raw = HiveService.challenges.get('data');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _challenges = list
            .map((e) => ChallengeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      _challenges = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final json = jsonEncode(_challenges.map((c) => c.toJson()).toList());
    await HiveService.challenges.put('data', json);
  }
}
