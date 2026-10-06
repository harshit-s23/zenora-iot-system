// lib/services/pressure_therapy_service.dart
//
// Pressure Therapy Service — controls phone vibration, sends commands to
// ESP32 hardware over WiFi, AND drives the haptic motor on ESP32 pin D19.
//
// Hardware integration:
//   POST /therapy/command  → pressure actuator (existing)
//   POST /haptic/command   → haptic motor on D19 (NEW)
//     Body: { "command": "start"|"stop"|"pulse", "intensity": 0-255, "duration": ms }
//
// Admin override: sendHapticForStress(stressIndex) fires a single haptic
// pulse scaled to the manipulated stress value (used by admin slider).

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
  static bool hardwareConnected = false;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isRunning = false;
  int _currentCycle = 0;
  int _sessionGeneration = 0;
  TherapyPhase _phase = TherapyPhase.idle;
  Timer? _cycleTimer;
  Future<void> _hardwareCommandQueue = Future<void>.value();

  // 11-step intensity curve: ramp up → peak → ramp down
  // Maps to 0–255 for ESP32 PWM and vibration amplitude
  static const List<int> intensityCurve = [
    55, // cycle 1  — gentle wake-up
    85, // cycle 2  — light pressure
    115, // cycle 3  — building
    145, // cycle 4  — transition
    175, // cycle 5  — pre-peak
    200, // cycle 6  — therapeutic peak ✅
    210, // cycle 7  — sustained peak ✅
    175, // cycle 8  — begin release
    140, // cycle 9  — ramp-down
    90, // cycle 10 — winding down
    55, // cycle 11 — gentle close (mirrors cycle 1)
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
    final session = ++_sessionGeneration;
    _isRunning = true;
    _currentCycle = 0;
    onCycleUpdate = onUpdate;
    onSessionComplete = onComplete;

    final connected = await checkHardwareConnection();
    if (!_isCurrentSession(session)) return;
    if (connected) {
      await _sendHardwareCommand('start', intensity: intensityCurve[0]);
      if (!_isCurrentSession(session)) return;
      await _sendHapticCommand('start',
          intensity: intensityCurve[0], duration: 900);
      if (!_isCurrentSession(session)) return;
    } else {
      debugPrint(
          '[PressureTherapy] ESP32 unavailable at $_baseUrl; continuing phone-only');
    }
    _runNextCycle(session);
  }

  void stop() {
    // Invalidate pending start/cycle continuations before enqueueing stop.
    // This prevents a delayed HTTP response from restarting therapy afterward.
    _sessionGeneration++;
    _isRunning = false;
    _currentCycle = 0;
    _phase = TherapyPhase.idle;
    _cycleTimer?.cancel();
    _cycleTimer = null;
    _sendHardwareCommand('stop', intensity: 0);
    _sendHapticCommand('stop', intensity: 0, duration: 0);
    _vibrate(0);
  }

  // ── Internal cycle runner ─────────────────────────────────────────────────

  bool _isCurrentSession(int session) =>
      _isRunning && session == _sessionGeneration;

  void _runNextCycle(int session) {
    if (!_isCurrentSession(session)) return;
    if (_currentCycle >= intensityCurve.length) {
      stop();
      onSessionComplete?.call();
      return;
    }

    final intensity = intensityCurve[_currentCycle];
    _phase = _phaseForCycle(_currentCycle);

    // Drive phone vibration (mirrors hardware)
    _vibrate(intensity);

    // Drive pressure actuator hardware
    _sendHardwareCommand('intensity', intensity: intensity);

    // Drive haptic motor on ESP32 D19 — pulse mirrors the therapy cycle
    _sendHapticCommand('pulse', intensity: intensity, duration: 900);

    onCycleUpdate?.call();

    // Each cycle is 1 second vibration + 400ms pause
    _cycleTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!_isCurrentSession(session)) return;
      _currentCycle++;
      _runNextCycle(session);
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

  Future<bool> _sendHardwareCommand(String command, {int intensity = 0}) =>
      _enqueueHardwareCommand(
        () => _sendHardwareCommandNow(command, intensity: intensity),
      );

  Future<bool> _sendHardwareCommandNow(String command,
      {int intensity = 0}) async {
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
          .timeout(const Duration(milliseconds: 1000));

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
          .timeout(const Duration(milliseconds: 800));
      hardwareConnected = response.statusCode == 200;
      debugPrint(
          '[PressureTherapy] Hardware ${hardwareConnected ? "ONLINE" : "OFFLINE"}');
      return hardwareConnected;
    } catch (_) {
      hardwareConnected = false;
      return false;
    }
  }

  // ── Haptic motor (D19) HTTP commands ──────────────────────────────────────
  //
  // ESP32 endpoint contract:
  //   POST /haptic/command
  //   Body: { "command": "start"|"stop"|"pulse", "intensity": 0-255, "duration": ms }
  //
  // ESP32: drives PWM on GPIO 19 (D19) for the haptic motor.

  Future<bool> _sendHapticCommand(String command,
          {int intensity = 0, int duration = 900}) =>
      _enqueueHardwareCommand(
        () => _sendHapticCommandNow(command,
            intensity: intensity, duration: duration),
      );

  Future<bool> _sendHapticCommandNow(String command,
      {int intensity = 0, int duration = 900}) async {
    if (!hardwareConnected) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/haptic/command'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'command': command,
              'intensity': intensity,
              'duration': duration
            }),
          )
          .timeout(const Duration(milliseconds: 1000));

      final ok = response.statusCode == 200;
      debugPrint(
          '[HapticMotor D19] command=$command intensity=$intensity duration=${duration}ms → ${ok ? "OK" : "FAIL"}');
      return ok;
    } catch (e) {
      debugPrint('[HapticMotor D19] error: $e');
      return false;
    }
  }

  /// Called by admin panel when stress index is manually overridden.
  /// Fires a single haptic pulse on D19 scaled to the stress value (0–100).
  /// Intensity is linearly mapped: stress 0 → amplitude 30, stress 100 → 255.
  Future<void> sendHapticForStress(double stressIndex) async {
    final int amplitude =
        (30 + ((stressIndex / 100.0) * 225)).round().clamp(30, 255);
    // Duration also scales with stress: 200ms at 0 → 800ms at 100
    final int duration =
        (200 + ((stressIndex / 100.0) * 600)).round().clamp(200, 800);

    debugPrint(
        '[HapticMotor D19] Admin stress override → pulse amplitude=$amplitude duration=${duration}ms');
    await _sendHapticCommand('pulse', intensity: amplitude, duration: duration);
  }

  Future<bool> _enqueueHardwareCommand(Future<bool> Function() send) {
    final result = Completer<bool>();
    _hardwareCommandQueue = _hardwareCommandQueue.then((_) async {
      try {
        result.complete(await send());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  void dispose() => stop();
}
