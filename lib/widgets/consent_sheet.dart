import 'package:flutter/material.dart';
import '../services/persistence_service.dart';

class ConsentSheet extends StatelessWidget {
  const ConsentSheet({super.key});

  static Future<void> showOnce(BuildContext context) async {
    final prefs = PersistenceService();
    final seen = await prefs.getBool('consent_seen') ?? false;
    if (seen) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ConsentSheet(),
    );
    await prefs.setBool('consent_seen', true);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Privacy & Safety', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('DreamShield measures noise levels and motion to adapt ANC. No raw audio is stored. You can delete data anytime.'),
      const SizedBox(height: 12),
      Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('I understand')))
    ]),
  );
}
