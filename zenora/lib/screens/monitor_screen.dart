import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/heart_rate_graph.dart';
import '../widgets/data_source_badge.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  bool _showHr = true;
  bool _showGsr = true;
  bool _showTemp = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildAppBar()),

                // ── Demo Mode Banner (visible when override active) ────────
                const SliverToBoxAdapter(child: DemoModeBanner()),

                // ── Metric Cards ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        _metricCard(
                          'Heart Rate',
                          provider.heartRate.toStringAsFixed(0),
                          'BPM',
                          AppTheme.accentRed,
                          Icons.favorite,
                        ),
                        const SizedBox(width: 10),
                        _metricCard(
                          'GSR',
                          provider.gsr.toStringAsFixed(1),
                          'μS',
                          AppTheme.accentCyan,
                          Icons.bolt,
                        ),
                        const SizedBox(width: 10),
                        _metricCard(
                          'Body Temp',
                          provider.bodyTemp.toStringAsFixed(1),
                          '°C',
                          AppTheme.accentOrange,
                          Icons.thermostat,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Real-Time Biometrics Chart ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Real-Time Biometrics',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppTheme.liveGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Live',
                                style: TextStyle(
                                  color: AppTheme.liveGreen,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Current reading labels on chart
                          if (provider.hrHistory.isNotEmpty)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  if (_showHr)
                                    _chartLabel(
                                      'HR: ${provider.heartRate.toStringAsFixed(0)} BPM',
                                      AppTheme.accentRed,
                                    ),
                                  if (_showGsr)
                                    _chartLabel(
                                      'GSR: ${provider.gsr.toStringAsFixed(1)} μS',
                                      AppTheme.accentCyan,
                                    ),
                                  if (_showTemp)
                                    _chartLabel(
                                      'Temp: ${provider.bodyTemp.toStringAsFixed(1)}°C',
                                      AppTheme.accentOrange,
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),

                          MultiLineGraph(
                            hrData: provider.hrHistory,
                            gsrData: provider.gsrHistory,
                            tempData: provider.tempHistory,
                            showHr: _showHr,
                            showGsr: _showGsr,
                            showTemp: _showTemp,
                            height: 170,
                          ),

                          const SizedBox(height: 14),

                          // Filter toggles
                          Wrap(
                            spacing: 8,
                            children: [
                              _filterChip(
                                '❤️ HR',
                                _showHr,
                                AppTheme.accentRed,
                                () => setState(
                                    () => _showHr = !_showHr),
                              ),
                              _filterChip(
                                '⚡ GSR',
                                _showGsr,
                                AppTheme.accentCyan,
                                () => setState(
                                    () => _showGsr = !_showGsr),
                              ),
                              _filterChip(
                                '🌡️ Temp',
                                _showTemp,
                                AppTheme.accentOrange,
                                () => setState(
                                    () => _showTemp = !_showTemp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Live Heart Rate Waveform ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      decoration: AppTheme.glowDecoration(AppTheme.accentRed),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite,
                                  color: AppTheme.accentRed, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'LIVE HEART RATE',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.accentRed.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '● LIVE',
                                  style: TextStyle(
                                    color: AppTheme.accentRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${provider.heartRate.toStringAsFixed(0)} BPM',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LiveHeartRateGraph(
                            data: provider.hrHistory.length > 80
                                ? provider.hrHistory
                                    .sublist(provider.hrHistory.length - 80)
                                : provider.hrHistory,
                            lineColor: AppTheme.accentRed,
                            height: 80,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── GSR Live Waveform ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      decoration:
                          AppTheme.glowDecoration(AppTheme.accentCyan),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt,
                                  color: AppTheme.accentCyan, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'GALVANIC SKIN RESPONSE',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${provider.gsr.toStringAsFixed(2)} μS',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LiveHeartRateGraph(
                            data: provider.gsrHistory.length > 80
                                ? provider.gsrHistory
                                    .sublist(provider.gsrHistory.length - 80)
                                : provider.gsrHistory,
                            lineColor: AppTheme.accentCyan,
                            height: 60,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Body Temp Strip ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Container(
                      decoration:
                          AppTheme.glowDecoration(AppTheme.accentOrange),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.thermostat,
                                  color: AppTheme.accentOrange, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'BODY TEMPERATURE',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${provider.bodyTemp.toStringAsFixed(1)} °C',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LiveHeartRateGraph(
                            data: provider.tempHistory.length > 80
                                ? provider.tempHistory
                                    .sublist(provider.tempHistory.length - 80)
                                : provider.tempHistory,
                            lineColor: AppTheme.accentOrange,
                            height: 55,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), AppTheme.accentCyan],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.monitor_heart,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Zenora',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'HEALTH INTELLIGENCE',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          DataSourceBadge(showIcon: true),
        ],
      ),
    );
  }

  Widget _metricCard(
      String title, String value, String unit, Color color, IconData icon) {
    return Expanded(
      child: Container(
        decoration: AppTheme.glowDecoration(color),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(unit,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
      String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : AppTheme.cardBg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color.withOpacity(0.5) : AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _chartLabel(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
