// lib/screens/home_screen.dart  [v4]
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stress_gauge.dart';
import '../widgets/heart_rate_graph.dart';
import '../widgets/data_source_badge.dart';
import '../widgets/pressure_therapy_card.dart';
import '../widgets/emergency_countdown_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppProvider? _provider;
  bool _dialogActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = Provider.of<AppProvider>(context, listen: false);
    if (p != _provider) {
      _provider?.removeListener(_onProviderChange);
      _provider = p;
      _provider!.addListener(_onProviderChange);
    }
  }

  void _onProviderChange() {
    if (_provider == null || !mounted) return;

    // Only show dialog when Home is the active screen (not while admin is open)
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;

    if (_provider!.isFallDetected && !_dialogActive && isCurrentRoute) {
      _dialogActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.75),
          builder: (_) => const EmergencyCountdownDialog(),
        ).then((_) => _dialogActive = false);
      });
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stress = provider.stressIndex;
        final color = AppTheme.stressColor(stress);
        final label = AppTheme.stressLabel(stress);
        final recs = AppTheme.stressRecommendations(stress);
        final isExercise = provider.isExerciseMode;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar(context, provider)),
                const SliverToBoxAdapter(child: DemoModeBanner()),

                // ── Exercise Mode Toggle Banner ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _exerciseModeToggle(provider),
                  ),
                ),

                // ── Exercise Alert Banner ────────────────────────────────
                if (provider.exerciseAlert != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: _exerciseAlertBanner(provider),
                    ),
                  ),

                // ── Exercise Mode: Live Monitoring Card (replaces stress) ─
                if (isExercise)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _exerciseMonitoringCard(provider),
                    ),
                  ),

                // ── Normal Mode: Stress Gauge ────────────────────────────
                if (!isExercise)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Container(
                        decoration: AppTheme.glowDecoration(color),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: color.withOpacity(0.6),
                                        blurRadius: 6)
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('REAL-TIME STRESS INDEX',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2)),
                            ]),
                            const SizedBox(height: 20),
                            SizedBox(
                                width: 200,
                                height: 200,
                                child: StressGaugeWidget(stressIndex: stress)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: color.withOpacity(0.4)),
                              ),
                              child: Text(label,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                            ),
                            const SizedBox(height: 6),
                            Text(_stressMessage(stress),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Quick Metrics
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(children: [
                      _quickMetric(
                          '❤️',
                          '${provider.heartRate.toStringAsFixed(0)}',
                          'BPM',
                          AppTheme.accentRed),
                      const SizedBox(width: 10),
                      _quickMetric('⚡', '${provider.gsr.toStringAsFixed(1)}',
                          'μS  GSR', AppTheme.accentCyan),
                      const SizedBox(width: 10),
                      _quickMetric(
                          '🌡️',
                          '${provider.bodyTemp.toStringAsFixed(1)}',
                          '°C  Temp',
                          AppTheme.accentOrange),
                      const SizedBox(width: 10),
                      _quickMetric(
                          '🫁',
                          provider.hasSpo2Reading
                              ? provider.spo2.toStringAsFixed(0)
                              : '--',
                          '%  SpO₂',
                          AppTheme.accentPurple),
                    ]),
                  ),
                ),

                // Recommendations (hidden in exercise mode)
                if (!isExercise)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        decoration: AppTheme.cardDecoration(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.lightbulb_outline,
                                  color: color, size: 18),
                              const SizedBox(width: 8),
                              const Text('Recommended Actions',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(label,
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            if (stress > 75) const PressureTherapyCard(),
                            ...recs.map((rec) => _recTile(rec, color)),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Live Heart Rate
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.favorite,
                                color: AppTheme.accentRed, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'LIVE HEART RATE  ${provider.heartRate.toStringAsFixed(0)} BPM',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            _liveDot(),
                          ]),
                          const SizedBox(height: 12),
                          LiveHeartRateGraph(
                            data: provider.hrHistory.length > 60
                                ? provider.hrHistory
                                    .sublist(provider.hrHistory.length - 60)
                                : provider.hrHistory,
                            lineColor: AppTheme.accentRed,
                            height: 70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Fall Detection Card (user-facing, read-only) ──────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _fallDetectionCard(provider),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Fall Detection Card (read-only user view) ─────────────────────────────
  Widget _fallDetectionCard(AppProvider provider) {
    final isFall = provider.isFallDetected;
    final statusColor = isFall ? AppTheme.accentRed : AppTheme.accentGreen;
    final statusLabel = isFall ? 'FALL DETECTED' : 'STABLE';
    final statusIcon =
        isFall ? Icons.warning_rounded : Icons.check_circle_outline;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(isFall ? 0.7 : 0.25),
          width: isFall ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(isFall ? 0.18 : 0.06),
            blurRadius: isFall ? 14 : 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.accessibility_new, color: statusColor, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Fall Detection',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            // Status badge
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(statusLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                ]),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Orientation row ─────────────────────────────────────────────
          _mpuSectionLabel(Icons.screen_rotation_alt, const Color(0xFF7B61FF),
              'Orientation'),
          const SizedBox(height: 8),
          Row(children: [
            _mpuValueTile('Roll', '${provider.mpuRoll.toStringAsFixed(1)}°',
                const Color(0xFF7B61FF)),
            const SizedBox(width: 10),
            _mpuValueTile('Pitch', '${provider.mpuPitch.toStringAsFixed(1)}°',
                const Color(0xFF7B61FF)),
          ]),

          const SizedBox(height: 14),

          // ── Linear acceleration row ─────────────────────────────────────
          _mpuSectionLabel(
              Icons.speed, AppTheme.accentCyan, 'Linear Acceleration (m/s²)'),
          const SizedBox(height: 8),
          Row(children: [
            _mpuValueTile('X', provider.mpuLinearX.toStringAsFixed(2),
                AppTheme.accentCyan),
            const SizedBox(width: 8),
            _mpuValueTile('Y', provider.mpuLinearY.toStringAsFixed(2),
                AppTheme.accentCyan),
            const SizedBox(width: 8),
            _mpuValueTile('Z', provider.mpuLinearZ.toStringAsFixed(2),
                AppTheme.accentCyan),
          ]),

          const SizedBox(height: 14),

          // ── Rotational row ──────────────────────────────────────────────
          _mpuSectionLabel(Icons.rotate_90_degrees_ccw, AppTheme.accentOrange,
              'Rotational / Gyroscope (°/s)'),
          const SizedBox(height: 8),
          Row(children: [
            _mpuValueTile('X', provider.mpuRotationalX.toStringAsFixed(1),
                AppTheme.accentOrange),
            const SizedBox(width: 8),
            _mpuValueTile('Y', provider.mpuRotationalY.toStringAsFixed(1),
                AppTheme.accentOrange),
            const SizedBox(width: 8),
            _mpuValueTile('Z', provider.mpuRotationalZ.toStringAsFixed(1),
                AppTheme.accentOrange),
          ]),

          // ── Fall alert callout (only visible when detected) ─────────────
          if (isFall) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentRed.withOpacity(0.35)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.accentRed, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Abnormal motion detected — emergency alert triggered.',
                    style: TextStyle(
                        color: AppTheme.accentRed, fontSize: 12, height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mpuSectionLabel(IconData icon, Color color, String label) {
    return Row(children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3)),
    ]);
  }

  Widget _mpuValueTile(String axis, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(axis,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), AppTheme.accentCyan]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.monitor_heart, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Zenora',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text('HEALTH INTELLIGENCE',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    letterSpacing: 1.5)),
          ]),
        ),
        // Internal test button — tap to test the emergency dialog
        GestureDetector(
          onTap: () async => provider.triggerFallManually(),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentRed.withOpacity(0.4)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppTheme.accentRed, size: 14),
              SizedBox(width: 4),
              Text('Fall',
                  style: TextStyle(
                      color: AppTheme.accentRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        Flexible(child: DataSourceBadge(showIcon: true)),
      ]),
    );
  }

  Widget _quickMetric(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        decoration: AppTheme.glowDecoration(color),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _recTile(String rec, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 7, right: 10),
          decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
        ),
        Expanded(
            child: Text(rec,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13.5, height: 1.4))),
      ]),
    );
  }

  Widget _liveDot() {
    return Row(children: [
      Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              color: AppTheme.liveGreen, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      const Text('LIVE',
          style: TextStyle(
              color: AppTheme.liveGreen,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    ]);
  }

  String _stressMessage(double stress) {
    if (stress <= 30) return 'You are calm';
    if (stress <= 50) return 'Slightly elevated — stay mindful';
    if (stress <= 70) return 'Moderate stress detected';
    if (stress <= 85) return 'High stress — take action now';
    return 'Very high stress — urgent attention needed';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXERCISE MODE WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _exerciseModeToggle(AppProvider provider) {
    final isActive = provider.isExerciseMode;
    final activeColor = const Color(0xFF00E676); // bright green
    final inactiveColor = AppTheme.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? activeColor.withOpacity(0.5)
              : AppTheme.borderColor,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withOpacity(0.15)
                  : AppTheme.cardBg2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isActive ? Icons.fitness_center : Icons.fitness_center_outlined,
              color: isActive ? activeColor : inactiveColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise Mode',
                  style: TextStyle(
                    color: isActive ? activeColor : AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive
                      ? 'Stress hidden • Safety alerts active'
                      : 'Enable to hide stress during workouts',
                  style: TextStyle(
                    color: isActive
                        ? activeColor.withOpacity(0.7)
                        : AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isActive,
            onChanged: (v) => provider.toggleExerciseMode(v),
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.3),
            inactiveThumbColor: AppTheme.textSecondary,
            inactiveTrackColor: AppTheme.cardBg2,
          ),
        ],
      ),
    );
  }

  Widget _exerciseAlertBanner(AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.accentRed.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentRed.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppTheme.accentRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VITALS SAFETY ALERT',
                  style: TextStyle(
                    color: AppTheme.accentRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.exerciseAlert ?? '',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => provider.dismissExerciseAlert(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.close,
                color: AppTheme.accentRed,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseMonitoringCard(AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E676).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF00E676),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'EXERCISE MONITORING',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00E676).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2×2 grid of live metrics
          Row(
            children: [
              _exerciseMetric(
                Icons.favorite,
                'Heart Rate',
                '${provider.heartRate.toStringAsFixed(0)}',
                'BPM',
                AppTheme.accentRed,
                _isHrDanger(provider.heartRate),
              ),
              const SizedBox(width: 10),
              _exerciseMetric(
                Icons.bolt,
                'GSR',
                '${provider.gsr.toStringAsFixed(1)}',
                'μS',
                AppTheme.accentCyan,
                provider.gsr > 12.0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _exerciseMetric(
                Icons.thermostat,
                'Body Temp',
                '${provider.bodyTemp.toStringAsFixed(1)}',
                '°C',
                AppTheme.accentOrange,
                provider.bodyTemp > 39.0,
              ),
              const SizedBox(width: 10),
              _exerciseMetric(
                Icons.air,
                'SpO2',
                provider.hasSpo2Reading
                    ? provider.spo2.toStringAsFixed(0)
                    : '--',
                '%',
                AppTheme.accentPurple,
                provider.hasSpo2Reading && provider.spo2 < 90,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Info text
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00E676).withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF00E676).withOpacity(0.7),
                  size: 14,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Stress index hidden during exercise. Safety alerts will trigger for abnormal vital ranges.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isHrDanger(double hr) => hr > 180 || hr < 40;

  Widget _exerciseMetric(
    IconData icon,
    String title,
    String value,
    String unit,
    Color color,
    bool isDanger,
  ) {
    final displayColor = isDanger ? AppTheme.accentRed : color;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isDanger
              ? AppTheme.accentRed.withOpacity(0.1)
              : displayColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger
                ? AppTheme.accentRed.withOpacity(0.5)
                : displayColor.withOpacity(0.2),
            width: isDanger ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: displayColor, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: displayColor.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDanger)
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.accentRed,
                    size: 12,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: displayColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: displayColor.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
