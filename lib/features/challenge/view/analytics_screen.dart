import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_formatters.dart';
import '../model/challenge_model.dart';
import '../provider/challenge_provider.dart';

/// Analytics screen showing savings progress as a line chart and
/// weekly savings as a bar chart.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as String;

    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        final challenge = provider.getById(id);
        if (challenge == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Analytics')),
            body: const Center(child: Text('Challenge not found.')),
          );
        }
        return _AnalyticsView(challenge: challenge);
      },
    );
  }
}

// ── Analytics View ────────────────────────────────────────────────────────────

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView({required this.challenge});

  final ChallengeModel challenge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final log = challenge.savingsLog;

    // Build sorted date → amount list
    final sortedEntries = log.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Cumulative savings per day (for line chart)
    final List<({DateTime date, double cumulative})> cumulativeData = [];
    double running = 0;
    for (final entry in sortedEntries) {
      running += entry.value;
      cumulativeData.add((
        date: DateTime.parse(entry.key),
        cumulative: running,
      ));
    }

    // Weekly savings (for bar chart) — last 8 weeks or however many we have
    final Map<String, double> weeklyMap = _buildWeeklyMap(sortedEntries);
    final weekLabels = weeklyMap.keys.toList();
    final weekValues = weeklyMap.values.toList();

    return Scaffold(
      appBar: AppBar(title: Text('${challenge.title} – Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary chips ───────────────────────────────────────────────
            _SummaryRow(challenge: challenge, cs: cs),

            const SizedBox(height: 24),

            // ── Cumulative Line Chart ────────────────────────────────────────
            Text(
              '📈 Savings Progress',
              style: textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _LineChartCard(
              cumulativeData: cumulativeData,
              target: challenge.targetAmount,
              cs: cs,
            ),

            const SizedBox(height: 24),

            // ── Weekly Bar Chart ─────────────────────────────────────────────
            Text(
              '📊 Weekly Savings',
              style: textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _BarChartCard(
              weekLabels: weekLabels,
              weekValues: weekValues,
              cs: cs,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Groups daily savings log into ISO week buckets (e.g. "W1", "W2", …).
  Map<String, double> _buildWeeklyMap(
    List<MapEntry<String, double>> sortedEntries,
  ) {
    if (sortedEntries.isEmpty) return {};

    // Determine first day
    final first = DateTime.parse(sortedEntries.first.key);

    final Map<int, double> weekMap = {};
    for (final entry in sortedEntries) {
      final d = DateTime.parse(entry.key);
      final week = d.difference(first).inDays ~/ 7;
      weekMap[week] = (weekMap[week] ?? 0) + entry.value;
    }

    // Convert to sorted, labelled map
    final sorted = weekMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {for (final e in sorted) 'W${e.key + 1}': e.value};
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.challenge, required this.cs});

  final ChallengeModel challenge;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final remaining = (challenge.targetAmount - challenge.savedAmount).clamp(
      0.0,
      double.infinity,
    );

    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            label: 'Saved',
            value: AppFormatters.formatCurrency(challenge.savedAmount),
            color: cs.primary,
            icon: Icons.savings_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            label: 'Remaining',
            value: AppFormatters.formatCurrency(remaining),
            color: cs.tertiary,
            icon: Icons.pending_actions_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            label: 'Entries',
            value: '${challenge.savingsLog.length}',
            color: cs.secondary,
            icon: Icons.receipt_long_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.labelLarge!.copyWith(
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

// ── Line Chart ────────────────────────────────────────────────────────────────

class _LineChartCard extends StatelessWidget {
  const _LineChartCard({
    required this.cumulativeData,
    required this.target,
    required this.cs,
  });

  final List<({DateTime date, double cumulative})> cumulativeData;
  final double target;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (cumulativeData.isEmpty) {
      return _noDataCard(context);
    }

    final maxY = target > 0 ? target : cumulativeData.last.cumulative * 1.2;

    final spots = cumulativeData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.cumulative);
    }).toList();

    return _ChartCard(
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (cumulativeData.length - 1).toDouble().clamp(
                1,
                double.infinity,
              ),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (cumulativeData.length / 4).ceilToDouble().clamp(
                      1,
                      double.infinity,
                    ),
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= cumulativeData.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppFormatters.formatShortDate(cumulativeData[idx].date),
                      style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (val, meta) {
                  if (val == 0) return const SizedBox();
                  return Text(
                    '₹${(val / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            // Target dashed line
            if (target > 0)
              LineChartBarData(
                spots: [
                  FlSpot(0, target),
                  FlSpot(
                    (cumulativeData.length - 1).toDouble().clamp(
                          1,
                          double.infinity,
                        ),
                    target,
                  ),
                ],
                isCurved: false,
                color: cs.error.withValues(alpha: 0.5),
                barWidth: 1.5,
                dashArray: [5, 4],
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            // Actual savings
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: cs.primary,
                  strokeColor: cs.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.25),
                    cs.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noDataCard(BuildContext context) {
    return _ChartCard(
      child: Center(
        child: Text(
          'No savings data yet.\nAdd some deposits to see your chart!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
        ),
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
    required this.weekLabels,
    required this.weekValues,
    required this.cs,
  });

  final List<String> weekLabels;
  final List<double> weekValues;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (weekLabels.isEmpty) {
      return _ChartCard(
        child: Center(
          child: Text(
            'No weekly data yet.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxY = weekValues.reduce((a, b) => a > b ? a : b) * 1.3;

    return _ChartCard(
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (val, meta) {
                  if (val == 0) return const SizedBox();
                  return Text(
                    '₹${(val / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= weekLabels.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      weekLabels[idx],
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: weekValues.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Shared Chart Container ────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant, width: 0.8),
      ),
      child: child,
    );
  }
}
