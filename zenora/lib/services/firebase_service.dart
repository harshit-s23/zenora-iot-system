// ════════════════════════════════════════════════════════════════════════════
// lib/services/firebase_service.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Snapshot of one complete device state resolved from Firebase.
class DeviceSnapshot {
  final double heartRate;
  final double spo2;
  final double gsr;
  final double temperature;
  final double stressIndex;
  final bool fall;
  final bool overrideEnabled;
  final bool esp32Online;
  final String scenario;

  // ── MPU6050 fall detection fields ─────────────────────────────────────────
  final double roll; // degrees  (linear orientation)
  final double pitch; // degrees  (linear orientation)
  final double linearX; // m/s²     (linear acceleration)
  final double linearY; // m/s²
  final double linearZ; // m/s²
  final double rotationalX; // °/s      (gyroscope)
  final double rotationalY; // °/s
  final double rotationalZ; // °/s

  const DeviceSnapshot({
    required this.heartRate,
    required this.spo2,
    required this.gsr,
    required this.temperature,
    required this.stressIndex,
    required this.fall,
    required this.overrideEnabled,
    required this.esp32Online,
    this.scenario = 'Calm',
    // MPU6050 defaults → upright, stationary
    this.roll = 0.0,
    this.pitch = 0.0,
    this.linearX = 0.0,
    this.linearY = 0.0,
    this.linearZ = 9.81,
    this.rotationalX = 0.0,
    this.rotationalY = 0.0,
    this.rotationalZ = 0.0,
  });

  /// Fallback when Firebase is unreachable
  factory DeviceSnapshot.fallback() => const DeviceSnapshot(
        heartRate: 72,
        spo2: 98,
        gsr: 4.2,
        temperature: 36.6,
        stressIndex: 34,
        fall: false,
        overrideEnabled: false,
        esp32Online: false,
      );
}

