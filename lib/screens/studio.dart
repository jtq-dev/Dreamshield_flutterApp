import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_mixer.dart';
import '../services/persistence_service.dart';
import '../services/ble_service.dart';
import '../services/adaptive_engine.dart';
import '../providers_sessions.dart'; // <- contains authStateProvider / firestoreRepoProvider

class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({super.key});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  final _mixer = AudioMixer();
  final _prefs = PersistenceService();
  final _ble = BleServiceImpl();
  final _adaptive = AdaptiveEngine();

  double pink = 0.5, brown = 0.3, white = 0.2;
  bool playing = false, _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLocalPreset();
    _adaptive.masking.addListener(() {
      final (p, b, w) = _adaptive.masking.value;
      setState(() {
        pink = p;
        brown = b;
        white = w;
      });
      if (playing) _mixer.setVolumes(pink, brown, white);
    });
  }

  Future<void> _loadLocalPreset() async {
    final jsonPreset = await _prefs.loadMixerPreset();
    if (jsonPreset != null) {
      final m = json.decode(jsonPreset) as Map<String, dynamic>;
      setState(() {
        pink = (m['pink'] as num).toDouble();
        brown = (m['brown'] as num).toDouble();
        white = (m['white'] as num).toDouble();
      });
    }
  }

  Future<void> _saveLocalPreset() async {
    final jsonPreset =
    json.encode({'pink': pink, 'brown': brown, 'white': white});
    await _prefs.saveMixerPreset(jsonPreset);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preset saved locally')),
    );
  }

  Future<void> _saveCloudPreset() async {
    final user = await ref.read(authStateProvider.future);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to save to cloud')),
        );
      }
      return;
    }
    await ref
        .read(firestoreRepoProvider)
        .savePreset(user.uid, {'pink': pink, 'brown': brown, 'white': white});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preset saved to cloud')),
      );
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (playing) {
        await _mixer.stop();
        setState(() => playing = false);
      } else {
        await _mixer.start(pink: pink, brown: brown, white: white);
        setState(() => playing = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), maxLines: 3)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateVolumes() async {
    if (playing) await _mixer.setVolumes(pink, brown, white);
    // push to BLE (no-op on web)
    await _ble.setMasking(pink, brown, white);
  }

  @override
  void dispose() {
    _mixer.dispose();
    _adaptive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Soundscape Studio',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),

          // Device card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (kIsWeb)
                    const Text(
                        'Bluetooth not available in web demo — use Android/iOS to connect.')
                  else
                    Row(
                      children: [
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () async {
                            try {
                              await _ble.scanAndConnect();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                    content: Text(e.toString())));
                              }
                            }
                          },
                          child: const Text('Connect'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _busy ? null : _ble.disconnect,
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          _slider('Pink noise', pink, (v) => setState(() => pink = v),
              onChangeEnd: (_) => _updateVolumes()),
          _slider('Brown noise', brown, (v) => setState(() => brown = v),
              onChangeEnd: (_) => _updateVolumes()),
          _slider('White noise', white, (v) => setState(() => white = v),
              onChangeEnd: (_) => _updateVolumes()),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _toggle,
                  icon: Icon(playing ? Icons.stop : Icons.play_arrow),
                  label: Text(_busy ? 'Please wait…' : (playing ? 'Stop' : 'Play')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _saveLocalPreset,
                  icon: const Icon(Icons.save),
                  label: const Text('Save local'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _saveCloudPreset,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Save to cloud'),
          ),

          const SizedBox(height: 24),
          Text('Breathing (4–7–8)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Inhale 4s • Hold 7s • Exhale 8s — follow the circle.'),
          const SizedBox(height: 8),
          const _BreathingCircle(),

          const SizedBox(height: 24),

          // Adaptive demo (works on web)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adaptive demo',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'Simulate noise floor to see masking adjust automatically.'),
                  Slider(
                    min: 0,
                    max: 1,
                    value: 0.2,
                    onChanged: (v) => _adaptive.noiseSink.add(v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged,
      {ValueChanged<double>? onChangeEnd}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Slider(
              min: 0,
              max: 1,
              divisions: 10,
              value: value,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingCircle extends StatefulWidget {
  const _BreathingCircle();
  @override
  State<_BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<_BreathingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) {
      final t = _c.value;
      double scale;
      if (t < 4 / 19) {
        scale = 0.6 + 0.4 * (t * 19 / 4); // inhale
      } else if (t < 11 / 19) {
        scale = 1.0; // hold
      } else {
        final et = (t - 11 / 19) * 19 / 8; // exhale
        scale = 1.0 - 0.4 * et;
      }
      return Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 180 * scale,
          height: 180 * scale,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient:
            LinearGradient(colors: [Color(0xFF6B7CFF), Color(0xFF9AA5FF)]),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
        ),
      );
    },
  );
}
