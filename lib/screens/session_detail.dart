import 'package:flutter/material.dart';
import '../models/sleep_session.dart';

class SessionDetailScreen extends StatelessWidget {
  final SleepSession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${session.durationHours.toStringAsFixed(2)} h',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Comfort: ${session.comfortRating}/5'),
            Text('Noise: ${session.noiseLevel}/5'),
            if (session.lat != null && session.lng != null)
              Text('Lat/Lng: ${session.lat}, ${session.lng}'),
            const SizedBox(height: 12),
            Text(session.notes),
          ],
        ),
      ),
    );
  }
}
