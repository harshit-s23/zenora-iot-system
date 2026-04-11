# 🔥 Zenora — Firebase Setup Guide
## Complete Step-by-Step Instructions

---

## PHASE 1 — Firebase Console Setup (5 minutes)

### Step 1: Create Firebase Project
1. Go to → https://console.firebase.google.com
2. Click **"Add Project"**
3. Name it: `zenora-health` (or anything you like)
4. Disable Google Analytics (not needed)
5. Click **"Create Project"**

### Step 2: Enable Realtime Database
1. In left sidebar → **"Build"** → **"Realtime Database"**
2. Click **"Create Database"**
3. Choose location: **Asia South (asia-south1)** (closest to India)
4. Start in **"Test mode"** (for hackathon demo — allows all reads/writes)
5. Click **"Enable"**

### Step 3: Note Your Database URL
After creation, you'll see a URL like:
```
https://zenora-health-default-rtdb.asia-southeast1.firebaseio.com
```
Copy this — you'll need it in Step 7.

### Step 4: Add Android App to Firebase
1. In Firebase Console → Project Overview → click **Android icon** (</>)
2. Android package name: `com.zenora.app`
   (must match `applicationId` in `android/app/build.gradle`)
3. App nickname: `Zenora Android`
4. Click **"Register App"**
5. **Download `google-services.json`**
6. Place it at: `android/app/google-services.json`

---

## PHASE 2 — Android Gradle Config (3 minutes)

### Step 5: Update `android/build.gradle`
Find the `dependencies {}` block inside `buildscript {}` and add:
```gradle
buildscript {
    dependencies {
        // ... existing lines ...
        classpath 'com.google.gms:google-services:4.4.2'   // ADD THIS
    }
}
```

### Step 6: Update `android/app/build.gradle`
At the very **top** of the file, add:
```gradle
apply plugin: 'com.google.gms.google-services'   // ADD THIS LINE AT TOP
```

Also confirm your `defaultConfig` has:
```gradle
defaultConfig {
    applicationId "com.zenora.app"    // must match Firebase package name
    minSdkVersion 21                  // Firebase requires min 21
    ...
}
```

---

## PHASE 3 — FlutterFire CLI (2 minutes)

### Step 7: Install FlutterFire CLI and configure
```bash
# Install the CLI globally
dart pub global activate flutterfire_cli

# In your project root (zenora/ folder):
flutterfire configure --project=zenora-health
```

When prompted:
- Select platforms: **Android** (and iOS if needed)
- This auto-generates `lib/firebase_options.dart` with your real API keys
- It also auto-updates the Android gradle files if not done in Phase 2

### Step 8: Install dependencies
```bash
flutter pub get
```

---

## PHASE 4 — Verify Database Structure

### Step 9: Seed initial data (optional — app does this automatically)
In Firebase Console → Realtime Database → click the **+** icon at root:

```json
{
  "device_1": {
    "real_data": {
      "heart_rate": 72.0,
      "gsr": 4.2,
      "temperature": 36.6,
      "stress_index": 34.0,
      "esp32_online": false
    },
    "override": {
      "enabled": false,
      "heart_rate": 72.0,
      "gsr": 4.2,
      "temperature": 36.6,
      "stress_index": 34.0,
      "scenario": "Calm"
    }
  }
}
```

---

## PHASE 5 — Run & Test

### Step 10: Run the app
```bash
flutter run
```

### Step 11: Test real-time sync
1. Install the app on **TWO phones** (or emulator + phone)
2. On Phone A: go to Profile → tap avatar 7 times → PIN: `2580` → Admin Panel
3. On Phone B: watch the home screen
4. On Phone A: tap **"High Stress"** scenario
5. Phone B should update within ~200ms ✅

---

## PHASE 6 — ESP32 Integration

### Step 12: Get Firebase Database Secret
1. Firebase Console → Project Settings → **Service Accounts** tab
2. Scroll to **"Database secrets"** → Show / Create a secret
3. Copy the secret key

### Step 13: Flash ESP32
Open `lib/services/firebase_service.dart` — scroll to the bottom.
Copy the Arduino code in the `/* ... */` comment block.
Replace:
```cpp
const char* FIREBASE_HOST = "YOUR_PROJECT_ID-default-rtdb.firebaseio.com";
const char* FIREBASE_SECRET = "YOUR_DATABASE_SECRET";
const char* WIFI_SSID = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
```

Flash to ESP32 and check Serial Monitor for:
```
WiFi connected: 192.168.x.x
Firebase PUT: 200 | HR:75.2 GSR:4.1 T:36.7 S:42.3
```

---

## Database Rules for Production
When done with demo, tighten rules in Firebase Console:
```json
{
  "rules": {
    "device_1": {
      "real_data": {
        ".read": true,
        ".write": true
      },
      "override": {
        ".read": true,
        ".write": true
      }
    }
  }
}
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `Firebase: no app` | Check `google-services.json` is at `android/app/` |
| `DatabaseException` | Check database URL matches region in `firebase_options.dart` |
| Override not syncing | Check Firebase rules allow write, check internet on both phones |
| ESP32 PUT returns 401 | Database secret is wrong |
| ESP32 PUT returns 404 | Database URL is wrong |
| App works offline | Normal — falls back to local simulation |

---

## Admin Panel Access
- Go to **Profile** tab
- Tap the avatar **7 times quickly** (within 3 seconds)  
- Enter PIN: **`2580`**

All changes in admin panel instantly push to Firebase and reflect on ALL connected devices.
