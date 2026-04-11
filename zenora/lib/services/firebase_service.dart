// ════════════════════════════════════════════════════════════════════════════
// lib/services/firebase_service.dart
//
// PURPOSE: Single point of contact for ALL Firebase Realtime Database ops.
//          - Publishes real-time streams that AppProvider listens to.
//          - Admin panel uses push methods to write overrides.
//          - ESP32 writes to /device_1/real_data via HTTP REST.
//
// DATABASE STRUCTURE:
//   /device_1/
//     real_data/
//       heart_rate:    82.0      ← written by ESP32
//       gsr:           6.5
//       temperature:   36.8
//       stress_index:  58.0
//       updated_at:    1712345678
//     override/
//       enabled:       false     ← admin toggle
//       heart_rate:    120.0     ← admin slider values
//       gsr:           12.0
//       temperature:   37.8
//       stress_index:  85.0
//       scenario:      "High Stress"
//     connection/
//       esp32_online:  true      ← ESP32 heartbeat flag
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Snapshot of one complete device state resolved from Firebase.
class DeviceSnapshot {
  final double heartRate;
  final double gsr;
  final double temperature;
  final double stressIndex;
  final bool overrideEnabled;
  final bool esp32Online;
  final String scenario;

  const DeviceSnapshot({
    required this.heartRate,
    required this.gsr,
    required this.temperature,
    required this.stressIndex,
    required this.overrideEnabled,
    required this.esp32Online,
    this.scenario = 'Calm',
  });

  /// Fallback when Firebase is unreachable
  factory DeviceSnapshot.fallback() => const DeviceSnapshot(
        heartRate: 72,
        gsr: 4.2,
        temperature: 36.6,
        stressIndex: 34,
        overrideEnabled: false,
        esp32Online: false,
      );
}

