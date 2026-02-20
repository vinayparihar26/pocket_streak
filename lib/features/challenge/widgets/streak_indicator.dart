import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Displays a 🔥 flame icon paired with the streak count.
class StreakIndicator extends StatelessWidget {
  const StreakIndicator({
    super.key,
    required this.streak,
    this.compact = false,
  });

  final int streak;

  /// If [compact] is true, renders a smaller inline version for cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: appColors.streakColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.streakColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '🔥',
          style: TextStyle(fontSize: streak > 0 ? 36 : 28),
        ),
        const SizedBox(height: 4),
        Text(
          '$streak day${streak == 1 ? '' : 's'}',
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
            color: appColors.streakColor,
          ),
        ),
        Text(
          'streak',
          style: textTheme.bodySmall!.copyWith(
            color: appColors.streakColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
