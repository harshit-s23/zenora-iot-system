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

    // Listen to real_data node
    _realDataSub = _realDataRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        _latestReal = Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      _emit();
    }, onError: (e) {
      debugPrint('[Firebase] real_data listen error: $e');
    });

    // Listen to override node
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

      if (overrideEnabled) {
        // Use admin-set override values
        heartRate = _toDouble(_latestOverride['heart_rate'], 72.0);
        spo2 = _toDouble(_latestOverride['spo2'], 98.0);
        gsr = _toDouble(_latestOverride['gsr'], 4.2);
        temperature = _toDouble(_latestOverride['temperature'], 36.6);
        stressIndex = _toDouble(_latestOverride['stress_index'], 34.0);
        fall = (_latestOverride['fall'] as bool?) ?? false;
        scenario = (_latestOverride['scenario'] as String?) ?? 'Calm';
      } else {
        // Use real ESP32 sensor values
        heartRate = _toDouble(_latestReal['heart_rate'], 72.0);
        spo2 = _toDouble(_latestReal['spo2'], 98.0);
        gsr = _toDouble(_latestReal['gsr'], 4.2);
        temperature = _toDouble(_latestReal['temperature'], 36.6);
        stressIndex = _toDouble(_latestReal['stress_index'], 34.0);
        fall = (_latestReal['fall'] as bool?) ?? false;
        scenario = 'Live';
      }

      // ✅ All 9 required fields passed — no missing parameters
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
