// ════════════════════════════════════════════════════════════════════════════
// lib/providers/app_provider.dart  [EXTENDED — v3]
//
// NEW in v3:
//   • isFallDetected flag + fall auto-trigger when stressIndex > 90
//   • isPressureTherapyActive flag + HapticService integration
//   • pressureTherapyCycle counter for animated pulse
//   • userAge + userPhone stored in SharedPreferences
//   • Fall event stored to Firebase via FallDetectionService
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../services/fall_detection_service.dart';
import '../services/pressure_therapy_service.dart';

class AppProvider extends ChangeNotifier {
  // ─── Real sensor values ────────────────────────────────────────────────────
  double _heartRate = 72;
  double _gsr = 4.2;
  double _bodyTemp = 36.6;
  double _stressIndex = 34;
  double _spo2 = 98.0; // ✅ SpO2 from ESP32
  bool _fallFromEsp32 = false; // ✅ Fall detection from ESP32

  // ─── MPU6050 fall detection values ────────────────────────────────────────
  double _mpuRoll = 0.0; // degrees
  double _mpuPitch = 0.0; // degrees
  double _mpuLinearX = 0.0; // m/s²
  double _mpuLinearY = 0.0; // m/s²
  double _mpuLinearZ = 9.81; // m/s²
  double _mpuRotationalX = 0.0; // °/s
  double _mpuRotationalY = 0.0; // °/s
  double _mpuRotationalZ = 0.0; // °/s

  // MPU6050 admin override values (shown in admin sliders)
  double _demoMpuRoll = 0.0;
  double _demoMpuPitch = 0.0;
  double _demoMpuLinearX = 0.0;
  double _demoMpuLinearY = 0.0;
  double _demoMpuLinearZ = 9.81;
  double _demoMpuRotX = 0.0;
  double _demoMpuRotY = 0.0;
  double _demoMpuRotZ = 0.0;

  // ─── Local demo override (fallback when Firebase offline) ─────────────────
  bool _localOverrideEnabled = false;
  double _demoHeartRate = 72;
  double _demoGsr = 4.2;
  double _demoBodyTemp = 36.6;
  double _demoStressIndex = 34;
  String _demoScenario = 'Calm';

  // ─── Firebase / Cloud state ────────────────────────────────────────────────
  bool _cloudOverrideEnabled = false;
  bool _isCloudConnected = false;
  bool _esp32Online = false;
  StreamSubscription<DeviceSnapshot>? _firebaseSub;

  // ─── Live graph history ───────────────────────────────────────────────────
  final List<double> _hrHistory = [];
  final List<double> _gsrHistory = [];
  final List<double> _tempHistory = [];
  Timer? _simulationTimer;

  // ─── Fall Detection ────────────────────────────────────────────────────────
  bool _isFallDetected = false;
  bool _fallAlertHandled = false; // prevents repeated triggers in same session
  String _fallLocationLink = '';

  // ─── Pressure Therapy ─────────────────────────────────────────────────────
  bool _isPressureTherapyActive = false;
  int _pressureTherapyCycle = 0;

  // ─── User profile ─────────────────────────────────────────────────────────
  String userName = 'Dr. Sarah Chen';
  String userRole = 'Healthcare Professional';
  String userAge = '';
  String userPhone = '';
  String memberSince = 'Jan 2026';
  bool deviceConnected = true;
  double batteryLevel = 0.78;
  String lastSync = '2 min ago';
  String firmwareVersion = 'v2.4.1';
  String emergencyContact1 = '';
  String emergencyContact2 = '';

  // ─── Stats ────────────────────────────────────────────────────────────────
  final List<double> weeklyStress = [45, 52, 68, 38, 72, 35, 42];
  final List<double> monthlyStress =
      List.generate(30, (i) => 30 + Random().nextDouble() * 50);
  final List<double> hourlyStress =
      List.generate(24, (i) => 25 + Random().nextDouble() * 60);

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool get isDemoMode => _cloudOverrideEnabled || _localOverrideEnabled;
  bool get isCloudOverride => _cloudOverrideEnabled;
  bool get isCloudConnected => _isCloudConnected;
  bool get esp32Online => _esp32Online;

