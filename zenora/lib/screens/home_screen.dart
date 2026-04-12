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

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar(context, provider)),
                const SliverToBoxAdapter(child: DemoModeBanner()),

                // Stress Gauge
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
                    ]),
                  ),
                ),

                // Recommendations
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
                            Text(
                                'LIVE HEART RATE  ${provider.heartRate.toStringAsFixed(0)} BPM',
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
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
            AnimatedContainer(
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
                Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ]),
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
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
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
        const Spacer(),
        // Internal test button — tap to test the emergency dialog
        GestureDetector(
          onTap: () async => provider.triggerFallManually(),
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        DataSourceBadge(showIcon: true),
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
}
