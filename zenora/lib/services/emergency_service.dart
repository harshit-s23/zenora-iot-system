import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// Sends SMS directly via native SmsManager — no app chooser, no WhatsApp popup.
  Future<bool> sendSms(
      {required String phoneNumber, required String message}) async {
    final clean = _cleanNumber(phoneNumber);
    if (clean.isEmpty) return false;
    debugPrint('[EmergencyService] Sending SMS to: $clean');
    try {
      final result = await _channel
          .invokeMethod<bool>('sendSms', {'number': clean, 'message': message});
      debugPrint('[EmergencyService] SMS result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint(
          '[EmergencyService] SMS PlatformException: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[EmergencyService] SMS Unknown error: $e');
      return false;
    }
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
