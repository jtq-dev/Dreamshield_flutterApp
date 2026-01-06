// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../widgets/stillness_gauge.dart';
import '../widgets/stat_chip.dart';
import '../widgets/badges_strip.dart';
import '../widgets/onboarding_sheet.dart';

import '../models/sleep_session.dart';
import '../providers_sessions.dart'; // <-- Firestore auth + sessions + repo
import '../services/badges_service.dart';
import '../services/onboarding_service.dart';
import '../services/insights_service.dart';

import 'sleep_form.dart';
import 'sessions.dart';
import 'studio.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final seen = await OnboardingService().hasSeen();
      if (!seen && mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => const OnboardingSheet(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const SafeArea(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SafeArea(child: Center(child: Text('Auth error: $e'))),
      data: (user) {
        if (user == null) {
          return const SafeArea(
            child: Center(child: Text('Please sign in to see your sleep overview.')),
          );
        }

        final sessionsAsync = ref.watch(sessionsStreamProviderFamily(user.uid));

        return sessionsAsync.when(
          loading: () => const SafeArea(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SafeArea(child: Center(child: Text('Error: $e'))),
          data: (sessions) {
            const goal = 7.5;
            final last = sessions.isEmpty ? 0.0 : sessions.last.durationHours;
            final avg = sessions.isEmpty
                ? 0.0
                : sessions
                .map((e) => e.durationHours)
                .fold<double>(0.0, (a, b) => a + b) /
                sessions.length;

            final buckets = _last7Buckets(sessions);
            final spots = List<FlSpot>.generate(
              buckets.length,
                  (i) => FlSpot(i.toDouble(), buckets[i].hours),
            );

            final streak = _calcStreak(sessions);
            final badges = BadgesService().compute(sessions, goal: goal);
            final insights = InsightsService().compute(sessions, goal: goal);
            final weekdayFmt = DateFormat.E();

            return SafeArea(
              child: ListView(
                children: [
                  _HeroHeader(avg: avg, streak: streak, goal: goal),
                  BadgesStrip(badges: badges),

                  // KPI chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatChip(label: 'Last', value: '${last.toStringAsFixed(1)}h'),
                        StatChip(label: 'Avg', value: '${avg.toStringAsFixed(1)}h'),
                        const StatChip(label: 'Goal', value: '7.5h'),
                        StatChip(label: 'Streak', value: '${streak}d'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Chart
                  _Card(
                    title: 'Last 7 nights',
                    child: SizedBox(
                      height: 180,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            right: 12, left: 6, top: 12, bottom: 6),
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: 12,
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 22,
                                  getTitlesWidget: (v, _) {
                                    if ((v - v.roundToDouble()).abs() > 0.001) {
                                      return const SizedBox.shrink();
                                    }
                                    final i = v.toInt();
                                    if (i < 0 || i >= buckets.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        weekdayFmt.format(buckets[i].day),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                spots: spots.isEmpty
                                    ? const [FlSpot(0, 0), FlSpot(6, 0)]
                                    : spots,
                                barWidth: 4,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                            extraLinesData: ExtraLinesData(horizontalLines: [
                              HorizontalLine(
                                y: goal,
                                dashArray: const [8, 6],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  labelResolver: (_) => 'goal ${goal.toStringAsFixed(1)}h',
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: StillnessGauge(),
                  ),

                  _Card(
                    title: 'Coach',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avg ${insights.avg.toStringAsFixed(1)}h • '
                              'Median ${insights.median.toStringAsFixed(1)}h • '
                              'σ ${insights.std.toStringAsFixed(1)}h',
                        ),
                        const SizedBox(height: 8),
                        ...insights.advice().map(
                              (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(t)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Quick actions (writes to Firestore)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _QuickActions(uid: user.uid),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------- Helpers ----------
  List<_DayBucket> _last7Buckets(List<SleepSession> sessions) {
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 6));
    final byDay = <DateTime, double>{};

    for (final s in sessions) {
      final startLocal = s.start.toLocal();
      final endLocal = s.end.toLocal();
      final key = dateOnly(startLocal);
      if (key.isBefore(start) || key.isAfter(today)) continue;

      final hrs = endLocal.difference(startLocal).inMinutes / 60.0;
      final current = byDay[key] ?? 0.0;
      if (hrs > current) byDay[key] = hrs;
    }

    final list = <_DayBucket>[];
    for (int i = 0; i < 7; i++) {
      final d = dateOnly(start.add(Duration(days: i)));
      list.add(_DayBucket(d, (byDay[d] ?? 0.0).clamp(0.0, 24.0)));
    }
    return list;
  }

  int _calcStreak(List<SleepSession> sessions) {
    if (sessions.isEmpty) return 0;
    final sorted = [...sessions]..sort((a, b) => b.end.compareTo(a.end));
    int streak = 0;
    DateTime cursor = DateTime.now();
    for (final s in sorted) {
      final day = DateTime(s.end.year, s.end.month, s.end.day);
      final cur = DateTime(cursor.year, cursor.month, cursor.day);
      if (day == cur || day == cur.subtract(const Duration(days: 1))) {
        streak++;
        cursor = day;
      } else if (day.isBefore(cur.subtract(const Duration(days: 1)))) {
        break;
      }
    }
    return streak;
  }
}

class _DayBucket {
  final DateTime day;
  final double hours;
  _DayBucket(this.day, this.hours);
}

class _HeroHeader extends StatelessWidget {
  final double avg;
  final int streak;
  final double goal;
  const _HeroHeader({required this.avg, required this.streak, required this.goal});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sleep overview',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: cs.onPrimaryContainer.withOpacity(0.9))),
                const SizedBox(height: 6),
                Text('${avg.toStringAsFixed(1)}h avg',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                    )),
                const SizedBox(height: 6),
                Text('Goal ${goal.toStringAsFixed(1)}h • Streak ${streak}d',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onPrimaryContainer.withOpacity(0.9))),
              ],
            ),
          ),
          Icon(Icons.nightlight_round,
              size: 44, color: cs.onPrimaryContainer.withOpacity(0.9)),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(firestoreRepoProvider);

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SleepFormScreen()),
              );
              if (created is SleepSession) {
                await repo.add(uid, created);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session saved')),
                  );
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Log night'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudioScreen()),
            ),
            icon: const Icon(Icons.graphic_eq),
            label: const Text('Open Studio'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SessionsScreen()),
          ),
          icon: const Icon(Icons.list_alt),
          tooltip: 'Sessions',
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
