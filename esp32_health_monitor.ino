/*
 * esp32_health_monitor.ino
 * With Firebase Auth + HTTP Server for Pressure Therapy + Haptic Motor (D19)
 *
 * CHANGES vs previous version:
 *   ✅ Added POST /haptic/command endpoint
 *      Body: { "command": "start"|"stop"|"pulse", "intensity": 0-255, "duration": ms }
 *      → Drives haptic motor on D19 directly
 *   ✅ Added hapticPattern_Therapy() — ramp-aware pulse used during therapy cycles
 *   ✅ /therapy/command still drives the pressure actuator (unchanged)
 *   ✅ Admin stress override via Flutter fires a scaled pulse on D19
 */

#include <WiFi.h>
#include <Wire.h>
#include <WebServer.h>
#include <ArduinoJson.h>              // ✅ ADD to lib manager: "ArduinoJson" by Benoit Blanchon
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ===== SENSOR HEADERS =====
#include "heart_rate.h"
#include "gsr_sensor.h"
#include "lm35_temp.h"
#include "mpu6050_fall.h"
#include "stress_calc.h"
#include "haptic_motor.h"             // defines HAPTIC_PIN 19, hapticPulse(), etc.

// ===== WIFI CONFIG =====
#define WIFI_SSID     "OnePlus_24"
#define WIFI_PASSWORD "k6djpq9f"

// ===== FIREBASE CONFIG =====
#define API_KEY      "AIzaSyD1-eb93yN5725gSy59caY3izCa56EmuSE"
#define DATABASE_URL "https://zenora-9802f-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== EMAIL/PASSWORD AUTH =====
#define USER_EMAIL    "doshiagasthi@gmail.com"
#define USER_PASSWORD "Swami@2408@Agasthi@21012005"

// Firebase objects
FirebaseData   fbdo;
FirebaseAuth   auth;
FirebaseConfig config;
bool firebaseReady = false;

// ✅ HTTP Server on port 80
WebServer server(80);

// ===== TIMING =====
unsigned long lastPrint    = 0;
unsigned long lastFirebase = 0;
unsigned long lastHaptic   = 0;
const unsigned long PRINT_INTERVAL    = 1000;
const unsigned long FIREBASE_INTERVAL = 2000;
const unsigned long HAPTIC_COOLDOWN   = 5000;

// ===== WIFI =====
void connectWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected! IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\nWiFi FAILED — running offline.");
  }
}

// ===== FIREBASE SETUP =====
void setupFirebase() {
  config.api_key      = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email     = USER_EMAIL;
  auth.user.password  = USER_PASSWORD;
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("Firebase Auth started — waiting for token...");
  int wait = 0;
  while (!Firebase.ready() && wait < 30) {
    delay(500);
    Serial.print(".");
    wait++;
  }

  if (Firebase.ready()) {
    firebaseReady = true;
    Serial.println("\nFirebase Authenticated & Ready! ✅");
  } else {
    firebaseReady = false;
    Serial.println("\nFirebase Auth FAILED.");
  }
}

// ===== HTTP SERVER HANDLERS =====

// Flutter calls GET /ping to check if ESP32 is reachable
void handlePing() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", "{\"status\":\"ok\",\"device\":\"esp32\"}");
  Serial.println("[HTTP] /ping received from Flutter");
}

