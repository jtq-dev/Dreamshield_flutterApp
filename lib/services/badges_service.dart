// lib/services/badges_service.dart
import '../models/sleep_session.dart';

class SleepBadge {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  SleepBadge(this.id, this.title, this.subtitle, this.emoji);
}

class BadgesService {
  List<SleepBadge> compute(List<SleepSession> sessions, {double goal = 7.5}) {
    if (sessions.isEmpty) return [];

    final list = [...sessions]..sort((a, b) => b.end.compareTo(a.end));

    // Streak
    int streak = 0;
    DateTime cursor = DateTime.now();
    for (final s in list) {
      final d = DateTime(s.end.year, s.end.month, s.end.day);
      final c = DateTime(cursor.year, cursor.month, cursor.day);
      if (d == c || d == c.subtract(const Duration(days: 1))) {
        streak++;
        cursor = d;
      } else if (d.isBefore(c.subtract(const Duration(days: 1)))) {
        break;
      }
    }

    final avg = list.map((e) => e.durationHours).reduce((a, b) => a + b) / list.length;
    final best = list.reduce((a, b) => a.durationHours >= b.durationHours ? a : b);

    final badges = <SleepBadge>[];
    if (streak >= 3)  badges.add(SleepBadge('streak3',  '3-day streak',  'Consistency builds habits', '🔥'));
    if (streak >= 7)  badges.add(SleepBadge('streak7',  '7-day streak',  'A whole week of wins', '🏅'));
    if (streak >= 14) badges.add(SleepBadge('streak14', '14-day streak', 'Elite consistency', '💎'));
    if (avg >= goal)  badges.add(SleepBadge('goal', 'Goal met', 'Average meets your target', '✅'));
    if (best.durationHours >= 8.0) badges.add(SleepBadge('eight', '8h+ night', 'Great recovery', '🌙'));
    return badges;
  }
}
