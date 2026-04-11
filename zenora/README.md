# 🧠 Zenora — Health Intelligence App

A Flutter app for real-time stress monitoring using an ESP32 wearable device.

---

## 📱 Screens

| Screen | Description |
|--------|-------------|
| **Home** | Real-time stress index gauge + smart recommendations |
| **Monitor** | Live HR, GSR, Body Temp graphs and waveforms |
| **Exercises** | 12 science-backed stress reduction practices with timers |
| **Stats** | Daily / Weekly / Monthly stress analytics & patterns |
| **Profile** | User info, device status, emergency contacts, settings |

---

## 🚀 Quick Setup

### Prerequisites
- Flutter SDK ≥ 3.1.0 ([install](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code with Flutter plugin
- Android phone (Developer Mode ON) or Android Emulator

### Steps

```bash
# 1. Navigate to project
cd zenora

# 2. Install dependencies
flutter pub get

# 3. Create assets folder
mkdir -p assets/images

# 4. Run on connected device
flutter run

# 5. Build APK for sideloading
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔐 Admin / Demo Panel

**Purpose:** Manipulate sensor data for prototype demonstrations.

**How to access:**
1. Go to **Profile** tab
2. Tap the profile avatar **7 times quickly** (within 3 seconds)
3. Enter PIN: **`2580`**

**Features:**
- Toggle Demo Mode on/off
- One-tap scenario presets: Calm → Very High Stress
- Manual sliders for Stress Index, Heart Rate, GSR, Temperature
- Live preview of how the app will display the values

> ⚠️ Demo mode shows an orange dot on the Profile nav icon as a reminder.

---

## 🔌 Hardware Integration (ESP32)

See `lib/services/hardware_service.dart` for complete wiring and code.

### Quick steps:
1. Wire sensors to ESP32 (HR, GSR, Temperature, optional Accelerometer)
2. Flash `ESP32_firmware.ino` (sketch in hardware_service.dart comments)
3. Update IP address in `WifiHardwareService._esp32Ip`
4. In `AppProvider`, call `startHardware()` to begin polling

### Sensor connections:
```
Pulse Sensor  → GPIO 36
GSR Sensor    → GPIO 34
DS18B20 Temp  → GPIO 4 (+ 4.7kΩ pull-up)
MPU6050 IMU   → SDA:21, SCL:22, INT:2
```

---

## 📋 Dependencies

```yaml
fl_chart: ^0.68.0       # Charts & graphs
provider: ^6.1.2        # State management
shared_preferences: ^2.2.3  # Local storage
percent_indicator: ^4.2.3   # Progress bars
intl: ^0.19.0           # Date formatting
```

Add for hardware integration:
```yaml
http: ^1.2.1            # WiFi polling
flutter_blue_plus: ^1.31.0  # BLE alternative
```

---

## 🔮 Future Scope (Planned)

### 1. AI Chat Assistant
- Tab: "AI" in bottom nav
- Uses Claude API or GPT-4 for personalized stress guidance
- Sends current stress readings as context

### 2. Fall Detection + SMS Alerts
- MPU6050 accelerometer on ESP32 detects falls
- ESP32 sends `POST /fall` to Flutter via HTTP
- Flutter sends SMS to 2 emergency contacts
- Use `telephony` or `sms_advanced` Flutter package

### 3. Historical Data Sync
- Store all readings in SQLite (`sqflite` package)
- Export to CSV for medical review
- Cloud sync option (Firebase)

---

## 📁 Project Structure

```
lib/
├── main.dart                   # Entry point + bottom navigation
├── theme/
│   └── app_theme.dart          # Colors, styles, stress colors
├── providers/
│   └── app_provider.dart       # State management + demo mode
├── screens/
│   ├── home_screen.dart        # Stress gauge + recommendations
│   ├── monitor_screen.dart     # Live biometrics
│   ├── exercises_screen.dart   # Exercise library + timer
│   ├── stats_screen.dart       # Analytics dashboard
│   ├── profile_screen.dart     # User profile + settings
│   └── admin_screen.dart       # 🔒 Demo/admin panel
├── widgets/
│   ├── stress_gauge.dart       # Custom circular gauge painter
│   └── heart_rate_graph.dart   # fl_chart wrappers
└── services/
    └── hardware_service.dart   # ESP32 WiFi/BLE integration stub
```

---

## 🎨 Design

- **Background:** `#080D1A` (deep navy)
- **Cards:** `#0F1828`
- **Accent Cyan:** `#00E5FF`
- **Accent Green:** `#00FF88`
- **Stress Colors:** Green → Cyan → Yellow → Orange → Red

---

*Built for Final Year Project Prototype — Zenora Health Intelligence*
