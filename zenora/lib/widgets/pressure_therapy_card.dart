// ════════════════════════════════════════════════════════════════════════════
// lib/widgets/pressure_therapy_card.dart
//
// Reusable card widget for Pressure Therapy feature.
// Shows animated pulse indicator + Start/Stop button.
// Insert into ExercisesScreen recommended section when stressIndex > 75.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class PressureTherapyCard extends StatefulWidget {
  const PressureTherapyCard({super.key});

  @override
  State<PressureTherapyCard> createState() => _PressureTherapyCardState();
}

class _PressureTherapyCardState extends State<PressureTherapyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final isActive = provider.isPressureTherapyActive;
        final cycle = provider.pressureTherapyCycle;
        const totalCycles = 11;
        final progress = isActive ? cycle / totalCycles : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.glowDecoration(AppTheme.accentPurple),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.accentPurple.withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.vibration,
                      color: AppTheme.accentPurple,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pressure Therapy',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Rhythmic haptic stimulation for stress relief',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Animated pulse indicator
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) {
                      final scale = isActive ? _pulseAnim.value : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.accentPurple
                                : AppTheme.textMuted,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppTheme.accentPurple
                                          .withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (isActive) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppTheme.borderColor,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accentPurple),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cycle ${cycle + 1} / $totalCycles — ${_phaseLabel(cycle)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    if (isActive) {
                      provider.stopPressureTherapy();
                    } else {
                      provider.startPressureTherapy();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? null
                          : const LinearGradient(
                              colors: [
                                AppTheme.accentPurple,
                                Color(0xFF6D28D9),
                              ],
                            ),
                      color: isActive ? AppTheme.borderColor : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? Icons.stop : Icons.play_arrow,
                          color: isActive
                              ? AppTheme.textSecondary
                              : Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Stop Session' : 'Start Pressure Therapy',
                          style: TextStyle(
                            color: isActive
                                ? AppTheme.textSecondary
                                : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _phaseLabel(int cycle) {
    if (cycle < 4) return 'Building up...';
    if (cycle < 7) return 'Peak stimulation';
    return 'Winding down...';
  }
}
