import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Circular badge showing the user's current level (⭐ Lv. N).
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.size = 48.0,
  });

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            appColors.levelColor.withValues(alpha: 0.9),
            appColors.levelColor.withValues(alpha: 0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: appColors.levelColor.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '⭐',
            style: TextStyle(fontSize: size * 0.28),
          ),
          Text(
            'Lv.$level',
            style: textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: size * 0.22,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
