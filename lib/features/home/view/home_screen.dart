import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../challenge/model/challenge_model.dart';
import '../../challenge/provider/challenge_provider.dart';
import '../../challenge/widgets/challenge_card.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile/widgets/profile_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChallengeProvider, ProfileProvider>(
      builder: (ctx, challengeP, profileP, _) {
        final challenges = challengeP.challenges;
        final profile = profileP.profile;

        // ── aggregate stats ───────────────────────────────────────────────────
        final totalSaved = challenges.fold<double>(
          0,
          (s, c) => s + c.savedAmount,
        );
        final totalXP = challenges.fold<int>(0, (s, c) => s + c.xp);
        final bestStreak =
            challenges.fold<int>(0, (a, c) => a > c.streak ? a : c.streak);

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Dashboard header ───────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: Theme.of(ctx).colorScheme.primary,
                leading: const SizedBox.shrink(),
                actions: const [SizedBox.shrink()],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.blurBackground],
                  background: _DashboardHeader(
                    profile: profile,
                    totalSaved: totalSaved,
                    totalXP: totalXP,
                    bestStreak: bestStreak,
                    challengeCount: challenges.length,
                    onProfileTap: () =>
                        Navigator.of(ctx).pushNamed(AppConstants.profileRoute),
                  ),
                ),
              ),

              // ── Section header ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                  count: challenges.length,
                  onAdd: () =>
                      Navigator.of(ctx).pushNamed(AppConstants.createRoute),
                ),
              ),

              // ── Challenge list or empty state ──────────────────────────────
              if (challengeP.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (challenges.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                    onTap: () =>
                        Navigator.of(ctx).pushNamed(AppConstants.createRoute),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => _AnimatedCard(
                        index: index,
                        challenge: challenges[index],
                        onTap: () => Navigator.of(ctx).pushNamed(
                          AppConstants.detailRoute,
                          arguments: challenges[index].id,
                        ),
                        onDismiss: () => ctx
                            .read<ChallengeProvider>()
                            .deleteChallenge(challenges[index].id),
                      ),
                      childCount: challenges.length,
                    ),
                  ),
                ),
            ],
          ),

          // ── FAB ────────────────────────────────────────────────────────────
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'home_fab',
            onPressed: () =>
                Navigator.of(ctx).pushNamed(AppConstants.createRoute),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Challenge'),
          ),
        );
      },
    );
  }
}

// ── Dashboard Header ──────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.profile,
    required this.totalSaved,
    required this.totalXP,
    required this.bestStreak,
    required this.challengeCount,
    required this.onProfileTap,
  });

  final dynamic profile;
  final double totalSaved;
  final int totalXP;
  final int bestStreak;
  final int challengeCount;
  final VoidCallback onProfileTap;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final profileP = context.watch<ProfileProvider>();
    final displayName = profileP.profile.name;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4527A0), // deep purple
            const Color(0xFF7B1FA2), // rich violet
            const Color(0xFFAD1457), // dark pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // ── Decorative circles ─────────────────────────────────────────────
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: greeting + avatar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_greeting${displayName.isNotEmpty ? ',' : '!'} 👋',
                              style: textTheme.bodySmall!.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              displayName.isNotEmpty ? displayName : 'Saver',
                              style: textTheme.titleLarge!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ProfileAvatar(
                        profile: profileP.profile,
                        radius: 26,
                        onTap: onProfileTap,
                        heroTag: 'profile_avatar',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Total Saved counter ────────────────────────────────────
                  Text(
                    'Total Saved',
                    style: textTheme.labelMedium!.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(totalSaved),
                    tween: Tween(begin: 0, end: totalSaved),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => Text(
                      AppFormatters.formatCurrency(val),
                      style: textTheme.displaySmall!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Stats pills ────────────────────────────────────────────
                  Row(
                    children: [
                      _StatPill(
                        icon: '🎯',
                        label:
                            '$challengeCount Challenge${challengeCount == 1 ? '' : 's'}',
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        icon: '⚡',
                        label: '$totalXP XP',
                        color: appColors.levelColor.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        icon: '🔥',
                        label: '$bestStreak day${bestStreak == 1 ? '' : 's'}',
                        color: appColors.streakColor.withValues(alpha: 0.25),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count, required this.onAdd});
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Text(
            'Active Challenges',
            style: textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ── Animated Card (staggered entrance) ───────────────────────────────────────

class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({
    required this.index,
    required this.challenge,
    required this.onTap,
    required this.onDismiss,
  });

  final int index;
  final ChallengeModel challenge;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 450 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (_, progress, child) => Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - progress)),
          child: child,
        ),
      ),
      child: Dismissible(
        key: ValueKey(challenge.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Icon(
            Icons.delete_sweep_rounded,
            color: cs.onErrorContainer,
            size: 30,
          ),
        ),
        confirmDismiss: (_) async {
          return await _confirmDelete(context);
        },
        onDismissed: (_) => onDismiss(),
        child: ChallengeCard(
          challenge: challenge,
          onTap: onTap,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Challenge?'),
            content: Text(
              'Remove "${challenge.title}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  const _EmptyState({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        cs.primaryContainer,
                        cs.secondaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.savings_rounded,
                    size: 54,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No challenges yet!',
                style: textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Start your first savings challenge\nand watch your streak grow 🔥',
                style: textTheme.bodyMedium!.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: widget.onTap,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Start First Challenge'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
