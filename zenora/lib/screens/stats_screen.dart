import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = ['Day', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.accentCyan.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Apr 2026',
                          style: TextStyle(
                              color: AppTheme.accentCyan, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tab bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicator: BoxDecoration(
                        color: AppTheme.accentCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.accentCyan.withOpacity(0.5)),
                      ),
                      labelColor: AppTheme.accentCyan,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      dividerColor: Colors.transparent,
                      tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Content ──────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _DayStats(provider: provider),
                      _WeekStats(provider: provider),
                      _MonthStats(provider: provider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Daily Stats ─────────────────────────────────────────────────────────────
class _DayStats extends StatelessWidget {
  final AppProvider provider;

  const _DayStats({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.hourlyStress;
    final avg = provider.todayAvgStress;
    final peak = data.reduce((a, b) => a > b ? a : b);
    final low = data.reduce((a, b) => a < b ? a : b);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Summary cards
        _summaryRow([
          _SummaryCard('Average', avg.toStringAsFixed(0), 'index',
              AppTheme.accentCyan),
          _SummaryCard('Peak', peak.toStringAsFixed(0), 'index',
              AppTheme.accentRed),
          _SummaryCard('Lowest', low.toStringAsFixed(0), 'index',
              AppTheme.accentGreen),
        ]),
        const SizedBox(height: 14),

        // Hourly trend
        _ChartCard(
          title: 'Today\'s Stress Pattern',
          subtitle: '24-hour view',
          child: _BarChart(
            data: data,
            labels: List.generate(
                24, (i) => i % 6 == 0 ? '${i}h' : ''),
            maxY: 100,
          ),
        ),
        const SizedBox(height: 14),

        // Time-of-day analysis
        _tileCard('🌅 Morning (6–12)', _avgRange(data, 6, 12),
            'Typically ${_timeLabel(_avgRange(data, 6, 12))}'),
        const SizedBox(height: 8),
        _tileCard('☀️ Afternoon (12–18)', _avgRange(data, 12, 18),
            'Typically ${_timeLabel(_avgRange(data, 12, 18))}'),
        const SizedBox(height: 8),
        _tileCard('🌙 Evening (18–24)', _avgRange(data, 18, 24),
            'Typically ${_timeLabel(_avgRange(data, 18, 24))}'),
        const SizedBox(height: 8),
        _tileCard('🌃 Night (0–6)', _avgRange(data, 0, 6),
            'Typically ${_timeLabel(_avgRange(data, 0, 6))}'),
        const SizedBox(height: 16),

        // Stress cause pie
        _StressCausesCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  double _avgRange(List<double> data, int start, int end) {
    final slice = data.sublist(start, end.clamp(0, data.length));
    return slice.isEmpty
        ? 0
        : slice.reduce((a, b) => a + b) / slice.length;
  }

  String _timeLabel(double v) =>
      v <= 35 ? 'Calm' : v <= 55 ? 'Moderate' : 'Elevated';
}

// ── Weekly Stats ─────────────────────────────────────────────────────────────
class _WeekStats extends StatelessWidget {
  final AppProvider provider;

  const _WeekStats({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.weeklyStress;
    final avg = provider.weekAvgStress;
    final peak = data.reduce((a, b) => a > b ? a : b);
    final low = data.reduce((a, b) => a < b ? a : b);
    final trend = data.last - data.first;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _summaryRow([
          _SummaryCard('Weekly Avg', avg.toStringAsFixed(0), 'index',
              AppTheme.accentCyan),
          _SummaryCard('Peak', peak.toStringAsFixed(0), 'index',
              AppTheme.accentRed),
          _SummaryCard('Trend', '${trend >= 0 ? "+" : ""}${trend.toStringAsFixed(0)}',
              trend < 0 ? '↓ Better' : '↑ Higher',
              trend < 0 ? AppTheme.accentGreen : AppTheme.accentOrange),
        ]),
        const SizedBox(height: 14),

        // Weekly bar chart
        _ChartCard(
          title: 'Weekly Stress Trend',
          subtitle: 'Average: ${avg.toStringAsFixed(1)} index',
          badge: trend < 0
              ? '↓ ${trend.abs().toStringAsFixed(0)}%'
              : '↑ ${trend.abs().toStringAsFixed(0)}%',
          badgeColor: trend < 0 ? AppTheme.accentGreen : AppTheme.accentOrange,
          child: _BarChart(
            data: data,
            labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            maxY: 100,
            highlightIndex: data.indexOf(peak),
          ),
        ),
        const SizedBox(height: 14),

        // Day breakdown
        Container(
          decoration: AppTheme.cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Day Breakdown',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...List.generate(
                7,
                (i) {
                  final days = [
                    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                  ];
                  final val = data[i];
                  final color = AppTheme.stressColor(val);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 36,
                            child: Text(days[i],
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: val / 100,
                              backgroundColor: AppTheme.borderColor,
                              valueColor:
                                  AlwaysStoppedAnimation(color),
                              minHeight: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 30,
                          child: Text(
                            val.toStringAsFixed(0),
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _StressCausesCard(),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Monthly Stats ────────────────────────────────────────────────────────────
class _MonthStats extends StatelessWidget {
  final AppProvider provider;

  const _MonthStats({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.monthlyStress;
    final avg = data.reduce((a, b) => a + b) / data.length;
    final peak = data.reduce((a, b) => a > b ? a : b);
    final low = data.reduce((a, b) => a < b ? a : b);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _summaryRow([
          _SummaryCard('Monthly Avg', avg.toStringAsFixed(0), 'index',
              AppTheme.accentCyan),
          _SummaryCard('Peak', peak.toStringAsFixed(0), 'index',
              AppTheme.accentRed),
          _SummaryCard('Best Day', low.toStringAsFixed(0), 'index',
              AppTheme.accentGreen),
        ]),
        const SizedBox(height: 14),

        _ChartCard(
          title: 'Monthly Stress Trend',
          subtitle: '30-day overview',
          child: _LineChartWidget(data: data),
        ),
        const SizedBox(height: 14),

        // Weekly averages for the month
        Container(
          decoration: AppTheme.cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Weekly Breakdown',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...List.generate(4, (i) {
                final slice = data.sublist(i * 7, ((i + 1) * 7).clamp(0, data.length));
                final weekAvg = slice.reduce((a, b) => a + b) / slice.length;
                final color = AppTheme.stressColor(weekAvg);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text('Week ${i + 1}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: weekAvg / 100,
                            backgroundColor: AppTheme.borderColor,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(weekAvg.toStringAsFixed(1),
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Insights
        Container(
          decoration: AppTheme.glowDecoration(AppTheme.accentPurple),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights, color: AppTheme.accentPurple, size: 18),
                  SizedBox(width: 8),
                  Text('Monthly Insights',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              _insightTile('📅', 'Stress peaks mid-week (Wed–Fri) patterns'),
              _insightTile('🌙', 'Evening relaxation is improving'),
              _insightTile('📉', 'Weekend recovery is healthy'),
              _insightTile('⚠️', '3 high-stress days this month exceeding 75'),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _insightTile(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String title, value, unit;
  final Color color;

  const _SummaryCard(this.title, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: AppTheme.glowDecoration(color),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text(unit,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

Widget _summaryRow(List<Widget> children) {
  return Row(children: children);
}

Widget _tileCard(String label, double value, String sub) {
  final color = AppTheme.stressColor(value);
  return Container(
    decoration: AppTheme.cardDecoration(),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13)),
              Text(sub,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Text(value.toStringAsFixed(0),
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final String? badge;
  final Color? badgeColor;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppTheme.accentGreen)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                        color: badgeColor ?? AppTheme.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final double maxY;
  final int? highlightIndex;

  const _BarChart({
    required this.data,
    required this.labels,
    required this.maxY,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i >= data.length) return const SizedBox();
                  return Text(
                    data[i].toStringAsFixed(0),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 9),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i >= labels.length || labels[i].isEmpty) {
                    return const SizedBox();
                  }
                  return Text(labels[i],
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10));
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppTheme.borderColor, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            data.length,
            (i) {
              final isHigh = i == highlightIndex;
              final color = isHigh
                  ? AppTheme.accentRed
                  : AppTheme.stressColor(data[i]);
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i],
                    color: color,
                    width: labels.length > 10 ? 6 : 14,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: AppTheme.borderColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final List<double> data;

  const _LineChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppTheme.borderColor, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (v, _) => Text(
                  'W${(v / 7).ceil()}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.accentCyan,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.accentCyan.withOpacity(0.2),
                    AppTheme.accentCyan.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StressCausesCard extends StatelessWidget {
  const _StressCausesCard();

  @override
  Widget build(BuildContext context) {
    final causes = [
      ('Work', 0.35, AppTheme.accentRed),
      ('Sleep', 0.25, AppTheme.accentPurple),
      ('Health', 0.20, AppTheme.accentYellow),
      ('Personal', 0.15, AppTheme.accentCyan),
      ('Other', 0.05, AppTheme.textSecondary),
    ];

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline,
                  color: AppTheme.accentPurple, size: 18),
              SizedBox(width: 8),
              Text('Stress Causes',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const Text('Based on pattern analysis',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 16),
          ...causes.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: c.$3, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c.$1,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13)),
                            Text('${(c.$2 * 100).toInt()}%',
                                style: TextStyle(
                                    color: c.$3, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: c.$2,
                            backgroundColor: AppTheme.borderColor,
                            valueColor: AlwaysStoppedAnimation(c.$3),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
