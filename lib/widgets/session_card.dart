import 'package:flutter/material.dart';
import '../models/sleep_session.dart';
import 'package:intl/intl.dart';

class SessionCard extends StatelessWidget {
  final SleepSession session;
  final VoidCallback onTap;
  const SessionCard({super.key, required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • HH:mm');
    return Card(
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${df.format(session.start)} → ${DateFormat('HH:mm').format(session.end)}'),
        subtitle: Text('Duration: ${session.durationHours.toStringAsFixed(1)} h  • Comfort ${session.comfortRating}/5'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