  // Fall Detection
  bool get isFallDetected => _isFallDetected;
  String get fallLocationLink => _fallLocationLink;

  // Pressure Therapy
  bool get isPressureTherapyActive => _isPressureTherapyActive;
  int get pressureTherapyCycle => _pressureTherapyCycle;

  String get dataSourceLabel {
    // Never expose demo/manipulation mode to the home UI.
    if (_esp32Online) return 'LIVE DATA';
    if (_isCloudConnected) return 'LIVE DATA';
    return 'SIMULATED';
  }

  Color get dataSourceColor {
    // Mirror label logic — never show orange demo colour on home.
    if (_esp32Online) return const Color(0xFF00FF88);
    if (_isCloudConnected) return const Color(0xFF00FF88);
    return const Color(0xFF7A8499);
  }

  double get heartRate => _heartRate;
  double get gsr => _gsr;
  double get bodyTemp => _bodyTemp;
  double get stressIndex => _stressIndex;
  double get spo2 => _spo2;
  bool get fallFromEsp32 => _fallFromEsp32;

  // ── MPU6050 live values (shown to user) ───────────────────────────────────
  double get mpuRoll => _mpuRoll;
  double get mpuPitch => _mpuPitch;
  double get mpuLinearX => _mpuLinearX;
  double get mpuLinearY => _mpuLinearY;
  double get mpuLinearZ => _mpuLinearZ;
  double get mpuRotationalX => _mpuRotationalX;
  double get mpuRotationalY => _mpuRotationalY;
  double get mpuRotationalZ => _mpuRotationalZ;

  // ── MPU6050 admin override values (used by admin sliders) ─────────────────
  double get demoMpuRoll => _demoMpuRoll;
  double get demoMpuPitch => _demoMpuPitch;
  double get demoMpuLinearX => _demoMpuLinearX;
  double get demoMpuLinearY => _demoMpuLinearY;
  double get demoMpuLinearZ => _demoMpuLinearZ;
  double get demoMpuRotX => _demoMpuRotX;
  double get demoMpuRotY => _demoMpuRotY;
  double get demoMpuRotZ => _demoMpuRotZ;

  double get demoHeartRate => _demoHeartRate;
  double get demoGsr => _demoGsr;
  double get demoBodyTemp => _demoBodyTemp;
  double get demoStressIndex => _demoStressIndex;
  String get demoScenario => _demoScenario;

  List<double> get hrHistory => _hrHistory;
  List<double> get gsrHistory => _gsrHistory;
  List<double> get tempHistory => _tempHistory;

  double get weekAvgStress =>
      weeklyStress.reduce((a, b) => a + b) / weeklyStress.length;
  double get todayAvgStress =>
      hourlyStress.reduce((a, b) => a + b) / hourlyStress.length;

  // ═══════════════════════════════════════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════════════════════════════════════
  AppProvider() {
    _initHistoryBuffers();
    _startSimulation();
    _subscribeToFirebase();
    _loadPrefs();
  }

