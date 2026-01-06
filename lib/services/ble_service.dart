import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class BleDeviceState {
  final bool connected;
  final int? battery; // %
  const BleDeviceState({required this.connected, this.battery});
}

abstract class BleService {
  Stream<BleDeviceState> get state;
  Future<void> scanAndConnect();
  Future<void> disconnect();
  Future<void> setAncLevel(int level);                // 0..100
  Future<void> setMasking(double pink,brown,white);   // 0..1
  Future<void> setAlertMode(int mode);                // 0=off,1=calls,2=favorites
}

/// Web-safe stub; replace with a real implementation on mobile later
class BleServiceImpl implements BleService {
  final _ctrl = StreamController<BleDeviceState>.broadcast();
  BleDeviceState _s = const BleDeviceState(connected: false);

  @override
  Stream<BleDeviceState> get state => _ctrl.stream;

  @override
  Future<void> scanAndConnect() async {
    if (kIsWeb) throw Exception('Bluetooth not available on web build.');
    // TODO: flutter_reactive_ble scanning + connect here
    _s = const BleDeviceState(connected: true, battery: 92);
    _ctrl.add(_s);
  }

  @override
  Future<void> disconnect() async {
    _s = const BleDeviceState(connected: false);
    _ctrl.add(_s);
  }

  @override
  Future<void> setAncLevel(int level) async {/* TODO: write to GATT */}
  @override
  Future<void> setMasking(double p, b, w) async {/* TODO */}
  @override
  Future<void> setAlertMode(int mode) async {/* TODO */}
}
