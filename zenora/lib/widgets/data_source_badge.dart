// ════════════════════════════════════════════════════════════════════════════
// lib/widgets/data_source_badge.dart
//
// Reusable badge that shows current data source state.
// Drop it anywhere in the UI — it reads directly from AppProvider.
//
// Usage:
//   DataSourceBadge()                    // compact pill
//   DataSourceBadge(showIcon: true)      // with wifi/demo icon
//   DataSourceBadge(expanded: true)      // wider with sub-label
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class DataSourceBadge extends StatefulWidget {
  final bool showIcon;
  final bool expanded;

  const DataSourceBadge({
    super.key,
    this.showIcon = true,
    this.expanded = false,
  });

  @override
  State<DataSourceBadge> createState() => _DataSourceBadgeState();
}

class _DataSourceBadgeState extends State<DataSourceBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final label = provider.dataSourceLabel;
        final color = provider.dataSourceColor;
        final isDemo = provider.isDemoMode;
        final isLive = provider.esp32Online && !isDemo;

        return AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            // Dot opacity pulses when live or demo
            final dotOpacity =
                (isLive || isDemo) ? 0.5 + _pulseCtrl.value * 0.5 : 1.0;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.expanded ? 14 : 10,
                vertical: widget.expanded ? 7 : 4,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: color.withOpacity(0.35), width: 1),
                boxShadow: (isLive || isDemo)
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.15 * _pulseCtrl.value),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing dot
                  Opacity(
                    opacity: dotOpacity,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (widget.expanded) ...[
                        Text(
                          _subLabel(provider),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Optional icon
                  if (widget.showIcon) ...[
                    const SizedBox(width: 5),
                    Icon(
                      _icon(provider),
                      color: color,
                      size: 11,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _subLabel(AppProvider p) {
    if (p.isDemoMode) return 'Cloud override active';
    if (p.esp32Online) return 'ESP32 connected';
    if (p.isCloudConnected) return 'Firebase connected';
    return 'Local simulation';
  }

  IconData _icon(AppProvider p) {
    if (p.isDemoMode) return Icons.science_outlined;
    if (p.esp32Online) return Icons.sensors;
    if (p.isCloudConnected) return Icons.cloud_outlined;
    return Icons.computer_outlined;
  }
}

/// Full-width banner variant — used at top of home/monitor when demo active
class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        if (!provider.isDemoMode) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.accentOrange.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.science_outlined,
                  color: AppTheme.accentOrange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DEMO MODE ACTIVE  •  ${provider.demoScenario}  •  Cloud-synced override',
                  style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => provider.setDemoMode(false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                        color: AppTheme.accentOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact sync status row — used in profile/settings
class CloudSyncStatus extends StatelessWidget {
  const CloudSyncStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final connected = provider.isCloudConnected;
        final color =
            connected ? AppTheme.accentGreen : AppTheme.textSecondary;

        return Row(
          children: [
            Icon(
              connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              connected ? 'Firebase connected' : 'Firebase offline',
              style: TextStyle(color: color, fontSize: 12),
            ),
            const SizedBox(width: 10),
            Icon(
              provider.esp32Online ? Icons.sensors : Icons.sensors_off,
              color: provider.esp32Online
                  ? AppTheme.accentCyan
                  : AppTheme.textSecondary,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              provider.esp32Online ? 'ESP32 online' : 'ESP32 offline',
              style: TextStyle(
                color: provider.esp32Online
                    ? AppTheme.accentCyan
                    : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}
