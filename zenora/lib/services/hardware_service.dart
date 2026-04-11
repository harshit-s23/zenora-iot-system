// ═══════════════════════════════════════════════════════════════════
// FILE: lib/services/hardware_service.dart
// Integrate AFTER hardware is built. Drop this file in and wire to AppProvider.
// ═══════════════════════════════════════════════════════════════════
//
// HOW TO INTEGRATE ESP32 → FLUTTER
//
// Option A: WiFi REST API (Recommended for local network)
//   ESP32 runs a simple HTTP server, Flutter polls or subscribes.
//
// Option B: BLE (Bluetooth Low Energy)
//   ESP32 acts as BLE peripheral, Flutter scans and connects.
//
// Below is a stub for BOTH approaches.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// For BLE, add: flutter_blue_plus: ^1.31.0 to pubspec.yaml
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// ── WiFi / HTTP Approach ──────────────────────────────────────────────────────
class WifiHardwareService {
  // Replace with your ESP32's IP (check Serial monitor or router)
  static const String _esp32Ip = '192.168.1.100';
  static const String _baseUrl = 'http://$_esp32Ip';

  Timer? _pollTimer;

  /// Start polling ESP32 every 1 second
  void startPolling(Function(Map<String, double>) onData) {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/data'))
            .timeout(const Duration(milliseconds: 800));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          onData({
            'heartRate': (json['hr'] as num).toDouble(),
            'gsr': (json['gsr'] as num).toDouble(),
            'bodyTemp': (json['temp'] as num).toDouble(),
            'stressIndex': (json['stress'] as num).toDouble(),
          });
        }
      } catch (e) {
        debugPrint('ESP32 connection error: $e');
      }
    });
  }

  void stop() => _pollTimer?.cancel();
}

// ── ESP32 Arduino Code (for your hardware team) ────────────────────────────
/*
PASTE THIS ON YOUR ESP32:

#include <WiFi.h>
#include <WebServer.h>

const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

WebServer server(80);

// Your sensor pins
#define GSR_PIN 34
#define TEMP_PIN 35
#define HR_PIN 36

float heartRate = 72.0;
float gsr = 4.2;
float bodyTemp = 36.6;
float stressIndex = 34.0;

void handleData() {
  // Build JSON with sensor readings
  String json = "{";
  json += "\"hr\":" + String(heartRate, 1) + ",";
  json += "\"gsr\":" + String(gsr, 2) + ",";
  json += "\"temp\":" + String(bodyTemp, 1) + ",";
  json += "\"stress\":" + String(stressIndex, 1);
  json += "}";
  
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", json);
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected: " + WiFi.localIP().toString());
  
  server.on("/data", handleData);
  server.begin();
}

void loop() {
  server.handleClient();
  
  // Replace with your actual sensor reads:
  // heartRate = readHeartRate();
  // gsr = analogRead(GSR_PIN) * (3.3/4095.0) * 10;
  // bodyTemp = readTemperature();
  // stressIndex = computeStress(heartRate, gsr, bodyTemp);
  
  delay(100);
}
*/

// ── Wiring instructions ────────────────────────────────────────────────────
/*
ESP32 SENSOR WIRING:

PULSE SENSOR (Heart Rate):
  Signal → GPIO 36 (VP / ADC1_CH0)
  VCC    → 3.3V
  GND    → GND

GSR (Galvanic Skin Response):
  Analog → GPIO 34 (ADC1_CH6)
  VCC    → 3.3V
  GND    → GND
  Electrodes → tips of index and middle finger

TEMPERATURE (DS18B20 or MLX90614 IR):
  DS18B20: Data → GPIO 4, VCC → 3.3V, GND → GND, 4.7kΩ pull-up
  MLX90614 (I2C): SDA → GPIO 21, SCL → GPIO 22

ACCELEROMETER (MPU6050 for fall detection):
  SDA → GPIO 21
  SCL → GPIO 22
  INT → GPIO 2
  VCC → 3.3V

STRESS INDEX CALCULATION (simplified):
  stressIndex = (hrNorm * 0.4) + (gsrNorm * 0.4) + (tempNorm * 0.2)
  Where: hrNorm = map(heartRate, 60, 120, 0, 100)
         gsrNorm = map(gsr, 1.0, 15.0, 0, 100)
         tempNorm = map(bodyTemp, 36.0, 38.5, 0, 100)
*/

// ── How to wire into AppProvider ──────────────────────────────────────────
/*
In AppProvider constructor, add:

  final _wifi = WifiHardwareService();
  
  void startHardware() {
    _wifi.startPolling((data) {
      updateSensorData(
        heartRate: data['heartRate'],
        gsr: data['gsr'],
        bodyTemp: data['bodyTemp'],
        stressIndex: data['stressIndex'],
      );
    });
  }
  
  @override
  void dispose() {
    _wifi.stop();
    super.dispose();
  }

Then call provider.startHardware() in main() or HomeScreen.initState()
when you're ready to connect to hardware.
*/
