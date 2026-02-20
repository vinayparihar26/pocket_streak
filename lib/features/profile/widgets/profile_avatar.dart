import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../model/user_profile.dart';

/// Reusable circular avatar that displays a profile photo (base64) or
/// a fallback initials/icon placeholder. Wrapped in a Hero for smooth
/// screen transitions.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    this.radius = 24,
    this.onTap,
    this.showEditBadge = false,
    this.heroTag = 'profile_avatar',
  });

  final UserProfile profile;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget avatar;
    if (profile.avatarBase64 != null && profile.avatarBase64!.isNotEmpty) {
      // Show decoded photo
      final Uint8List bytes = base64Decode(profile.avatarBase64!);
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
        backgroundColor: cs.primaryContainer,
      );
    } else {
      // Fallback: initials or default icon
      final initials = _initials(profile.name);
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: cs.primaryContainer,
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: radius * 0.55,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer,
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: radius * 1.0,
                color: cs.onPrimaryContainer,
              ),
      );
    }

    final heroChild = showEditBadge
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: radius * 0.45,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ],
          )
        : avatar;

    return Hero(
      tag: heroTag,
      child: GestureDetector(
        onTap: onTap,
        child: heroChild,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
