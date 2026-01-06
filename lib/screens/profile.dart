// lib/screens/profile.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/persistence_service.dart';
import '../providers_sessions.dart';           // authStateProvider
import 'auth_gate.dart';

// Optional: if you want to push alert mode to your device over BLE on mobile.
// Safe no-op on web. If you don't have this service, you can remove it.
import '../services/ble_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _prefs = PersistenceService();

  double goal = 7.5;
  bool dark = false;

  // NEW: alert mode persisted locally (0=Off, 1=Allow calls, 2=Allow favorites)
  int alertMode = 0;

  // Optional BLE instance (safe to keep; ignored on web)
  final _ble = BleServiceImpl();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await _prefs.loadGoal();
    final d = await _prefs.loadDarkTheme();

    // NEW: load stored alert mode (default 0)
    final a = await _prefs.loadAlertMode();

    if (!mounted) return;
    setState(() {
      goal = g;
      dark = d;
      alertMode = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Auth error: $e')),
      data: (user) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Profile & Settings',
                  style: Theme.of(context).textTheme.headlineSmall),

              const SizedBox(height: 12),

              // ----- Account card -----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null) ...[
                        Text('Signed in as',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(user.email ?? '(no email)'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text('Sign out'),
                        ),
                      ] else ...[
                        const Text('Not signed in'),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AuthGate(),
                            ),
                          ),
                          child: const Text('Sign in / Register'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ----- Alerts (NEW) -----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alert Mode (breakthrough)',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButton<int>(
                        value: alertMode,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Off')),
                          DropdownMenuItem(value: 1, child: Text('Allow calls')),
                          DropdownMenuItem(
                              value: 2, child: Text('Allow favorites')),
                        ],
                        onChanged: (v) async {
                          if (v == null) return;
                          setState(() => alertMode = v);
                          // persist locally
                          await _prefs.saveAlertMode(v);
                          // optional: push to BLE device on mobile
                          if (!kIsWeb) {
                            try {
                              await _ble.setAlertMode(v);
                            } catch (_) {
                              // swallow BLE errors; UI still persists choice
                            }
                          }
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Alert mode saved')),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose which alerts can break through masking. '
                            'Saved on this device; pushed to hardware when connected.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ----- Sleep goal / theme -----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sleep Goal: ${goal.toStringAsFixed(1)} h',
                          style: Theme.of(context).textTheme.titleMedium),
                      Slider(
                        min: 4,
                        max: 10,
                        divisions: 12,
                        value: goal,
                        onChanged: (v) => setState(() => goal = v),
                      ),
                      SwitchListTile(
                        value: dark,
                        onChanged: (v) async {
                          setState(() => dark = v);
                          await _prefs.saveDarkTheme(v);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Theme preference saved')),
                          );
                        },
                        title: const Text('Dark theme preference'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () async {
                          await _prefs.saveGoal(goal);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Goal saved')),
                          );
                        },
                        child: const Text('Save Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
