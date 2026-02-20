import 'package:flutter/material.dart';

import '../../../core/utils/app_formatters.dart';
import '../model/challenge_model.dart';
import 'animated_progress_bar.dart';
import 'level_badge.dart';
import 'streak_indicator.dart';

/// Summary card shown on the Home screen for each challenge.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  final ChallengeModel challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = challenge.progressRatio;
    final percent = (progress * 100).toStringAsFixed(1);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            challenge.challengeType.displayName,
                            style: textTheme.labelSmall!.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  LevelBadge(level: challenge.level),
                ],
              ),

              const SizedBox(height: 16),

              // ── Progress bar ─────────────────────────────────────────────────
              AnimatedProgressBar(progress: progress, height: 10),

              const SizedBox(height: 8),

              // ── Amount & percentage ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppFormatters.formatCurrency(challenge.savedAmount)} saved',
                    style: textTheme.bodySmall!.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$percent% of ${AppFormatters.formatCurrency(challenge.targetAmount)}',
                    style: textTheme.bodySmall!.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Footer chips ─────────────────────────────────────────────────
              Row(
                children: [
                  StreakIndicator(streak: challenge.streak, compact: true),
                  const SizedBox(width: 8),
                  _XpChip(xp: challenge.xp),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XpChip extends StatelessWidget {
  const _XpChip({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 13, color: cs.onSecondaryContainer),
          const SizedBox(width: 2),
          Text(
            '$xp XP',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
