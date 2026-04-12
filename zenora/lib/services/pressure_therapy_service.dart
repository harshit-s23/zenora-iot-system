// lib/services/pressure_therapy_service.dart
//
// Pressure Therapy Service — controls both phone vibration AND
// sends commands to ESP32 hardware over WiFi.
//
// Hardware integration: ESP32 listens on /therapy/start, /therapy/stop,
// /therapy/intensity with intensity 0–255.
// Flutter sends HTTP commands; ESP32 drives the actual pressure actuator.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;

enum TherapyPhase { rampUp, peak, rampDown, idle }

class PressureTherapyService {
  static final PressureTherapyService instance = PressureTherapyService._();
  PressureTherapyService._();

  // ── Hardware config ────────────────────────────────────────────────────────
  // Set this to your ESP32's IP address on the same WiFi network
  static String esp32Ip =
      '10.59.180.90'; // ✅ UPDATE to your ESP32 IP from Serial Monitor
  static String get _baseUrl => 'http://$esp32Ip';
  static bool hardwareConnected = true; // ✅ set true to send commands to ESP32

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isRunning = false;
  int _currentCycle = 0;
  TherapyPhase _phase = TherapyPhase.idle;
  Timer? _cycleTimer;

  // 11-step intensity curve: ramp up → peak → ramp down
  // Maps to 0–255 for ESP32 PWM and vibration amplitude
  static const List<int> intensityCurve = [
    60,
    100,
    140,
    180,
    220,
    255,
    255,
    220,
    180,
    140,
    80
  ];

  // Callbacks
  VoidCallback? onCycleUpdate;
  VoidCallback? onSessionComplete;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isRunning => _isRunning;
  int get currentCycle => _currentCycle;
  int get totalCycles => intensityCurve.length;
  TherapyPhase get phase => _phase;

  int get currentIntensity =>
      _currentCycle < intensityCurve.length ? intensityCurve[_currentCycle] : 0;

  double get intensityPercent => currentIntensity / 255.0;

  TherapyPhase _phaseForCycle(int cycle) {
    if (cycle < 4) return TherapyPhase.rampUp;
    if (cycle < 7) return TherapyPhase.peak;
    return TherapyPhase.rampDown;
  }

  String get phaseLabel {
    switch (_phase) {
      case TherapyPhase.rampUp:
        return 'Building Pressure...';
      case TherapyPhase.peak:
        return 'Peak Stimulation';
      case TherapyPhase.rampDown:
        return 'Releasing Pressure...';
      case TherapyPhase.idle:
        return 'Ready';
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> start({
    VoidCallback? onUpdate,
    VoidCallback? onComplete,
  }) async {
    if (_isRunning) return;
    _isRunning = true;
    _currentCycle = 0;
    onCycleUpdate = onUpdate;
    onSessionComplete = onComplete;

    await _sendHardwareCommand('start', intensity: intensityCurve[0]);
    _runNextCycle();
  }

  void stop() {
    _isRunning = false;
    _currentCycle = 0;
    _phase = TherapyPhase.idle;
    _cycleTimer?.cancel();
    _cycleTimer = null;
    _sendHardwareCommand('stop', intensity: 0);
    _vibrate(0);
  }

  // ── Internal cycle runner ─────────────────────────────────────────────────

  void _runNextCycle() {
    if (!_isRunning || _currentCycle >= intensityCurve.length) {
      stop();
      onSessionComplete?.call();
      return;
    }

    final intensity = intensityCurve[_currentCycle];
    _phase = _phaseForCycle(_currentCycle);

    // Drive phone vibration (mirrors hardware)
    _vibrate(intensity);

    // Drive hardware
    _sendHardwareCommand('intensity', intensity: intensity);

    onCycleUpdate?.call();

    // Each cycle is 1 second vibration + 400ms pause
    _cycleTimer = Timer(const Duration(milliseconds: 1400), () {
      _currentCycle++;
      _runNextCycle();
    });
  }

  void _vibrate(int amplitude) {
    if (amplitude == 0) {
      Vibration.cancel();
      return;
    }
    try {
      Vibration.vibrate(
        duration: 900,
        amplitude: amplitude.clamp(1, 255),
      );
    } catch (e) {
      debugPrint('[PressureTherapy] Vibration error: $e');
    }
  }

  // ── Hardware HTTP commands ────────────────────────────────────────────────
  //
  // ESP32 endpoint contract:
  //   POST /therapy/command
  //   Body: { "command": "start"|"stop"|"intensity", "intensity": 0-255 }
  //
  // ESP32 response: { "status": "ok" }

  Future<bool> _sendHardwareCommand(String command, {int intensity = 0}) async {
    if (!hardwareConnected) {
      debugPrint('[PressureTherapy] Hardware not connected — phone only mode');
      return false;
    }
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/therapy/command'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'command': command, 'intensity': intensity}),
          )
          .timeout(const Duration(milliseconds: 500));

      final ok = response.statusCode == 200;
      debugPrint(
          '[PressureTherapy] HW command=$command intensity=$intensity → ${ok ? "OK" : "FAIL"}');
      return ok;
    } catch (e) {
      debugPrint('[PressureTherapy] HW error: $e');
      return false;
    }
  }

  /// Check if ESP32 is reachable and update hardwareConnected flag
  Future<bool> checkHardwareConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/ping'))
          .timeout(const Duration(seconds: 2));
      hardwareConnected = response.statusCode == 200;
      debugPrint(
          '[PressureTherapy] Hardware ${hardwareConnected ? "ONLINE" : "OFFLINE"}');
      return hardwareConnected;
    } catch (_) {
      hardwareConnected = false;
      return false;
    }
  }

  void dispose() => stop();
}