class FirebaseService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // ── Device ID ─────────────────────────────────────────────────────────────
  static const String _deviceId = 'device_1';

  // ── Database references ───────────────────────────────────────────────────
  late final DatabaseReference _rootRef;
  late final DatabaseReference _realDataRef;
  late final DatabaseReference _overrideRef;
  late final DatabaseReference _connectionRef;

  bool _initialized = false;

  // ── Stream controller ──────────────────────────────────────────────────────
  final _snapshotController = StreamController<DeviceSnapshot>.broadcast();
  Stream<DeviceSnapshot> get deviceStream => _snapshotController.stream;

  // ── Internal subscriptions ────────────────────────────────────────────────
  StreamSubscription? _realDataSub;
  StreamSubscription? _overrideSub;

  // ── Last known values ─────────────────────────────────────────────────────
  Map<String, dynamic> _latestReal = {};
  Map<String, dynamic> _latestOverride = {};

  // ─────────────────────────────────────────────────────────────────────────
  /// Call once from main() AFTER Firebase.initializeApp()
  // ─────────────────────────────────────────────────────────────────────────
  void init() {
    if (_initialized) return;
    _initialized = true;

    _rootRef = FirebaseDatabase.instance.ref(_deviceId);
    _realDataRef = _rootRef.child('real_data');
    _overrideRef = _rootRef.child('override');
    _connectionRef = _rootRef.child('connection');

    _seedDefaults();

    _realDataSub = _realDataRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        _latestReal = Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      _emit();
    }, onError: (e) {
      debugPrint('[Firebase] real_data listen error: $e');
    });

    _overrideSub = _overrideRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        _latestOverride =
            Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      _emit();
    }, onError: (e) {
      debugPrint('[Firebase] override listen error: $e');
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  /// Merge real + override, resolve which to serve, push to stream.
  // ─────────────────────────────────────────────────────────────────────────
  void _emit() {
    try {
      final overrideEnabled = (_latestOverride['enabled'] as bool?) ?? false;
      final esp32Online = (_latestReal['esp32_online'] as bool?) ?? false;

      double heartRate, spo2, gsr, temperature, stressIndex;
      bool fall;
      String scenario;
      double roll, pitch, linearX, linearY, linearZ;
      double rotationalX, rotationalY, rotationalZ;

      if (overrideEnabled) {
        heartRate = _toDouble(_latestOverride['heart_rate'], 72.0);
        spo2 = _toDouble(_latestOverride['spo2'], 98.0);
        gsr = _toDouble(_latestOverride['gsr'], 4.2);
        temperature = _toDouble(_latestOverride['temperature'], 36.6);
        stressIndex = _toDouble(_latestOverride['stress_index'], 34.0);
        fall = (_latestOverride['fall'] as bool?) ?? false;
        scenario = (_latestOverride['scenario'] as String?) ?? 'Calm';
        // MPU override values
        roll = _toDouble(_latestOverride['mpu_roll'], 0.0);
        pitch = _toDouble(_latestOverride['mpu_pitch'], 0.0);
        linearX = _toDouble(_latestOverride['mpu_linear_x'], 0.0);
        linearY = _toDouble(_latestOverride['mpu_linear_y'], 0.0);
        linearZ = _toDouble(_latestOverride['mpu_linear_z'], 9.81);
        rotationalX = _toDouble(_latestOverride['mpu_rot_x'], 0.0);
        rotationalY = _toDouble(_latestOverride['mpu_rot_y'], 0.0);
        rotationalZ = _toDouble(_latestOverride['mpu_rot_z'], 0.0);
      } else {
        heartRate = _toDouble(_latestReal['heart_rate'], 72.0);
        spo2 = _toDouble(_latestReal['spo2'], 98.0);
        gsr = _toDouble(_latestReal['gsr'], 4.2);
        temperature = _toDouble(_latestReal['temperature'], 36.6);
        stressIndex = _toDouble(_latestReal['stress_index'], 34.0);
        fall = (_latestReal['fall'] as bool?) ?? false;
        scenario = 'Live';
        // MPU real values (from ESP32 if present, otherwise defaults)
        roll = _toDouble(_latestReal['mpu_roll'], 0.0);
        pitch = _toDouble(_latestReal['mpu_pitch'], 0.0);
        linearX = _toDouble(_latestReal['mpu_linear_x'], 0.0);
        linearY = _toDouble(_latestReal['mpu_linear_y'], 0.0);
        linearZ = _toDouble(_latestReal['mpu_linear_z'], 9.81);
        rotationalX = _toDouble(_latestReal['mpu_rot_x'], 0.0);
        rotationalY = _toDouble(_latestReal['mpu_rot_y'], 0.0);
        rotationalZ = _toDouble(_latestReal['mpu_rot_z'], 0.0);
      }

      _snapshotController.add(DeviceSnapshot(
        heartRate: heartRate,
        spo2: spo2,
        gsr: gsr,
        temperature: temperature,
        stressIndex: stressIndex,
        fall: fall,
        overrideEnabled: overrideEnabled,
        esp32Online: esp32Online,
        scenario: scenario,
        roll: roll,
        pitch: pitch,
        linearX: linearX,
        linearY: linearY,
        linearZ: linearZ,
        rotationalX: rotationalX,
        rotationalY: rotationalY,
        rotationalZ: rotationalZ,
      ));
    } catch (e) {
      debugPrint('[Firebase] emit error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADMIN PANEL — Write Methods
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setOverrideEnabled(bool enabled) async {
    try {
      await _overrideRef.update({'enabled': enabled});
      debugPrint('[Firebase] override.enabled → $enabled');
    } catch (e) {
      debugPrint('[Firebase] setOverrideEnabled error: $e');
    }
  }

  Future<void> pushOverrideScenario({
    required double heartRate,
    required double gsr,
    required double temperature,
    required double stressIndex,
    required String scenario,
    double spo2 = 98.0,
    bool fall = false,
  }) async {
    try {
      await _overrideRef.update({
        'enabled': true,
        'heart_rate': heartRate,
        'spo2': spo2,
        'gsr': gsr,
        'temperature': temperature,
        'stress_index': stressIndex,
        'fall': fall,
        'scenario': scenario,
        'updated_at': ServerValue.timestamp,
      });
      debugPrint('[Firebase] Override scenario pushed: $scenario');
    } catch (e) {
      debugPrint('[Firebase] pushOverrideScenario error: $e');
    }
  }

  Future<void> updateOverrideField(String field, double value) async {
    try {
      await _overrideRef.update({field: value, 'enabled': true});
    } catch (e) {
      debugPrint('[Firebase] updateOverrideField error: $e');
    }
  }

  /// Push all 8 MPU6050 override values at once.
  Future<void> updateMpuOverride({
    required double roll,
    required double pitch,
    required double linearX,
    required double linearY,
    required double linearZ,
    required double rotationalX,
    required double rotationalY,
    required double rotationalZ,
  }) async {
    try {
      await _overrideRef.update({
        'enabled': true,
        'mpu_roll': roll,
        'mpu_pitch': pitch,
        'mpu_linear_x': linearX,
        'mpu_linear_y': linearY,
        'mpu_linear_z': linearZ,
        'mpu_rot_x': rotationalX,
        'mpu_rot_y': rotationalY,
        'mpu_rot_z': rotationalZ,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[Firebase] updateMpuOverride error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ESP32 — Write real sensor data
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> pushRealSensorData({
    required double heartRate,
    required double gsr,
    required double temperature,
    required double stressIndex,
    double spo2 = 98.0,
    bool fall = false,
    // MPU6050 fields (optional — only present if ESP32 sends them)
    double roll = 0.0,
    double pitch = 0.0,
    double linearX = 0.0,
    double linearY = 0.0,
    double linearZ = 9.81,
    double rotationalX = 0.0,
    double rotationalY = 0.0,
    double rotationalZ = 0.0,
  }) async {
    try {
      await _realDataRef.update({
        'heart_rate': heartRate,
        'spo2': spo2,
        'gsr': gsr,
        'temperature': temperature,
        'stress_index': stressIndex,
        'fall': fall,
        'esp32_online': true,
        'mpu_roll': roll,
        'mpu_pitch': pitch,
        'mpu_linear_x': linearX,
        'mpu_linear_y': linearY,
        'mpu_linear_z': linearZ,
        'mpu_rot_x': rotationalX,
        'mpu_rot_y': rotationalY,
        'mpu_rot_z': rotationalZ,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[Firebase] pushRealSensorData error: $e');
    }
  }

  Future<void> setEsp32Online(bool online) async {
    try {
      await _connectionRef.update({'esp32_online': online});
    } catch (e) {
      debugPrint('[Firebase] setEsp32Online error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _seedDefaults() async {
    try {
      final realSnap = await _realDataRef.get();
      if (!realSnap.exists) {
        await _realDataRef.set({
          'heart_rate': 72.0,
          'spo2': 98.0,
          'gsr': 4.2,
          'temperature': 36.6,
          'stress_index': 34.0,
          'fall': false,
          'esp32_online': false,
          'mpu_roll': 0.0,
          'mpu_pitch': 0.0,
          'mpu_linear_x': 0.0,
          'mpu_linear_y': 0.0,
          'mpu_linear_z': 9.81,
          'mpu_rot_x': 0.0,
          'mpu_rot_y': 0.0,
          'mpu_rot_z': 0.0,
          'updated_at': ServerValue.timestamp,
        });
      }

      final overSnap = await _overrideRef.get();
      if (!overSnap.exists) {
        await _overrideRef.set({
          'enabled': false,
          'heart_rate': 72.0,
          'spo2': 98.0,
          'gsr': 4.2,
          'temperature': 36.6,
          'stress_index': 34.0,
          'fall': false,
          'scenario': 'Calm',
          'mpu_roll': 0.0,
          'mpu_pitch': 0.0,
          'mpu_linear_x': 0.0,
          'mpu_linear_y': 0.0,
          'mpu_linear_z': 9.81,
          'mpu_rot_x': 0.0,
          'mpu_rot_y': 0.0,
          'mpu_rot_z': 0.0,
        });
      }
    } catch (e) {
      debugPrint('[Firebase] seedDefaults error (offline?): $e');
    }
  }

  double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  void dispose() {
    _realDataSub?.cancel();
    _overrideSub?.cancel();
    _snapshotController.close();
  }
}
