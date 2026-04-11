// ════════════════════════════════════════════════════════════════════════════
// lib/services/emergency_service.dart
//
// Emergency Alert Service
// • Opens SMS intent with location link (url_launcher)
// • WhatsApp deep link fallback
// • Phone call to primary contact
// All FREE — no paid APIs.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  static final EmergencyService instance = EmergencyService._();
  EmergencyService._();

  /// Send SMS to a single number with the emergency message.
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    final clean = _cleanNumber(phoneNumber);
    if (clean.isEmpty) return false;

    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$clean?body=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {
      debugPrint('[EmergencyService] SMS error: $e');
    }
    return false;
  }

  /// Open WhatsApp with pre-filled message for a number.
  Future<bool> sendWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    final clean = _cleanNumber(phoneNumber);
    if (clean.isEmpty) return false;

    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$clean?text=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('[EmergencyService] WhatsApp error: $e');
    }
    return false;
  }

  /// Place a phone call to the primary contact.
  Future<bool> callContact(String phoneNumber) async {
    final clean = _cleanNumber(phoneNumber);
    if (clean.isEmpty) return false;

    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {
      debugPrint('[EmergencyService] Call error: $e');
    }
    return false;
  }

  /// Trigger full emergency alert sequence:
  /// 1. SMS to both contacts
  /// 2. Call to primary contact
  Future<void> triggerFullAlert({
    required String userName,
    required String mapsLink,
    required String contact1,
    required String contact2,
  }) async {
    final message =
        '🚨 Emergency Alert: Fall detected for $userName. Location: $mapsLink';

    if (contact1.isNotEmpty) {
      await sendSms(phoneNumber: contact1, message: message);
    }
    if (contact2.isNotEmpty) {
      await sendSms(phoneNumber: contact2, message: message);
    }
    if (contact1.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      await callContact(contact1);
    }
  }

  String _cleanNumber(String number) {
    return number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }
}