  void _initHistoryBuffers() {
    final rand = Random();
    for (int i = 0; i < 60; i++) {
      _hrHistory.add(65 + rand.nextDouble() * 20);
      _gsrHistory.add(3.5 + rand.nextDouble() * 2.5);
      _tempHistory.add(36.2 + rand.nextDouble() * 0.8);
    }
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      final rand = Random();
      if (!isDemoMode) {
        _heartRate = (_heartRate + (rand.nextDouble() * 4 - 2)).clamp(55, 110);
        _gsr = (_gsr + (rand.nextDouble() * 0.4 - 0.2)).clamp(1.0, 10.0);
        _bodyTemp =
            (_bodyTemp + (rand.nextDouble() * 0.1 - 0.05)).clamp(35.5, 38.5);
        _stressIndex =
            (_stressIndex + (rand.nextDouble() * 3 - 1.5)).clamp(10, 85);
      } else {
        _heartRate = _demoHeartRate + (rand.nextDouble() * 4 - 2);
        _gsr = _demoGsr + (rand.nextDouble() * 0.2 - 0.1);
        _bodyTemp = _demoBodyTemp + (rand.nextDouble() * 0.05 - 0.025);
        _stressIndex =
            (_demoStressIndex + (rand.nextDouble() * 2 - 1)).clamp(1, 100);
      }

      _hrHistory.add(_heartRate);
      _gsrHistory.add(_gsr);
      _tempHistory.add(_bodyTemp);
      if (_hrHistory.length > 120) _hrHistory.removeAt(0);
      if (_gsrHistory.length > 120) _gsrHistory.removeAt(0);
      if (_tempHistory.length > 120) _tempHistory.removeAt(0);

      // Only trigger emergency popup when admin manipulation is active (isDemoMode)
      // AND stress is above 90. This prevents random simulation drift from
      // firing false alerts during normal use.
      if (isDemoMode && _stressIndex > 90 && !_fallAlertHandled) {
        _triggerFallDetection();
      }

      notifyListeners();
    });
  }

  void _subscribeToFirebase() {
    _firebaseSub = FirebaseService.instance.deviceStream.listen(
      (snapshot) {
        _isCloudConnected = true;
        _esp32Online = snapshot.esp32Online;
        _cloudOverrideEnabled = snapshot.overrideEnabled;

        if (snapshot.overrideEnabled) {
          _demoHeartRate = snapshot.heartRate;
          _demoGsr = snapshot.gsr;
          _demoBodyTemp = snapshot.temperature;
          _demoStressIndex = snapshot.stressIndex;
          _demoScenario = snapshot.scenario;
          _heartRate = snapshot.heartRate;
          _gsr = snapshot.gsr;
          _bodyTemp = snapshot.temperature;
          _stressIndex = snapshot.stressIndex;
          // MPU6050 override → update both demo (slider) and live (display) values
          _demoMpuRoll = snapshot.roll;
          _demoMpuPitch = snapshot.pitch;
          _demoMpuLinearX = snapshot.linearX;
          _demoMpuLinearY = snapshot.linearY;
          _demoMpuLinearZ = snapshot.linearZ;
          _demoMpuRotX = snapshot.rotationalX;
          _demoMpuRotY = snapshot.rotationalY;
          _demoMpuRotZ = snapshot.rotationalZ;
          _mpuRoll = snapshot.roll;
          _mpuPitch = snapshot.pitch;
          _mpuLinearX = snapshot.linearX;
          _mpuLinearY = snapshot.linearY;
          _mpuLinearZ = snapshot.linearZ;
          _mpuRotationalX = snapshot.rotationalX;
          _mpuRotationalY = snapshot.rotationalY;
          _mpuRotationalZ = snapshot.rotationalZ;
        } else if (snapshot.esp32Online) {
          _heartRate = snapshot.heartRate;
          _gsr = snapshot.gsr;
          _bodyTemp = snapshot.temperature;
          _stressIndex = snapshot.stressIndex;
          _spo2 = snapshot.spo2; // ✅ read SpO2
          _fallFromEsp32 = snapshot.fall; // ✅ read fall
          _localOverrideEnabled = false;
          // MPU6050 real values from ESP32
          _mpuRoll = snapshot.roll;
          _mpuPitch = snapshot.pitch;
          _mpuLinearX = snapshot.linearX;
          _mpuLinearY = snapshot.linearY;
          _mpuLinearZ = snapshot.linearZ;
          _mpuRotationalX = snapshot.rotationalX;
          _mpuRotationalY = snapshot.rotationalY;
          _mpuRotationalZ = snapshot.rotationalZ;
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[AppProvider] Firebase stream error: $e');
        _isCloudConnected = false;
        notifyListeners();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FALL DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _triggerFallDetection() async {
    _fallAlertHandled = true; // prevent re-trigger
    _isFallDetected = true;
    notifyListeners();

    final locationLink =
        await FallDetectionService.instance.getLocationLink() ??
            'https://maps.google.com/?q=0,0';
    _fallLocationLink = locationLink;

    await FallDetectionService.instance.storeFallEvent(
      userName: userName,
      mapsLink: locationLink,
    );

    notifyListeners();
  }

  /// Manual trigger (Fall test button on home screen)
  Future<void> triggerFallManually() async {
    _fallAlertHandled = true;
    _isFallDetected = true;
    notifyListeners();

    final locationLink =
        await FallDetectionService.instance.getLocationLink() ??
            'https://maps.google.com/?q=0,0';
    _fallLocationLink = locationLink;

    await FallDetectionService.instance.storeFallEvent(
      userName: userName,
      mapsLink: locationLink,
    );

    notifyListeners();
  }

  void dismissFallAlert() {
    _isFallDetected = false;
    // Keep _fallAlertHandled = true to avoid re-trigger in same session
    notifyListeners();
  }

  void resetFallSession() {
    _isFallDetected = false;
    _fallAlertHandled = false;
    _fallLocationLink = '';
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRESSURE THERAPY
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> startPressureTherapy() async {
    if (_isPressureTherapyActive) return;
    _isPressureTherapyActive = true;
    _pressureTherapyCycle = 0;
    notifyListeners();

    await PressureTherapyService.instance.start(
      onUpdate: () {
        _pressureTherapyCycle = PressureTherapyService.instance.currentCycle;
        notifyListeners();
      },
      onComplete: () {
        _isPressureTherapyActive = false;
        _pressureTherapyCycle = 0;
        notifyListeners();
      },
    );
  }

  void stopPressureTherapy() {
    PressureTherapyService.instance.stop();
    _isPressureTherapyActive = false;
    _pressureTherapyCycle = 0;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HARDWARE UPDATE
  // ═══════════════════════════════════════════════════════════════════════════
  void updateSensorData({
    double? heartRate,
    double? gsr,
    double? bodyTemp,
    double? stressIndex,
  }) {
    if (!isDemoMode) {
      if (heartRate != null) _heartRate = heartRate;
      if (gsr != null) _gsr = gsr;
      if (bodyTemp != null) _bodyTemp = bodyTemp;
      if (stressIndex != null) _stressIndex = stressIndex;
      FirebaseService.instance.pushRealSensorData(
        heartRate: _heartRate,
        gsr: _gsr,
        temperature: _bodyTemp,
        stressIndex: _stressIndex,
      );
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN PANEL — cloud-synced writes
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> setDemoMode(bool enabled) async {
    _localOverrideEnabled = enabled;
    _cloudOverrideEnabled = enabled;
    if (!enabled) _demoScenario = 'Calm';
    notifyListeners();
    await FirebaseService.instance.setOverrideEnabled(enabled);
  }

  Future<void> applyDemoScenario(String scenario) async {
    _demoScenario = scenario;
    double hr, gsr, temp, stress;
    switch (scenario) {
      case 'Calm':
        stress = 25;
        hr = 65;
        gsr = 2.8;
        temp = 36.4;
        break;
      case 'Relaxed':
        stress = 42;
        hr = 72;
        gsr = 4.0;
        temp = 36.6;
        break;
      case 'Moderate':
        stress = 60;
        hr = 85;
        gsr = 6.5;
        temp = 36.9;
        break;
      case 'High Stress':
        stress = 78;
        hr = 98;
        gsr = 8.5;
        temp = 37.2;
        break;
      case 'Very High':
        stress = 92;
        hr = 115;
        gsr = 11.0;
        temp = 37.6;
        break;
      default:
        stress = 34;
        hr = 72;
        gsr = 4.2;
        temp = 36.6;
    }
    _demoStressIndex = stress;
    _demoHeartRate = hr;
    _demoGsr = gsr;
    _demoBodyTemp = temp;
    _localOverrideEnabled = true;
    notifyListeners();
    await FirebaseService.instance.pushOverrideScenario(
      heartRate: hr,
      gsr: gsr,
      temperature: temp,
      stressIndex: stress,
      scenario: scenario,
    );
  }

  Future<void> setDemoHeartRate(double v) async {
    _demoHeartRate = v;
    notifyListeners();
    await FirebaseService.instance.updateOverrideField('heart_rate', v);
  }

  Future<void> setDemoGsr(double v) async {
    _demoGsr = v;
    notifyListeners();
    await FirebaseService.instance.updateOverrideField('gsr', v);
  }

  Future<void> setDemoBodyTemp(double v) async {
    _demoBodyTemp = v;
    notifyListeners();
    await FirebaseService.instance.updateOverrideField('temperature', v);
  }

  Future<void> setDemoStressIndex(double v) async {
    _demoStressIndex = v;
    notifyListeners();
    await FirebaseService.instance.updateOverrideField('stress_index', v);
    // Fire haptic motor (D19) on ESP32 to reflect the manipulated stress value
    PressureTherapyService.instance.sendHapticForStress(v);
  }

  // ── MPU6050 admin override ─────────────────────────────────────────────────
  /// Called by admin sliders — pushes all 8 MPU fields to Firebase in one write.
  Future<void> setDemoMpuValues({
    double? roll,
    double? pitch,
    double? linearX,
    double? linearY,
    double? linearZ,
    double? rotX,
    double? rotY,
    double? rotZ,
  }) async {
    if (roll != null) _demoMpuRoll = roll;
    if (pitch != null) _demoMpuPitch = pitch;
    if (linearX != null) _demoMpuLinearX = linearX;
    if (linearY != null) _demoMpuLinearY = linearY;
    if (linearZ != null) _demoMpuLinearZ = linearZ;
    if (rotX != null) _demoMpuRotX = rotX;
    if (rotY != null) _demoMpuRotY = rotY;
    if (rotZ != null) _demoMpuRotZ = rotZ;
    notifyListeners();
    await FirebaseService.instance.updateMpuOverride(
      roll: _demoMpuRoll,
      pitch: _demoMpuPitch,
      linearX: _demoMpuLinearX,
      linearY: _demoMpuLinearY,
      linearZ: _demoMpuLinearZ,
      rotationalX: _demoMpuRotX,
      rotationalY: _demoMpuRotY,
      rotationalZ: _demoMpuRotZ,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────────────────────────────────
  void updateProfile({
    String? name,
    String? role,
    String? age,
    String? phone,
    String? ec1,
    String? ec2,
  }) {
    if (name != null) userName = name;
    if (role != null) userRole = role;
    if (age != null) userAge = age;
    if (phone != null) userPhone = phone;
    if (ec1 != null) emergencyContact1 = ec1;
    if (ec2 != null) emergencyContact2 = ec2;
    _savePrefs();
    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName') ?? userName;
    userRole = prefs.getString('userRole') ?? userRole;
    userAge = prefs.getString('userAge') ?? '';
    userPhone = prefs.getString('userPhone') ?? '';
    emergencyContact1 = prefs.getString('ec1') ?? '';
    emergencyContact2 = prefs.getString('ec2') ?? '';
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    await prefs.setString('userRole', userRole);
    await prefs.setString('userAge', userAge);
    await prefs.setString('userPhone', userPhone);
    await prefs.setString('ec1', emergencyContact1);
    await prefs.setString('ec2', emergencyContact2);
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _firebaseSub?.cancel();
    PressureTherapyService.instance.dispose();
    super.dispose();
  }
}
