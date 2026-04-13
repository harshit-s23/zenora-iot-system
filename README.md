<div align="center">

# Zenora — *Stress Less, Live More*

**AI-Powered Wearable Stress Management System**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime_DB-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![ESP32](https://img.shields.io/badge/ESP32-IoT_Core-E7352C?style=for-the-badge&logo=espressif&logoColor=white)](https://www.espressif.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Top 25 — Agnels Tech Mania 2026** | 24-Hour National-Level Hackathon | IETE-ETSA Council

---

*Zenora is a real-time, AI-driven stress monitoring and relief system combining an ESP32-powered wearable wristband with a Flutter mobile app. It continuously tracks physiological signals, predicts rising stress levels, and delivers adaptive pressure therapy — all without requiring user interruption.*

</div>

---

## Table of Contents

- [Problem Statement](#-problem-statement)
- [Proposed Solution](#-proposed-solution)
- [System Architecture](#-system-architecture)
- [Hardware Components](#-hardware-components)
- [Flutter App Features](#-flutter-app-features)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Firebase Setup](#-firebase-setup)
- [ESP32 Integration](#-esp32-integration)
- [Team](#-team)

---

## Problem Statement

Healthcare professionals and knowledge workers operate under extreme, sustained stress — yet there is **no real-time, non-intrusive system** capable of continuously monitoring and managing their stress levels.

Current limitations:
- **No real-time monitoring** — stress goes undetected until it's too late
- **Intrusive systems** — existing wearables are bulky and uncomfortable for clinical shifts
- **Lack of personalization** — generic thresholds, no user-specific adaptation
- **Delayed or no intervention** — data is collected but actionable relief is absent

The downstream consequences include burnout syndrome, medical errors, hormonal disruption, cardiovascular risk, and systemic workplace failures.

---

## Proposed Solution

Zenora combines a **lightweight ESP32 wristband** with a **Flutter mobile app** to form a closed-loop stress management system that follows a simple pipeline:

```
Monitor → Predict → Alert → Act → Analyze → Personalize → Outcome
```

| Stage | What Happens |
|---|---|
| **Monitor** | Heart Rate (MAX30102) + GSR sensor capture continuous physiological data |
| **Predict** | Edge AI on ESP32 runs threshold + pattern-based stress prediction |
| **Alert** | Vibration motor triggers an immediate haptic alert |
| **Act** | Haptic Sensor applies controlled pressure therapy to the wrist |
| **Analyze** | Data is transmitted via WiFi to Firebase for cloud-based tracking |
| **Personalize** | App delivers user-specific feedback, breathing exercises, and AI chat |
| **Outcome** | Burnout prevention, improved performance, and enhanced patient safety |

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      WEARABLE (ESP32)                       │
│                                                             │
│  MAX30102 ──┐                                               │
│  GSR Sensor ├──► ESP32 Controller ──► Stress Algorithm     │
│  MPU6050   ──┤         │                    │               │
│  Temp Sensor┘          │             ┌──────┴──────┐        │
│                        │             │  Alert      │        │
│                   WiFi/BLE           │  Vibration  │        │
│                        │             │  RGB LED    │        │
│                        ▼             │  Servo      │        │
│               Firebase Realtime DB   └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   FLUTTER MOBILE APP                        │
│                                                             │
│  HomeScreen ── MonitorScreen ── ExercisesScreen             │
│  StatsScreen ── ProfileScreen ── ChatScreen (AI)            │
│                                                             │
│  Services:                                                  │
│  FirebaseService | HardwareService | EmergencyService       │
│  FallDetectionService | PressureTherapyService              │
└─────────────────────────────────────────────────────────────┘
```

**Data Flow:**
1. ESP32 reads sensors every ~1 second
2. Calculates stress index on-device
3. Publishes JSON (`hr`, `gsr`, `temp`, `stress`, `fall`) to Firebase Realtime DB
4. Flutter app subscribes to Firebase and updates UI in real-time
5. On high stress → haptic alert on phone + servo activation on wristband
6. Emergency fall detection → SMS + GPS location alert to emergency contacts

---

## Hardware Components

### Sensors
| Component | Purpose |
|---|---|
| **MAX30102** | Heart rate & SpO2 (cardiovascular data) |
| **GSR Sensor** | Galvanic skin response / electrodermal activity (stress detection) |
| **MPU6050** | 6-axis IMU for motion tracking and fall detection |
| **Temperature Sensor** | Body heat variation tracking |

### Core & Power
| Component | Purpose |
|---|---|
| **ESP32** | Low-power WiFi/BLE processing core |
| **Li-ion Battery** | Portable continuous operation (24+ hr) |
| **TP4056** | Charge management & protection circuit |

### Actuators
| Component | Purpose |
|---|---|
| **Vibration Motor** | Immediate haptic stress alert |
| **SG90 Micro Servo Motor** | Adaptive pressure therapy mechanism |
| **Pressure Pads** | Comfortable, distributed wrist pressure |

---

## Flutter App Features

### Home Screen
- Real-time Stress Index gauge (0–100 scale with Calm / Moderate / High zones)
- Live heart rate monitor with animated waveform
- Quick-access stress relief shortcuts

### Monitor Screen
- Real-time biometric graphs: Heart Rate, GSR, Temperature, Motion
- AI Prediction overlay on the timeline
- Live connection status (ESP32 / Firebase)

### Alert Screen
- High stress detected notification with recommended actions
- One-tap **Activate Pressure Therapy** (sends command to ESP32 servo)
- One-tap **Start Guided Breathing** (4-7-8 technique with timer)
- Emergency Mode toggle

### AI Chat Screen
- Conversational AI companion for mental wellness support
- Quick-action chips: Breathing, Talk mode, Relax Tips
- Contextual suggestions based on current stress readings

### Stats Screen
- Day / Week / Month stress trend charts
- Stress causes breakdown (Work, Sleep, Health, Personal)
- Weekly average with percentage change indicator

### Profile Screen
- User role configuration (Healthcare Professional, etc.)
- Emergency contact management (2 contacts for fall alerts)
- Demo mode toggle for testing without hardware

### Exercises Screen
- Guided breathing exercises
- Stress-relief exercises and stretches

### Emergency & Fall Detection
- MPU6050-based fall detection with auto SMS alert
- GPS coordinates sent as Google Maps link to emergency contacts
- 10-second countdown before alert fires (allows cancellation)

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter 3.x (Dart) |
| **State Management** | Provider |
| **Backend / Cloud** | Firebase Realtime Database |
| **IoT Firmware** | Arduino C++ on ESP32 |
| **Charts** | fl_chart |
| **Location** | geolocator |
| **Haptics** | vibration package |
| **Emergency** | Native MethodChannel (SMS + Call) |
| **HTTP Polling** | http package (ESP32 WiFi REST) |

---

## 📁 Project Structure

```
zenora/
├── lib/
│   ├── main.dart                    # App entry, navigation shell
│   ├── firebase_options.dart        # Firebase config (auto-generated)
│   ├── providers/
│   │   └── app_provider.dart        # Central state management
│   ├── screens/
│   │   ├── home_screen.dart         # Stress index + live HR
│   │   ├── monitor_screen.dart      # Real-time biometric graphs
│   │   ├── exercises_screen.dart    # Breathing & relaxation
│   │   ├── stats_screen.dart        # Weekly/monthly analytics
│   │   ├── profile_screen.dart      # User & emergency contacts
│   │   ├── chat_screen.dart         # AI wellness companion
│   │   └── admin_screen.dart        # Hardware override / debug
│   ├── services/
│   │   ├── firebase_service.dart    # Realtime DB subscriptions
│   │   ├── hardware_service.dart    # ESP32 WiFi / BLE integration
│   │   ├── emergency_service.dart   # Native SMS + call
│   │   ├── fall_detection_service.dart  # MPU6050 fall logic
│   │   ├── haptic_service.dart      # Vibration patterns
│   │   └── pressure_therapy_service.dart  # Servo therapy commands
│   ├── widgets/
│   │   ├── stress_gauge.dart        # Circular stress dial
│   │   ├── heart_rate_graph.dart    # Animated HR waveform
│   │   ├── pressure_therapy_card.dart
│   │   ├── fall_alert_banner.dart
│   │   ├── emergency_countdown_dialog.dart
│   │   └── data_source_badge.dart
│   └── theme/
│       └── app_theme.dart           # Dark theme tokens
├── android/                         # Android-specific config
├── ios/                             # iOS-specific config
├── FIREBASE_SETUP.md                # Firebase setup guide
└── pubspec.yaml                     # Dependencies
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.1.0
- Android Studio / VS Code with Flutter extension
- A Firebase project (free Spark plan is sufficient)
- (Optional) ESP32 hardware for live sensor data

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/zenora-iot-system.git
cd zenora-iot-system/zenora

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase (see Firebase Setup below)

# 4. Run the app
flutter run
```

> **No hardware?** The app includes a **Demo Mode** (toggle in Profile screen) that simulates realistic sensor data so you can explore all features without an ESP32.

---

## Firebase Setup

See [`FIREBASE_SETUP.md`](zenora/FIREBASE_SETUP.md) for the full guide. Quick summary:

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name `com.zenora.app`
3. Download `google-services.json` → place in `android/app/`
4. Enable **Realtime Database** and set rules to allow read/write during development
5. Run `flutterfire configure` to regenerate `firebase_options.dart`

**Expected Firebase JSON structure:**
```json
{
  "device": {
    "hr": 72,
    "gsr": 4.2,
    "temp": 36.6,
    "stress": 34,
    "spo2": 98,
    "fall": false,
    "online": true
  }
}
```

---

## ESP32 Integration

The app supports two connection modes:

### Option A: WiFi REST API (Recommended)
The ESP32 runs a lightweight HTTP server. The Flutter app polls `http://<ESP32_IP>/data` every second.

```cpp
// Paste on your ESP32 (see hardware_service.dart for full code)
void handleData() {
  String json = "{\"hr\":" + String(heartRate) +
                ",\"gsr\":" + String(gsr) +
                ",\"temp\":" + String(bodyTemp) +
                ",\"stress\":" + String(stressIndex) + "}";
  server.send(200, "application/json", json);
}
```

Update `_esp32Ip` in `lib/services/hardware_service.dart` to match your ESP32's local IP.

### Option B: Firebase Bridge
The ESP32 publishes directly to Firebase Realtime DB using the [Firebase ESP32 library](https://github.com/mobizt/Firebase-ESP32). The Flutter app then subscribes to Firebase for updates.

### Sensor Pins (default)
| Sensor | ESP32 Pin |
|---|---|
| GSR | GPIO 34 |
| Temperature | GPIO 35 |
| MAX30102 | I2C (SDA: 21, SCL: 22) |
| MPU6050 | I2C (SDA: 21, SCL: 22) |
| Servo (SG90) | GPIO 18 |
| Vibration Motor | GPIO 19 |
| RGB LED R/G/B | GPIO 25 / 26 / 27 |

---

## Team

**Team Part-time Pundits** — Agnels Tech Mania 2026

| Name | Role |
|---|---|
| **Agasthi Doshi** | Flutter App & UI , Sensors Codes  , Firebase Setup and Connections to Hardware |
| **Harshita Chavan** | Hardware Connections & Sesnors Codes , IOT Integration |
| **Isaiah Gaikwad** | Hardware Connections & Sesnors Codes , IOT Integration |
| **Harshit Singh** | Flutter App & UI , Sensors Codes , Firebase Setup and Connections to Hardware |

---

## Future Scope

- **Advanced AI Prediction** — ML models trained on larger physiological datasets for more accurate early detection
- **Personalized Therapy Modes** — Audio-guided breathing, biofeedback loops
- **Additional Sensors** — Cortisol patch integration, EEG headband
- **Cloud Analytics Dashboard** — Hospital-level monitoring for managing entire healthcare teams
- **Battery Optimization** — Deep sleep modes, energy harvesting
- **Scalability** — Cross-domain deployment: corporate, military, fitness

---

<div align="center">

Built at **Agnels Tech Mania 2026** — *Top 25 Finalist*

*"Our system doesn't just respond to stress — it predicts, prevents, and continuously adapts to protect both performance and human lives."*

</div>
