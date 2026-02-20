import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../model/challenge_model.dart';
import '../provider/challenge_provider.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/level_badge.dart';

/// Detail view for a single challenge: shows stats, progress, and lets the
/// user record new deposits.
class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as String;

    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        final challenge = provider.getById(id);

        if (challenge == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Challenge')),
            body: const Center(child: Text('Challenge not found.')),
          );
        }

        return _DetailView(challenge: challenge);
      },
    );
  }
}

// ── Detail View ──────────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  const _DetailView({required this.challenge});

  final ChallengeModel challenge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final progress = challenge.progressRatio;

    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.title),
        actions: [
          IconButton(
            tooltip: 'Analytics',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(AppConstants.analyticsRoute, arguments: challenge.id),
          ),
          IconButton(
            tooltip: 'Delete Challenge',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress hero card ────────────────────────────────────────────
            _HeroCard(
              challenge: challenge,
              progress: progress,
              cs: cs,
              textTheme: textTheme,
              appColors: appColors,
            ),

            const SizedBox(height: 16),

            // ── Stats row ─────────────────────────────────────────────────────
            _StatsRow(challenge: challenge, appColors: appColors),

            const SizedBox(height: 16),

            // ── Savings log ───────────────────────────────────────────────────
            _SavingsLogCard(challenge: challenge, cs: cs, textTheme: textTheme),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ── Add Savings FAB ───────────────────────────────────────────────────
      floatingActionButton: challenge.progressRatio < 1.0
          ? FloatingActionButton.extended(
              heroTag: 'add_savings_fab',
              onPressed: () => _showAddSavingsDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Savings'),
            )
          : null,
    );
  }

  // ── Add Savings Dialog ────────────────────────────────────────────────────

  void _showAddSavingsDialog(BuildContext context) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Savings'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter amount';
                final p = double.tryParse(val.trim());
                if (p == null || p <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amount = double.parse(amountController.text.trim());
                // ignore: use_build_context_synchronously
                await context.read<ChallengeProvider>().updateProgress(
                      challenge.id,
                      amount,
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${AppFormatters.formatCurrency(amount)} added! 🎉',
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Challenge?'),
        content: const Text(
          'This will permanently remove the challenge and all its data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<ChallengeProvider>().deleteChallenge(
                    challenge.id,
                  );
              if (context.mounted) {
                Navigator.of(context).pop(); // back to Home
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.challenge,
    required this.progress,
    required this.cs,
    required this.textTheme,
    required this.appColors,
  });

  final ChallengeModel challenge;
  final double progress;
  final ColorScheme cs;
  final TextTheme textTheme;
  final AppColors appColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(challenge.savedAmount),
                      style: textTheme.headlineMedium!.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'of ${AppFormatters.formatCurrency(challenge.targetAmount)} goal',
                      style: textTheme.bodyMedium!.copyWith(
                        color: cs.onPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              LevelBadge(level: challenge.level, size: 56),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedProgressBar(
            progress: progress,
            height: 14,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            foregroundColor: cs.onPrimary,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}% complete',
                style: textTheme.labelMedium!.copyWith(
                  color: cs.onPrimary.withValues(alpha: 0.85),
                ),
              ),
              Text(
                challenge.challengeType.displayName,
                style: textTheme.labelMedium!.copyWith(
                  color: cs.onPrimary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.challenge, required this.appColors});

  final ChallengeModel challenge;
  final AppColors appColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '🔥',
            label: 'Streak',
            value: '${challenge.streak} day${challenge.streak == 1 ? '' : 's'}',
            color: appColors.streakColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: '⚡',
            label: 'XP',
            value: '${challenge.xp} XP',
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: '📅',
            label: 'Days',
            value: '${AppFormatters.daysElapsed(challenge.startDate)}',
            color: appColors.successColor,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 0.8),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Savings Log Card ─────────────────────────────────────────────────────────

class _SavingsLogCard extends StatelessWidget {
  const _SavingsLogCard({
    required this.challenge,
    required this.cs,
    required this.textTheme,
  });

  final ChallengeModel challenge;
  final ColorScheme cs;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final log = challenge.savingsLog;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Savings History',
                  style: textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (log.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppConstants.analyticsRoute,
                      arguments: challenge.id,
                    ),
                    icon: const Icon(Icons.bar_chart_rounded, size: 16),
                    label: const Text('View Chart'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (log.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No deposits yet.\nTap "Add Savings" to start!',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall!.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ),
              )
            else
              ...log.entries
                  .toList()
                  .reversed
                  .take(7)
                  .map((e) => _LogRow(dateKey: e.key, amount: e.value)),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.dateKey, required this.amount});

  final String dateKey;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = DateTime.tryParse(dateKey) ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppFormatters.formatDate(date),
                style: textTheme.bodySmall!.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            '+ ${AppFormatters.formatCurrency(amount)}',
            style: textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
