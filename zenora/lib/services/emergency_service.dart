import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  static final EmergencyService instance = EmergencyService._();
  EmergencyService._();

  static const _channel = MethodChannel('zenora/emergency');

  Future<bool> makeDirectCall(String phoneNumber) async {
    final clean = _cleanNumber(phoneNumber);
    debugPrint('[EmergencyService] Attempting call to: $clean');
    try {
      final result =
          await _channel.invokeMethod<bool>('makeCall', {'number': clean});
      debugPrint('[EmergencyService] Call result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint(
          '[EmergencyService] PlatformException: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[EmergencyService] Unknown error: $e');
      return false;
    }
  }

  Future<bool> sendSms(
      {required String phoneNumber, required String message}) async {
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

  Future<bool> sendWhatsApp(
      {required String phoneNumber, required String message}) async {
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

  Future<void> triggerFullAlert({
    required String userName,
    required String mapsLink,
    required String contact1,
    required String contact2,
  }) async {
    final message =
        '🚨 Emergency Alert: Fall detected for $userName. Location: $mapsLink';
    if (contact1.isNotEmpty)
      await sendSms(phoneNumber: contact1, message: message);
    if (contact2.isNotEmpty)
      await sendSms(phoneNumber: contact2, message: message);
    if (contact1.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      await makeDirectCall(contact1);
    }
  }

  String _cleanNumber(String number) =>
      number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
}