class FirebaseService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // ── Device ID (change per deployment if multi-device) ─────────────────────
  static const String _deviceId = 'device_1';

  // ── Database references ───────────────────────────────────────────────────
  late final DatabaseReference _rootRef;
  late final DatabaseReference _realDataRef;
  late final DatabaseReference _overrideRef;
  late final DatabaseReference _connectionRef;

  bool _initialized = false;

  // ── Stream controller: broadcasts merged snapshots to AppProvider ──────────
  final _snapshotController =
      StreamController<DeviceSnapshot>.broadcast();

  Stream<DeviceSnapshot> get deviceStream => _snapshotController.stream;

  // ── Internal subscriptions (kept to cancel on dispose) ───────────────────
  StreamSubscription? _realDataSub;
  StreamSubscription? _overrideSub;

  // ── Last known values (merged on each Firebase event) ────────────────────
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

    // ── Ensure database structure exists with defaults ────────────────────
    _seedDefaults();

    // ── Listen to real_data node ──────────────────────────────────────────
    _realDataSub = _realDataRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        _latestReal =
            Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      _emit();
    }, onError: (e) {
      debugPrint('[Firebase] real_data listen error: $e');
    });

    // ── Listen to override node ───────────────────────────────────────────
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
      final overrideEnabled =
          (_latestOverride['enabled'] as bool?) ?? false;
      final esp32Online =
          (_latestReal['esp32_online'] as bool?) ?? false;

      double heartRate, gsr, temperature, stressIndex;
      String scenario;

      if (overrideEnabled) {
        // ── Use admin-set override values ─────────────────────────────────
        heartRate = _toDouble(_latestOverride['heart_rate'], 72);
        gsr = _toDouble(_latestOverride['gsr'], 4.2);
        temperature = _toDouble(_latestOverride['temperature'], 36.6);
        stressIndex = _toDouble(_latestOverride['stress_index'], 34);
        scenario = (_latestOverride['scenario'] as String?) ?? 'Calm';
      } else {
        // ── Use real ESP32 sensor values ──────────────────────────────────
        heartRate = _toDouble(_latestReal['heart_rate'], 72);
        gsr = _toDouble(_latestReal['gsr'], 4.2);
        temperature = _toDouble(_latestReal['temperature'], 36.6);
        stressIndex = _toDouble(_latestReal['stress_index'], 34);
        scenario = 'Live';
      }

      _snapshotController.add(DeviceSnapshot(
        heartRate: heartRate,
        gsr: gsr,
        temperature: temperature,
        stressIndex: stressIndex,
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

  /// Toggle override on/off — instantly reflects on ALL devices
  Future<void> setOverrideEnabled(bool enabled) async {
    try {
      await _overrideRef.update({'enabled': enabled});
      debugPrint('[Firebase] override.enabled → $enabled');
    } catch (e) {
      debugPrint('[Firebase] setOverrideEnabled error: $e');
    }
  }

  /// Push a complete scenario to override node
  Future<void> pushOverrideScenario({
    required double heartRate,
    required double gsr,
    required double temperature,
    required double stressIndex,
    required String scenario,
  }) async {
    try {
      await _overrideRef.update({
        'enabled': true,
        'heart_rate': heartRate,
        'gsr': gsr,
        'temperature': temperature,
        'stress_index': stressIndex,
        'scenario': scenario,
        'updated_at': ServerValue.timestamp,
      });
      debugPrint('[Firebase] Override scenario pushed: $scenario');
    } catch (e) {
      debugPrint('[Firebase] pushOverrideScenario error: $e');
    }
  }

  /// Push individual field update (called from sliders)
  Future<void> updateOverrideField(String field, double value) async {
    try {
      await _overrideRef.update({field: value, 'enabled': true});
    } catch (e) {
      debugPrint('[Firebase] updateOverrideField error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ESP32 — Write real sensor data (also callable from Flutter for testing)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> pushRealSensorData({
    required double heartRate,
    required double gsr,
    required double temperature,
    required double stressIndex,
  }) async {
    try {
      await _realDataRef.update({
        'heart_rate': heartRate,
        'gsr': gsr,
        'temperature': temperature,
        'stress_index': stressIndex,
        'esp32_online': true,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[Firebase] pushRealSensorData error: $e');
    }
  }

  /// ESP32 heartbeat — marks device online
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

  /// Seed default structure so new databases start with valid values
  Future<void> _seedDefaults() async {
    try {
      final realSnap = await _realDataRef.get();
      if (!realSnap.exists) {
        await _realDataRef.set({
          'heart_rate': 72.0,
          'gsr': 4.2,
          'temperature': 36.6,
          'stress_index': 34.0,
          'esp32_online': false,
          'updated_at': ServerValue.timestamp,
        });
      }

      final overSnap = await _overrideRef.get();
      if (!overSnap.exists) {
        await _overrideRef.set({
          'enabled': false,
          'heart_rate': 72.0,
          'gsr': 4.2,
          'temperature': 36.6,
          'stress_index': 34.0,
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

// ════════════════════════════════════════════════════════════════════════════
// ESP32 ARDUINO CODE — sends data to Firebase REST API
// Paste this in your ESP32 firmware
// ════════════════════════════════════════════════════════════════════════════
/*

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Get this from Firebase Console → Project Settings → General → Web API Key
const char* FIREBASE_HOST = "YOUR_PROJECT_ID.firebaseio.com";
// Your database secret (Firebase → Project Settings → Service accounts)
const char* FIREBASE_SECRET = "YOUR_DATABASE_SECRET";

// Sensor pins
#define GSR_PIN   34
#define TEMP_PIN  35   // Use appropriate library for your sensor

HTTPClient http;

float readHeartRate() {
  // Replace with your pulse sensor library read
  return 72.0 + random(-5, 5);
}

float readGSR() {
  int raw = analogRead(GSR_PIN);
  return raw * (15.0 / 4095.0);  // Normalize to 0-15 µS
}

float readTemperature() {
  // Replace with DS18B20 / MLX90614 library read
  return 36.6 + (random(-5, 5) / 10.0);
}

float computeStress(float hr, float gsr, float temp) {
  float hrNorm   = constrain(map(hr,   60, 120, 0, 100), 0, 100);
  float gsrNorm  = constrain(map(gsr,  1,  15,  0, 100), 0, 100);
  float tempNorm = constrain(map(temp * 10, 360, 385, 0, 100), 0, 100);
  return (hrNorm * 0.4) + (gsrNorm * 0.4) + (tempNorm * 0.2);
}

void sendToFirebase(float hr, float gsr, float temp, float stress) {
  String url = "https://" + String(FIREBASE_HOST) +
               "/device_1/real_data.json?auth=" + FIREBASE_SECRET;

  StaticJsonDocument<256> doc;
  doc["heart_rate"]   = hr;
  doc["gsr"]          = gsr;
  doc["temperature"]  = temp;
  doc["stress_index"] = stress;
  doc["esp32_online"] = true;

  String payload;
  serializeJson(doc, payload);

  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  int code = http.PATCH(payload);   // PATCH updates only specified fields
  http.end();

  Serial.printf("Firebase PUT: %d | HR:%.1f GSR:%.1f T:%.1f S:%.1f\n",
                code, hr, gsr, temp, stress);
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500); Serial.print(".");
  }
  Serial.println("\nWiFi connected: " + WiFi.localIP().toString());
}

void loop() {
  float hr    = readHeartRate();
  float gsr   = readGSR();
  float temp  = readTemperature();
  float stress = computeStress(hr, gsr, temp);

  sendToFirebase(hr, gsr, temp, stress);
  delay(1000);   // Send every 1 second
}

*/
