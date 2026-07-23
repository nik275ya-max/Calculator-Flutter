import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription? _accelerometerSubscription;
  bool _enabled = false;
  DateTime? _lastShakeTime;
  double _prevX = 0;
  double _prevY = 0;
  double _prevZ = 0;

  Function()? onShakeDetected;

  void startListening() {
    if (_enabled) return;
    _enabled = true;
    _lastShakeTime = null;

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final dx = (event.x - _prevX).abs();
      final dy = (event.y - _prevY).abs();
      final dz = (event.z - _prevZ).abs();
      _prevX = event.x;
      _prevY = event.y;
      _prevZ = event.z;

      final delta = dx + dy + dz;
      if (delta > 15) {
        final now = DateTime.now();
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > const Duration(seconds: 3)) {
          _lastShakeTime = now;
          onShakeDetected?.call();
        }
      }
    });
  }

  void stopListening() {
    _enabled = false;
    _lastShakeTime = null;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  void dispose() {
    stopListening();
  }
}
