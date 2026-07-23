import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class ClapService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _enabled = false;
  bool _isRecording = false;
  Timer? _amplitudeTimer;
  DateTime? _lastClapTime;

  static const double _clapThreshold = 0.7;
  static const Duration _clapDebounce = Duration(milliseconds: 1500);

  Function()? onClapDetected;

  bool get enabled => _enabled;

  Future<void> startListening() async {
    if (_enabled) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    if (!await _recorder.hasPermission()) return;

    _enabled = true;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: '',
    );
    _isRecording = true;

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _checkAmplitude();
    });
  }

  Future<void> _checkAmplitude() async {
    if (!_enabled || !_isRecording) return;

    try {
      final amplitude = await _recorder.getAmplitude();
      final normalized = (amplitude.current + 60) / 60;
      final level = normalized.clamp(0.0, 1.0);

      if (level > _clapThreshold) {
        final now = DateTime.now();
        if (_lastClapTime == null ||
            now.difference(_lastClapTime!) > _clapDebounce) {
          _lastClapTime = now;
          onClapDetected?.call();
        }
      }
    } catch (_) {}
  }

  Future<void> stopListening() async {
    _enabled = false;
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
  }

  void dispose() {
    stopListening();
    _recorder.dispose();
  }
}
