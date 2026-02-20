import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_formatters.dart';
import '../model/user_profile.dart';
import '../provider/profile_provider.dart';
import '../widgets/profile_avatar.dart';

/// Full-page profile editor with avatar upload, name, bio, and monthly goal.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _goalCtrl;

  Uint8List? _pendingAvatar; // freshly picked bytes (not yet saved)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    final profile = context.read<ProfileProvider>().profile;
    _nameCtrl = TextEditingController(text: profile.name);
    _bioCtrl = TextEditingController(text: profile.bio);
    _goalCtrl = TextEditingController(
      text:
          profile.monthlyGoal > 0 ? profile.monthlyGoal.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final provider = context.read<ProfileProvider>();
    final bytes = await provider.pickAvatarImage();
    if (bytes != null && mounted) {
      setState(() => _pendingAvatar = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<ProfileProvider>();

    // Save image first if newly picked
    if (_pendingAvatar != null) {
      await provider.saveAvatar(_pendingAvatar!);
    }

    final currentB64 = _pendingAvatar != null
        ? provider.profile.avatarBase64
        : provider.profile.avatarBase64;

    await provider.saveProfile(
      UserProfile(
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        monthlyGoal: double.tryParse(_goalCtrl.text.trim()) ?? 5000,
        avatarBase64: currentB64,
      ),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile saved! ✅'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = context.watch<ProfileProvider>().profile;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: cs.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.onPrimary.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.onPrimary.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Avatar + title
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            ProfileAvatar(
                              profile: _pendingAvatar != null
                                  ? profile.copyWith(
                                      avatarBase64: null,
                                    )
                                  : profile,
                              radius: 44,
                              onTap: _pickAvatar,
                              showEditBadge: true,
                              heroTag: 'profile_avatar_edit',
                            ),
                            if (_pendingAvatar != null) ...[
                              const SizedBox(height: 4),
                              _PendingAvatarPreview(bytes: _pendingAvatar!),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              profile.name.isNotEmpty
                                  ? profile.name
                                  : 'Your Profile',
                              style: textTheme.titleLarge!.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Tap the avatar to change photo',
                              style: textTheme.bodySmall!.copyWith(
                                color: cs.onPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ─────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name ────────────────────────────────────────────────
                      _SectionLabel('About You'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'e.g. Rahul Sharma',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // ── Bio ─────────────────────────────────────────────────
                      TextFormField(
                        controller: _bioCtrl,
                        maxLines: 2,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Tagline / Bio',
                          hintText: 'e.g. Saving for my dream trip ✈️',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Savings goal ────────────────────────────────────────
                      _SectionLabel('Savings Goal'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _goalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Goal (₹)',
                          hintText: 'e.g. 5000',
                          prefixIcon: Icon(Icons.savings_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final d = double.tryParse(v.trim());
                          if (d == null || d <= 0) {
                            return 'Enter a valid positive amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── Save Button ─────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(
                            _isSaving ? 'Saving…' : 'Save Profile',
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Stats summary ───────────────────────────────────────
                      _ProfileStatsCard(
                        monthlyGoal: double.tryParse(_goalCtrl.text) ?? 0,
                        cs: cs,
                        textTheme: textTheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.8,
          ),
    );
  }
}

/// Displays a live preview of the newly picked avatar bytes.
class _PendingAvatarPreview extends StatelessWidget {
  const _PendingAvatarPreview({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.memory(
              bytes,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'New photo selected',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatsCard extends StatelessWidget {
  const _ProfileStatsCard({
    required this.monthlyGoal,
    required this.cs,
    required this.textTheme,
  });

  final double monthlyGoal;
  final ColorScheme cs;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    if (monthlyGoal <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_circle_rounded, color: cs.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Target', style: textTheme.labelSmall),
              Text(
                AppFormatters.formatCurrency(monthlyGoal),
                style: textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
