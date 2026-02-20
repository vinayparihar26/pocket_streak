import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/challenge_model.dart';
import '../provider/challenge_provider.dart';

/// Screen to create a new savings challenge.
class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  ChallengeType _selectedType = ChallengeType.thirtyDay;
  bool _isSaving = false;

  // ── Type-specific suggested amounts ──────────────────────────────────────────
  static const Map<ChallengeType, double> _suggestions = {
    ChallengeType.thirtyDay: 3000,
    ChallengeType.fiftyTwoWeek: 1378,
    ChallengeType.custom: 5000,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onTypeChanged(ChallengeType type) {
    setState(() {
      _selectedType = type;
      // Pre-fill suggested amount
      _amountController.text = _suggestions[type]!.toStringAsFixed(0);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<ChallengeProvider>();
    await provider.addChallenge(
      title: _titleController.text.trim(),
      targetAmount: double.parse(_amountController.text.trim()),
      challengeType: _selectedType,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    _amountController.text = _suggestions[_selectedType]!.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New Challenge')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header card ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primaryContainer, cs.secondaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.rocket_launch_rounded,
                      size: 32,
                      color: cs.onPrimaryContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your savings journey',
                      style: textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Build a streak, earn XP, level up!',
                      style: textTheme.bodySmall!.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Challenge name ───────────────────────────────────────────────
              Text(
                'Challenge Name',
                style: textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g. Vacation Fund',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a challenge name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Challenge type ───────────────────────────────────────────────
              Text(
                'Challenge Type',
                style: textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _TypeSelector(selected: _selectedType, onChanged: _onTypeChanged),

              const SizedBox(height: 20),

              // ── Type description ─────────────────────────────────────────────
              _TypeDescription(type: _selectedType),

              const SizedBox(height: 20),

              // ── Target amount ────────────────────────────────────────────────
              Text(
                'Target Amount (₹)',
                style: textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 5000',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a target amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 36),

              // ── Submit ───────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Start Challenge'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Type Selector ────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final ChallengeType selected;
  final ValueChanged<ChallengeType> onChanged;

  @override
  Widget build(BuildContext context) {
    final types = ChallengeType.values;
    return Wrap(
      spacing: 8,
      children: types.map((type) {
        final isSelected = type == selected;
        return ChoiceChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (_) => onChanged(type),
        );
      }).toList(),
    );
  }
}

// ── Type Description ─────────────────────────────────────────────────────────

class _TypeDescription extends StatelessWidget {
  const _TypeDescription({required this.type});

  final ChallengeType type;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Map<ChallengeType, ({IconData icon, String text})> desc = {
      ChallengeType.thirtyDay: (
        icon: Icons.calendar_month_rounded,
        text:
            'Save a fixed amount every day for 30 days. Perfect for building a daily savings habit.',
      ),
      ChallengeType.fiftyTwoWeek: (
        icon: Icons.trending_up_rounded,
        text:
            'Save ₹1 in week 1, ₹2 in week 2 … ₹52 in week 52. Total = ₹1,378. Gradually increase your savings each week.',
      ),
      ChallengeType.custom: (
        icon: Icons.tune_rounded,
        text:
            'Set your own target amount and save at your own pace. Full flexibility!',
      ),
    };

    final info = desc[type]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(info.icon, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info.text,
              style: textTheme.bodySmall!.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