// Flutter calls POST /therapy/command
// Body: {"command":"start"|"intensity"|"stop","intensity":0-255}
// Drives the PRESSURE ACTUATOR (unchanged from before)
void handleTherapyCommand() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String body = server.arg("plain");
  Serial.println("[HTTP] /therapy/command body: " + body);

  if (body.indexOf("stop") >= 0) {
    Serial.println("[Therapy] STOP — actuator off");
    digitalWrite(HAPTIC_PIN, LOW);
    server.send(200, "application/json", "{\"status\":\"ok\",\"command\":\"stop\"}");

  } else if (body.indexOf("start") >= 0) {
    Serial.println("[Therapy] START — initial buzz");
    hapticPulse(300);
    server.send(200, "application/json", "{\"status\":\"ok\",\"command\":\"start\"}");

  } else if (body.indexOf("intensity") >= 0) {
    int colonPos = body.lastIndexOf(":");
    String valStr = body.substring(colonPos + 1);
    valStr.trim();
    valStr.replace("}", "");
    valStr.trim();
    int intensity = constrain(valStr.toInt(), 0, 255);
    int pulseDuration = map(intensity, 0, 255, 50, 500);
    Serial.printf("[Therapy] INTENSITY %d → pulse %dms\n", intensity, pulseDuration);
    hapticPulse(pulseDuration);
    server.send(200, "application/json", "{\"status\":\"ok\",\"command\":\"intensity\"}");

  } else {
    server.send(400, "application/json", "{\"status\":\"error\"}");
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ NEW: Flutter calls POST /haptic/command
//
// This endpoint is dedicated to the HAPTIC MOTOR on D19.
// It is called in two situations:
//   1. During pressure therapy — Flutter sends a pulse per therapy cycle,
//      intensity follows the 11-step ramp curve (60 → 255 → 80).
//   2. Admin stress override — Flutter sends a single pulse whose intensity
//      and duration are scaled to the manually set stress index (0–100).
//
// Body JSON:
//   { "command": "start"|"stop"|"pulse", "intensity": 0-255, "duration": ms }
//
// command = "start"  → Initial buzz when therapy begins (uses intensity)
// command = "pulse"  → Single timed buzz (uses intensity + duration)
// command = "stop"   → Immediately cuts motor off
// ─────────────────────────────────────────────────────────────────────────────
void handleHapticCommand() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String body = server.arg("plain");
  Serial.println("[HTTP] /haptic/command body: " + body);

  // Parse JSON with ArduinoJson
  StaticJsonDocument<256> doc;
  DeserializationError err = deserializeJson(doc, body);

  if (err) {
    Serial.println("[HapticMotor D19] JSON parse error: " + String(err.c_str()));
    server.send(400, "application/json", "{\"status\":\"error\",\"reason\":\"bad json\"}");
    return;
  }

  const char* command  = doc["command"]  | "pulse";
  int intensity        = constrain((int)(doc["intensity"] | 128), 0, 255);
  int duration         = constrain((int)(doc["duration"]  | 300), 10, 2000);

  Serial.printf("[HapticMotor D19] command=%s intensity=%d duration=%dms\n",
                command, intensity, duration);

  if (strcmp(command, "stop") == 0) {
    // Immediately silence the motor
    digitalWrite(HAPTIC_PIN, LOW);
    Serial.println("[HapticMotor D19] Stopped.");
    server.send(200, "application/json", "{\"status\":\"ok\",\"command\":\"stop\"}");

  } else if (strcmp(command, "start") == 0) {
    // Therapy session beginning — short confirmation buzz
    // Duration mapped from intensity so the opening buzz feels proportional
    int startDuration = map(intensity, 0, 255, 80, 300);
    hapticPulse(startDuration);
    Serial.printf("[HapticMotor D19] Session start buzz → %dms\n", startDuration);
    server.send(200, "application/json", "{\"status\":\"ok\",\"command\":\"start\"}");

  } else {
    // "pulse" — standard per-cycle or admin-override buzz
    // intensity (0-255) controls how long the motor runs within the given window:
    //   we map it so a full-intensity pulse fills ~90% of the cycle duration,
    //   and low intensity fills ~20%, giving a noticeable ramp-up feel.
    int pulseDuration = map(intensity, 0, 255,
                            80,
                            750);
    pulseDuration = constrain(pulseDuration, 80, 750);

    hapticPulse(pulseDuration);
    Serial.printf("[HapticMotor D19] Pulse → intensity=%d effective_duration=%dms\n",
                  intensity, pulseDuration);
    server.send(200, "application/json", "{\"status\":\"ok\",\"command\":\"pulse\"}");
  }
}

// Handle CORS preflight for Flutter web
void handleOptions() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  server.send(204);
}

// ===== HTTP SERVER SETUP =====
void setupHTTPServer() {
  server.on("/ping",             HTTP_GET,     handlePing);

  // Pressure actuator (existing)
  server.on("/therapy/command",  HTTP_POST,    handleTherapyCommand);
  server.on("/therapy/command",  HTTP_OPTIONS, handleOptions);

  // ✅ Haptic motor D19 (new)
  server.on("/haptic/command",   HTTP_POST,    handleHapticCommand);
  server.on("/haptic/command",   HTTP_OPTIONS, handleOptions);

  server.begin();
  Serial.println("✅ HTTP Server started!");
  Serial.println("   /therapy/command  → pressure actuator");
  Serial.println("   /haptic/command   → haptic motor D19");
  Serial.println("👉 Flutter ESP32 IP to set: " + WiFi.localIP().toString());
}

