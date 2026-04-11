// ════════════════════════════════════════════════════════════════════════════
// lib/screens/admin_screen.dart  [UPGRADED — Cloud-Synced]
//
// CHANGES FROM V1:
//   • All toggle/slider/scenario changes now push to Firebase Realtime DB
//   • Device B receives changes within ~200ms (Firebase stream)
//   • Added: Cloud Sync Status card (shows Firebase connection + ESP32 state)
//   • Added: Firebase push indicator on each action
//   • Sliders now call async setDemo* methods (write to Firebase)
//   • All scenarios use applyDemoScenario() which writes to Firebase
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/data_source_badge.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isPushing = false;   // Shows a brief "syncing" state on Firebase writes

  Future<void> _withPushFeedback(Future<void> Function() action) async {
    setState(() => _isPushing = true);
    await action();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isPushing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: AppTheme.accentOrange, size: 20),
                const SizedBox(width: 8),
                const Text('Admin / Demo Panel'),
                const Spacer(),
                // Cloud push indicator
                AnimatedOpacity(
                  opacity: _isPushing ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text('Syncing…',
                          style: TextStyle(
                              color: AppTheme.accentCyan, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Warning banner ─────────────────────────────────────────
              _warningBanner(),
              const SizedBox(height: 14),

              // ── Cloud Sync Status ──────────────────────────────────────
              _cloudStatusCard(provider),
              const SizedBox(height: 14),

              // ── Demo Mode Master Toggle ────────────────────────────────
              _demoModeToggle(provider),
              const SizedBox(height: 16),

              // ── Quick Scenario Presets ─────────────────────────────────
              _sectionLabel('Quick Scenario Presets'),
              const SizedBox(height: 10),
              _scenarioGrid(provider),
              const SizedBox(height: 18),

              // ── Manual Sliders ─────────────────────────────────────────
              _sectionLabel('Manual Override'),
              const SizedBox(height: 2),
              _sectionHint('Changes push to Firebase instantly'),
              const SizedBox(height: 10),
              _slidersCard(provider),
              const SizedBox(height: 16),

              // ── Live Preview ───────────────────────────────────────────
              _sectionLabel('Live Preview (All Devices)'),
              const SizedBox(height: 10),
              _livePreview(provider),
              const SizedBox(height: 16),

              // ── Reset ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentRed,
                    side: const BorderSide(color: AppTheme.accentRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.restore),
                  label: const Text('Disable Override — Show Real Data'),
                  onPressed: () => _withPushFeedback(
                      () => provider.setDemoMode(false)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── Warning banner ──────────────────────────────────────────────────────
  Widget _warningBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentOrange.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: AppTheme.accentOrange, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'CLOUD-SYNCED DEMO MODE\nChanges here instantly reflect on ALL connected devices via Firebase.',
              style: TextStyle(
                  color: AppTheme.accentOrange, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cloud sync status card ──────────────────────────────────────────────
  Widget _cloudStatusCard(AppProvider provider) {
    return Container(
      decoration: AppTheme.glowDecoration(
          provider.isCloudConnected
              ? AppTheme.accentCyan
              : AppTheme.borderColor),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                provider.isCloudConnected
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: provider.isCloudConnected
                    ? AppTheme.accentCyan
                    : AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('System Status',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              DataSourceBadge(expanded: false),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statusChip(
                icon: Icons.cloud,
                label: 'Firebase',
                ok: provider.isCloudConnected,
              ),
              const SizedBox(width: 8),
              _statusChip(
                icon: Icons.memory,
                label: 'ESP32',
                ok: provider.esp32Online,
              ),
              const SizedBox(width: 8),
              _statusChip(
                icon: Icons.science_outlined,
                label: 'Override',
                ok: provider.isDemoMode,
                okColor: AppTheme.accentOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required bool ok,
    Color? okColor,
  }) {
    final color =
        ok ? (okColor ?? AppTheme.accentGreen) : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(width: 4),
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 11,
          ),
        ],
      ),
    );
  }

  // ── Demo mode master toggle ─────────────────────────────────────────────
  Widget _demoModeToggle(AppProvider provider) {
    return Container(
      decoration: AppTheme.glowDecoration(provider.isDemoMode
          ? AppTheme.accentOrange
          : AppTheme.borderColor),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.science_outlined,
                color: AppTheme.accentOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Override / Demo Mode',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                Text(
                  provider.isDemoMode
                      ? '🟠 ACTIVE — All devices showing override data'
                      : '⚫ OFF — Devices showing real/simulated data',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
                if (provider.isDemoMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.sync, color: AppTheme.accentCyan, size: 11),
                        const SizedBox(width: 4),
                        const Text('Pushed to Firebase',
                            style: TextStyle(
                                color: AppTheme.accentCyan, fontSize: 10)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: provider.isDemoMode,
            onChanged: (v) =>
                _withPushFeedback(() => provider.setDemoMode(v)),
            activeColor: AppTheme.accentOrange,
            trackColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? AppTheme.accentOrange.withOpacity(0.3)
                    : AppTheme.borderColor),
          ),
        ],
      ),
    );
  }

  // ── Scenario grid ───────────────────────────────────────────────────────
  Widget _scenarioGrid(AppProvider provider) {
    final scenarios = [
      ('Calm', AppTheme.accentGreen, '😌'),
      ('Relaxed', AppTheme.accentCyan, '🙂'),
      ('Moderate', AppTheme.accentYellow, '😐'),
      ('High Stress', AppTheme.accentOrange, '😰'),
      ('Very High', AppTheme.accentRed, '🆘'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: scenarios.map((s) {
        final isActive = provider.isDemoMode && provider.demoScenario == s.$1;
        return GestureDetector(
          onTap: () => _withPushFeedback(
              () => provider.applyDemoScenario(s.$1)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? s.$2.withOpacity(0.2)
                  : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? s.$2 : AppTheme.borderColor,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [BoxShadow(color: s.$2.withOpacity(0.2), blurRadius: 8)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.$3, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.$1,
                      style: TextStyle(
                        color:
                            isActive ? s.$2 : AppTheme.textPrimary,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    if (isActive)
                      Row(
                        children: const [
                          Icon(Icons.cloud_done,
                              color: AppTheme.accentCyan, size: 9),
                          SizedBox(width: 3),
                          Text('Synced',
                              style: TextStyle(
                                  color: AppTheme.accentCyan,
                                  fontSize: 9)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Manual sliders card ────────────────────────────────────────────────
  Widget _slidersCard(AppProvider provider) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _cloudSlider(
            context: context,
            label: '😰 Stress Index',
            value: provider.demoStressIndex,
            min: 0,
            max: 100,
            color: AppTheme.stressColor(provider.demoStressIndex),
            valueLabel:
                '${provider.demoStressIndex.toStringAsFixed(0)}  (${AppTheme.stressLabel(provider.demoStressIndex)})',
            onChangeEnd: (v) =>
                _withPushFeedback(() => provider.setDemoStressIndex(v)),
          ),
          _divider(),
          _cloudSlider(
            context: context,
            label: '❤️ Heart Rate',
            value: provider.demoHeartRate,
            min: 40,
            max: 160,
            color: AppTheme.accentRed,
            valueLabel: '${provider.demoHeartRate.toStringAsFixed(0)} BPM',
            onChangeEnd: (v) =>
                _withPushFeedback(() => provider.setDemoHeartRate(v)),
          ),
          _divider(),
          _cloudSlider(
            context: context,
            label: '⚡ GSR',
            value: provider.demoGsr,
            min: 0.5,
            max: 15,
            color: AppTheme.accentCyan,
            valueLabel: '${provider.demoGsr.toStringAsFixed(1)} μS',
            onChangeEnd: (v) =>
                _withPushFeedback(() => provider.setDemoGsr(v)),
          ),
          _divider(),
          _cloudSlider(
            context: context,
            label: '🌡️ Body Temp',
            value: provider.demoBodyTemp,
            min: 35.0,
            max: 39.5,
            color: AppTheme.accentOrange,
            valueLabel: '${provider.demoBodyTemp.toStringAsFixed(1)} °C',
            onChangeEnd: (v) =>
                _withPushFeedback(() => provider.setDemoBodyTemp(v)),
          ),
        ],
      ),
    );
  }

  // ── Live preview card ──────────────────────────────────────────────────
  Widget _livePreview(AppProvider provider) {
    final stress = provider.stressIndex;
    final color = AppTheme.stressColor(stress);
    return Container(
      decoration: AppTheme.glowDecoration(color),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stress.toStringAsFixed(0),
                style: TextStyle(
                    color: color, fontSize: 52, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppTheme.stressLabel(stress),
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Text('Stress Index',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _previewMetric('❤️', '${provider.heartRate.toStringAsFixed(0)}',
                  'BPM', AppTheme.accentRed),
              _previewMetric('⚡', '${provider.gsr.toStringAsFixed(1)}',
                  'μS', AppTheme.accentCyan),
              _previewMetric('🌡️', '${provider.bodyTemp.toStringAsFixed(1)}',
                  '°C', AppTheme.accentOrange),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            provider.isDemoMode
                ? '↑ This is what Device B sees right now'
                : '↑ Real / simulated data (override OFF)',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8),
      );

  Widget _sectionHint(String hint) => Text(
        hint,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
      );

  Widget _divider() =>
      const Divider(color: AppTheme.borderColor, height: 20);

  Widget _previewMetric(
      String emoji, String value, String unit, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(unit,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  /// Slider that fires onChangeEnd (avoids hammering Firebase on every frame)
  Widget _cloudSlider({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required String valueLabel,
    required Future<void> Function(double) onChangeEnd,
  }) {
    return StatefulBuilder(
      builder: (_, setLocal) {
        double localVal = value;
        return Column(
          children: [
            Row(
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(valueLabel,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                // Mini cloud icon shows this will sync
                const Icon(Icons.cloud_upload_outlined,
                    color: AppTheme.accentCyan, size: 12),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: AppTheme.borderColor,
                thumbColor: color,
                overlayColor: color.withOpacity(0.2),
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                // Update local state on every drag (no Firebase hit)
                onChanged: (v) => setLocal(() => localVal = v),
                // Push to Firebase only when user lifts finger
                onChangeEnd: (v) => onChangeEnd(v),
              ),
            ),
          ],
        );
      },
    );
  }
}
