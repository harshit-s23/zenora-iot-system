// ════════════════════════════════════════════════════════════════════════════
// lib/widgets/fall_alert_banner.dart
//
// Fall Detection Alert Banner
// Shows when isFallDetected == true.
// Allows sending emergency alert or dismissing.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/emergency_service.dart';
import '../theme/app_theme.dart';

class FallAlertBanner extends StatelessWidget {
  const FallAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        if (!provider.isFallDetected) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accentRed.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentRed.withOpacity(0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.accentRed, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '⚠️ Fall Detected — Location Shared',
                      style: TextStyle(
                        color: AppTheme.accentRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: provider.dismissFallAlert,
                    child: const Icon(Icons.close,
                        color: AppTheme.textSecondary, size: 18),
                  ),
                ],
              ),
              if (provider.fallLocationLink.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  provider.fallLocationLink,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _sendAlert(context, provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Send Emergency Alert',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: provider.dismissFallAlert,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "I'm Safe",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendAlert(BuildContext context, AppProvider provider) async {
    final c1 = provider.emergencyContact1;
    final c2 = provider.emergencyContact2;

    if (c1.isEmpty && c2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No emergency contacts set. Go to Profile to add them.'),
          backgroundColor: AppTheme.accentOrange,
        ),
      );
      return;
    }

    await EmergencyService.instance.triggerFullAlert(
      userName: provider.userName,
      mapsLink: provider.fallLocationLink.isNotEmpty
          ? provider.fallLocationLink
          : 'Location unavailable',
      contact1: c1,
      contact2: c2,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Emergency alert sent to contacts.'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }
}
