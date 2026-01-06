import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sleep_session.dart';
import '../widgets/session_card.dart';
import 'session_detail.dart';
import 'sleep_form.dart';

// 🔁 USE THE FIRESTORE PROVIDERS (not providers_sessions / firestore_service)
import '../providers_sessions.dart';

import '../services/backup_service.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);                 // StreamProvider<User?>
    final repo = ref.read(firestoreRepoProvider);              // FirestoreRepo
    final backup = BackupService();

    Future<void> _export(List<SleepSession> sessions) async {
      final jsonStr = backup.toJsonString(sessions);
      backup.downloadJsonWeb('dreamshield-sessions.json', jsonStr);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloaded sessions JSON')),
      );
    }

    Future<void> _import(String uid) async {
      final jsonStr = await backup.pickJsonWeb();
      if (jsonStr == null) return;
      try {
        final imported = backup.fromJsonString(jsonStr);
        for (final s in imported) {
          await repo.add(uid, s);                               // ✅ repo.add
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imported to Firestore')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: $e')),
          );
        }
      }
    }

    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Auth error: $e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please sign in to see your sessions.'));
        }

        // 🔑 Watch the family stream with UID
        final sessionsAsync = ref.watch(sessionsStreamProviderFamily(user.uid));

        return sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (sessions) => SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: const Text('Sessions'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.file_download),
                      tooltip: 'Export JSON',
                      onPressed: () => _export(sessions),
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_upload),
                      tooltip: 'Import JSON → Firestore',
                      onPressed: () => _import(user.uid),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Log new session',
                      onPressed: () async {
                        final created = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SleepFormScreen()),
                        );
                        if (created is SleepSession) {
                          await repo.add(user.uid, created);     // ✅ repo.add
                        }
                      },
                    ),
                  ],
                ),
                if (sessions.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No sessions yet — log your first night!')),
                  )
                else
                  SliverList.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, i) {
                      final s = sessions[i];
                      return Dismissible(
                        key: ValueKey(s.id),
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          child: const Icon(Icons.delete),
                        ),
                        onDismissed: (_) async {
                          await repo.delete(user.uid, s.id);     // ✅ repo.delete
                        },
                        child: SessionCard(
                          session: s,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s)),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
