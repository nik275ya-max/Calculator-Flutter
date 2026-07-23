import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription? _accelerometerSubscription;
  bool _enabled = false;
  DateTime? _lastShakeTime;

  Function()? onShakeDetected;

  void startListening() {
    if (_enabled) return;
    _enabled = true;
    _lastShakeTime = null;

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (acceleration > 28) {
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
