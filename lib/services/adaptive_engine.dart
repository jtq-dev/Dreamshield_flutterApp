import 'dart:async';
import 'package:flutter/foundation.dart';

/// Emits suggested masking levels based on a “noise floor”.
class AdaptiveEngine {
  final _masking = ValueNotifier<(double pink,double brown,double white)>((0.5,0.3,0.2));
  ValueListenable<(double,double,double)> get masking => _masking;

  double _noiseFloor = 0.2; // 0..1
  final _noiseCtrl = StreamController<double>.broadcast();
  Sink<double> get noiseSink => _noiseCtrl.sink;

  AdaptiveEngine() {
    _noiseCtrl.stream.listen((nf) {
      _noiseFloor = nf.clamp(0, 1);
      // Simple policy: more noise -> more brown; less -> reduce overall
      final pink = (0.4 + 0.3 * _noiseFloor).clamp(0.0, 1.0);
      final brown = (0.2 + 0.6 * _noiseFloor).clamp(0.0, 1.0);
      final white = (0.2 - 0.2 * _noiseFloor).clamp(0.0, 1.0);
      _masking.value = (pink, brown, white);
    });
  }

  void dispose() {
    _noiseCtrl.close();
  }
}
