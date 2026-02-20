import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/hive/hive_service.dart';
import '../model/user_profile.dart';

/// Manages the user's profile state and Hive persistence.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider() {
    _load();
  }

  UserProfile _profile = UserProfile.empty();
  UserProfile get profile => _profile;

  bool get hasName => _profile.name.isNotEmpty;

  // ── Load ─────────────────────────────────────────────────────────────────────

  void _load() {
    final box = HiveService.profile;
    final map = <String, String>{};
    for (final key in box.keys) {
      final val = box.get(key as String);
      if (val != null) map[key] = val;
    }
    _profile = UserProfile.fromMap(map);
    notifyListeners();
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  Future<void> saveProfile(UserProfile updated) async {
    _profile = updated;
    notifyListeners();
    final box = HiveService.profile;
    await box.clear();
    await box.putAll(updated.toMap());
  }

  // ── Image picker ─────────────────────────────────────────────────────────────

  /// Picks an image from gallery and returns raw bytes (null if cancelled).
  Future<Uint8List?> pickAvatarImage() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (xFile == null) return null;
      return await xFile.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Saves avatar bytes to Hive and updates the profile.
  Future<void> saveAvatar(Uint8List bytes) async {
    final b64 = base64Encode(bytes);
    final updated = _profile.copyWith(avatarBase64: b64);
    await saveProfile(updated);
  }
}