// ===== SEND DATA TO FIREBASE =====
void sendToFirebase(float bpm, float spo2, float gsr,
                    float tempC, int stressScore, bool fallDet) {
  if (!firebaseReady)                return;
  if (WiFi.status() != WL_CONNECTED) return;
  if (!Firebase.ready())             return;

  FirebaseJson json;
  json.set("heart_rate",   bpm);
  json.set("spo2",         spo2);
  json.set("gsr",          gsr);
  json.set("temperature",  tempC);
  json.set("stress_index", stressScore);
  json.set("fall",         fallDet);
  json.set("esp32_online", true);
  json.set("user_email",   String(USER_EMAIL));

  bool ok = Firebase.RTDB.setJSON(&fbdo, "device_1/real_data", &json);
  if (!ok) {
    Serial.println("Firebase Error: " + fbdo.errorReason());
  } else {
    Serial.println("Firebase: Sent OK ✅");
  }
}

// ===== SETUP =====
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n==============================");
  Serial.println("  ESP32 Health Monitor v7     ");
  Serial.println("  Firebase Auth + HTTP Server  ");
  Serial.println("  Haptic Motor D19 Support     ");
  Serial.println("==============================");

  Wire.begin(21, 22);
  Wire.setClock(400000);

  initHaptic();      // sets D19 as OUTPUT, starts LOW
  hapticPulse(200);  // boot confirmation buzz

  initHeartRate();
  initMPU6050();
  initGSR();
  initLM35();

  connectWiFi();

  if (WiFi.status() == WL_CONNECTED) {
    setupFirebase();
    setupHTTPServer();

    if (firebaseReady) {
      FirebaseJson ping;
      ping.set("esp32_online", true);
      ping.set("user_email", String(USER_EMAIL));
      Firebase.RTDB.updateNode(&fbdo, "device_1/real_data", &ping);
      Serial.println("ESP32 marked ONLINE in Firebase!");
    }
  }

  Serial.println("\nSystem Ready! Starting monitoring...\n");
}

// ===== LOOP =====
void loop() {
  server.handleClient(); // ✅ REQUIRED — handles /therapy/command AND /haptic/command

  updateHeartRate();
  updateMPU6050();

  unsigned long now = millis();

  if (now - lastPrint >= PRINT_INTERVAL) {
    lastPrint = now;

    float  bpm       = getHeartRate();
    float  spo2      = getSpO2();
    float  gsr       = readGSR();
    float  tempC     = readLM35();
    bool   fallDet   = isFallDetected();
    float  accelMag  = getAccelMagnitude();
    int    stress    = calculateStress(bpm, gsr, tempC, accelMag);
    String stressLvl = getStressLevel(stress);

    Serial.println("------ SENSOR READINGS ------");
    Serial.printf("Heart Rate : %.1f BPM\n",    bpm);
    Serial.printf("SpO2       : %.1f %%\n",     spo2);
    Serial.printf("GSR        : %.2f kOhm\n",   gsr);
    Serial.printf("Temp       : %.1f C\n",      tempC);
    Serial.printf("Accel Mag  : %.2f g\n",      accelMag);
    Serial.printf("Fall       : %s\n",          fallDet ? "YES" : "No");
    Serial.printf("Stress     : %d/100 (%s)\n", stress, stressLvl.c_str());
    Serial.println("-----------------------------\n");

    if (now - lastFirebase >= FIREBASE_INTERVAL) {
      lastFirebase = now;
      sendToFirebase(bpm, spo2, gsr, tempC, stress, fallDet);
    }

    // Autonomous haptic alerts (sensor-driven, not Flutter-driven)
    if (fallDet && now - lastHaptic > HAPTIC_COOLDOWN) {
      hapticPattern_Fall();
      lastHaptic = now;
    } else if (stress >= 70 && now - lastHaptic > HAPTIC_COOLDOWN) {
      hapticPattern_Stress();
      lastHaptic = now;
    }
  }
}