import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class StillnessGauge extends StatefulWidget {
  const StillnessGauge({super.key});
  @override
  State<StillnessGauge> createState() => _StillnessGaugeState();
}

class _StillnessGaugeState extends State<StillnessGauge> {
  double _smoothMagnitude = 0;
  static const _alpha = 0.2;
  bool _sensorOk = false;

  bool get _supportsMotion =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_supportsMotion) {
      accelerometerEventStream().listen((e) {
        final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        setState(() {
          _smoothMagnitude = _alpha * mag + (1 - _alpha) * _smoothMagnitude;
          _sensorOk = true;
        });
      }, onError: (_) {
        setState(() => _sensorOk = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsMotion || !_sensorOk) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stillness', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('Motion sensor not available on this device.'),
            ],
          ),
        ),
      );
    }

    final norm = (_smoothMagnitude - 9.3) / (11.5 - 9.3);
    final stillness = (1 - norm.clamp(0, 1).toDouble());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stillness', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: stillness),
              duration: const Duration(milliseconds: 350),
              builder: (_, value, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: value),
                  const SizedBox(height: 6),
                  Text('${(value * 100).round()}% calm'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
