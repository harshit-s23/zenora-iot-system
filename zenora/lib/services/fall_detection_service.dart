// ════════════════════════════════════════════════════════════════════════════
// lib/services/fall_detection_service.dart
//
// Fall Detection + GPS Service
// • Fetches device location via geolocator
// • Generates Google Maps link
// • Stores event in Firebase under device_1/fall_event/
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class FallDetectionService {
  static final FallDetectionService instance = FallDetectionService._();
  FallDetectionService._();

  /// Returns Google Maps link for current location.
  /// Returns null if permission denied or unavailable.
  Future<String?> getLocationLink() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[FallDetection] Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[FallDetection] Location permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[FallDetection] Location permission permanently denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final link =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      debugPrint('[FallDetection] Location: $link');
      return link;
    } catch (e) {
      debugPrint('[FallDetection] Error getting location: $e');
      return null;
    }
  }

  /// Stores fall event in Firebase under device_1/fall_event/
  Future<void> storeFallEvent({
    required String userName,
    required String mapsLink,
  }) async {
    try {
      final ref = FirebaseDatabase.instance.ref('device_1/fall_event');
      await ref.set({
        'timestamp': DateTime.now().toIso8601String(),
        'user_name': userName,
        'maps_link': mapsLink,
        'status': 'triggered',
      });
      debugPrint('[FallDetection] Fall event stored in Firebase');
    } catch (e) {
      debugPrint('[FallDetection] Firebase write error: $e');
    }
  }
}
