// ════════════════════════════════════════════════════════════════════════════
// lib/services/haptic_service.dart
//
// Pressure Therapy Service — vibration-based stress relief simulation.
// Uses 'vibration' package to create pulsing patterns.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  static final HapticService instance = HapticService._();
  HapticService._();

  bool _isRunning = false;
  Timer? _patternTimer;
  int _cycleCount = 0;

  bool get isRunning => _isRunning;

  // Increasing → plateau → decreasing vibration pattern (8-cycle session)
  static const List<int> _intensityPattern = [
    100, 150, 200, 250, 300, 300, 300, 250, 200, 150, 100,
  ];

  Future<bool> isAvailable() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      return hasVibrator;
    } catch (_) {
      return false;
    }
  }

  Future<void> startPressureTherapy({VoidCallback? onCycleComplete, VoidCallback? onSessionEnd}) async {
    if (_isRunning) return;
    _isRunning = true;
    _cycleCount = 0;

    final available = await isAvailable();
    if (!available) {
      debugPrint('[HapticService] Vibration not available on this device');
      _isRunning = false;
      return;
    }

    _runCycle(onCycleComplete: onCycleComplete, onSessionEnd: onSessionEnd);
  }

  void _runCycle({VoidCallback? onCycleComplete, VoidCallback? onSessionEnd}) {
    if (!_isRunning || _cycleCount >= _intensityPattern.length) {
      stop();
      onSessionEnd?.call();
      return;
    }

    final intensity = _intensityPattern[_cycleCount];
    final duration = 600;

    try {
      Vibration.vibrate(duration: duration, amplitude: intensity.clamp(1, 255));
    } catch (e) {
      debugPrint('[HapticService] Vibrate error: $e');
    }

    _cycleCount++;
    onCycleComplete?.call();

    _patternTimer = Timer(Duration(milliseconds: duration + 400), () {
      _runCycle(onCycleComplete: onCycleComplete, onSessionEnd: onSessionEnd);
    });
  }

  void stop() {
    _isRunning = false;
    _cycleCount = 0;
    _patternTimer?.cancel();
    _patternTimer = null;
    try {
      Vibration.cancel();
    } catch (_) {}
  }

  void dispose() {
    stop();
  }
}
