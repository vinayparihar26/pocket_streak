import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Centralises Hive initialisation and typed box access.
class HiveService {
  HiveService._();

  /// Call this once in [main] before [runApp].
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(AppConstants.hiveBoxChallenges);
    await Hive.openBox<String>(AppConstants.hiveBoxProfile);
  }

  /// Box that stores the JSON-encoded challenge list.
  static Box<String> get challenges =>
      Hive.box<String>(AppConstants.hiveBoxChallenges);

  /// Box that stores profile fields as individual key-value pairs.
  static Box<String> get profile =>
      Hive.box<String>(AppConstants.hiveBoxProfile);
}
