// lib/widgets/emergency_countdown_dialog.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/emergency_service.dart';
import '../theme/app_theme.dart';

class EmergencyCountdownDialog extends StatefulWidget {
  const EmergencyCountdownDialog({super.key});

  @override
  State<EmergencyCountdownDialog> createState() =>
      _EmergencyCountdownDialogState();
}

class _EmergencyCountdownDialogState extends State<EmergencyCountdownDialog>
    with TickerProviderStateMixin {
  static const _totalSeconds = 10;
  int _secondsLeft = _totalSeconds;
  Timer? _countdownTimer;
  bool _actionTaken = false;
  bool _sending = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (!_actionTaken) _autoSendEmergency();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _iAmSafe() {
    if (_actionTaken) return;
    _actionTaken = true;
    _countdownTimer?.cancel();
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.dismissFallAlert();
    Navigator.of(context).pop();
  }

  Future<void> _autoSendEmergency() async {
    if (_actionTaken || !mounted) return;
    _actionTaken = true;
    setState(() => _sending = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final mapsLink = provider.fallLocationLink.isNotEmpty
        ? provider.fallLocationLink
        : 'Location unavailable';

    await EmergencyService.instance.triggerFullAlert(
      userName: provider.userName,
      mapsLink: mapsLink,
      contact1: provider.emergencyContact1,
      contact2: provider.emergencyContact2,
    );

    provider.dismissFallAlert();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Emergency alert sent automatically.'),
          backgroundColor: AppTheme.accentRed,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // block back button
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1117),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppTheme.accentRed.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.accentRed.withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 4),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: _sending ? _buildSending() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildSending() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20),
        CircularProgressIndicator(color: AppTheme.accentRed),
        SizedBox(height: 20),
        Text('Sending emergency alert…',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Text('Contacting emergency contacts',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildContent() {
    final ringColor =
        _secondsLeft > 5 ? const Color(0xFFFFA726) : AppTheme.accentRed;
    final progress = _secondsLeft / _totalSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing warning icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentRed
                  .withOpacity(0.08 + _pulseController.value * 0.1),
              border: Border.all(
                color: AppTheme.accentRed
                    .withOpacity(0.4 + _pulseController.value * 0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppTheme.accentRed, size: 32),
          ),
        ),

        const SizedBox(height: 16),

        const Text('⚠️ HIGH STRESS DETECTED',
            style: TextStyle(
                color: AppTheme.accentRed,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8),
            textAlign: TextAlign.center),

        const SizedBox(height: 8),

        const Text(
            'Are you okay? Emergency alert will be sent automatically if you do not respond.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center),

        const SizedBox(height: 28),

        // Countdown ring
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                  size: const Size(110, 110),
                  painter: _RingPainter(
                      progress: 1.0,
                      color: AppTheme.borderColor,
                      strokeWidth: 8)),
              CustomPaint(
                  size: const Size(110, 110),
                  painter: _RingPainter(
                      progress: progress, color: ringColor, strokeWidth: 8)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$_secondsLeft',
                    style: TextStyle(
                        color: ringColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w800)),
                Text('SEC',
                    style: TextStyle(
                        color: ringColor.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5)),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // I Am Safe button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _iAmSafe,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 20),
                SizedBox(width: 8),
                Text("I Am Safe",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text('Emergency alert sends automatically in $_secondsLeft seconds',
            style: TextStyle(
                color: AppTheme.accentRed.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  const _RingPainter(
      {required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2 - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
