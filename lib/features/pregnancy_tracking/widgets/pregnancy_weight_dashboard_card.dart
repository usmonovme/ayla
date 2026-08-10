import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class PregnancyWeightDashboardCard extends StatefulWidget {
  final double currentWeight;
  final double? totalGain;
  final String? status;
  final List<double>? gainRange;
  final double? weeklyRate;
  final String unitSuffix;
  final List<FlSpot>? chartSpots;
  final List<FlSpot>? chartMinBand;
  final List<FlSpot>? chartMaxBand;
  final double chartMinX;
  final double chartMaxX;
  final double chartMinY;
  final double chartMaxY;
  final bool isCompact;
  final double? bmi;

  const PregnancyWeightDashboardCard({
    super.key,
    required this.currentWeight,
    required this.totalGain,
    required this.status,
    required this.gainRange,
    required this.weeklyRate,
    required this.unitSuffix,
    this.chartSpots,
    this.chartMinBand,
    this.chartMaxBand,
    this.chartMinX = 0,
    this.chartMaxX = 0,
    this.chartMinY = 0,
    this.chartMaxY = 0,
    this.isCompact = false,
    this.bmi,
  });

  @override
  State<PregnancyWeightDashboardCard> createState() =>
      _PregnancyWeightDashboardCardState();
}

class _PregnancyWeightDashboardCardState
    extends State<PregnancyWeightDashboardCard> {
  int? _touchedSpotIndex;
  bool _insightExpanded = false;

  // ── Status helpers ───────────────────────────────────────────────────────────

  Color get _statusColor {
    switch (widget.status) {
      case 'under':
        return Colors.orange;
      case 'over':
        return AppTheme.errorColor;
      default:
        return AppTheme.successColor;
    }
  }

  IconData get _statusIcon {
    switch (widget.status) {
      case 'under':
        return Icons.south_rounded;
      case 'over':
        return Icons.north_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (widget.status) {
      case 'under':
        return l10n.health_target_below;
      case 'over':
        return l10n.health_target_above;
      default:
        return l10n.health_target_on_track;
    }
  }

  String _insightBody(AppLocalizations l10n) {
    switch (widget.status) {
      case 'under':
        return l10n.health_weight_insight_below_body;
      case 'over':
        return l10n.health_weight_insight_above_body;
      default:
        return l10n.health_weight_insight_on_track_body;
    }
  }

  /// Returns a "nice" interval that places approximately 5 evenly-spaced ticks
  /// across [minY]→[maxY] by rounding (range / 5) up to the nearest
  /// 1 / 2 / 5 / 10 … value in the appropriate magnitude.
  double _niceYInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 0) return 1.0;
    final rawStep = range / 5;
    final mag = pow(10, (log(rawStep) / log(10)).floor()).toDouble();
    final norm = rawStep / mag;
    if (norm <= 1.5) return 1.0 * mag;
    if (norm <= 3.0) return 2.0 * mag;
    if (norm <= 7.0) return 5.0 * mag;
    return 10.0 * mag;
  }

  double? _interpolateY(double x, List<FlSpot>? band) {
    if (band == null || band.isEmpty) return null;
    if (x <= band.first.x) return band.first.y;
    if (x >= band.last.x) return band.last.y;

    for (int i = 0; i < band.length - 1; i++) {
      if (x >= band[i].x && x <= band[i + 1].x) {
        final x0 = band[i].x;
        final y0 = band[i].y;
        final x1 = band[i + 1].x;
        final y1 = band[i + 1].y;
        if (x1 == x0) return y0;
        return y0 + (x - x0) * (y1 - y0) / (x1 - x0);
      }
    }
    return null;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasChart =
        widget.chartSpots != null && widget.chartSpots!.length >= 2;
    final hasGain = widget.totalGain != null && widget.gainRange != null;
    final sc = _statusColor;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(context, l10n, sc),

          // Tap-to-reveal insight banner
          if (widget.status != null && !widget.isCompact)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _insightExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        children: [
                          _buildInsightBanner(context, l10n, sc),
                          const SizedBox(height: 4),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.isCompact ? 16 : 20,
              widget.isCompact ? 12 : 14,
              widget.isCompact ? 16 : 20,
              widget.isCompact ? 14 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                _buildStatsRow(context, l10n),

                // Gain progress bar
                if (hasGain) ...[
                  SizedBox(height: widget.isCompact ? 12 : 16),
                  _buildGainProgressBar(context, l10n),
                ],

                // Chart + legend
                if (hasChart) ...[
                  SizedBox(height: widget.isCompact ? 12 : 16),
                  Divider(
                    height: 1,
                    color: context.appDividerColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 8),
                  _buildChart(context, l10n),
                  if (!widget.isCompact) ...[
                    const SizedBox(height: 8),
                    _buildChartLegend(context, l10n),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Header ──────────────────────────────────────────────────────────────

  Widget _buildHeroHeader(
    BuildContext context,
    AppLocalizations l10n,
    Color sc,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        widget.isCompact ? 16 : 20,
        widget.isCompact ? 12 : 16,
        widget.isCompact ? 16 : 20,
        widget.isCompact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sc.withValues(alpha: 0.10),
            sc.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Weight icon badge (non-compact only)
          if (!widget.isCompact) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.trimester3Primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                AppTheme.weightIcon,
                size: 22,
                color: AppTheme.trimester3Primary,
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Large weight display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.health_weight_current,
                  style: GoogleFonts.nunito(
                    fontSize: widget.isCompact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.currentWeight.toStringAsFixed(1),
                      style: GoogleFonts.nunito(
                        fontSize: widget.isCompact ? 30 : 42,
                        fontWeight: FontWeight.w900,
                        color: context.appTextPrimary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        widget.unitSuffix,
                        style: GoogleFonts.nunito(
                          fontSize: widget.isCompact ? 14 : 17,
                          fontWeight: FontWeight.w600,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status badge + optional add button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.status != null)
                GestureDetector(
                  onTap: widget.isCompact
                      ? null
                      : () => setState(
                          () => _insightExpanded = !_insightExpanded,
                        ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isCompact ? 8 : 10,
                      vertical: widget.isCompact ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: _insightExpanded
                          ? sc.withValues(alpha: 0.18)
                          : sc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sc.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          _statusIcon,
                          size: widget.isCompact ? 11 : 12,
                          color: sc,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(l10n),
                          style: GoogleFonts.nunito(
                            fontSize: widget.isCompact ? 10 : 11,
                            fontWeight: FontWeight.w800,
                            color: sc,
                          ),
                        ),
                        if (!widget.isCompact) ...[
                          const SizedBox(width: 3),
                          AnimatedRotation(
                            turns: _insightExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 13,
                              color: sc,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Insight Banner ───────────────────────────────────────────────────────────

  Widget _buildInsightBanner(
    BuildContext context,
    AppLocalizations l10n,
    Color sc,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [sc.withValues(alpha: 0.13), sc.withValues(alpha: 0.04)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon, size: 18, color: sc),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  _statusLabel(l10n),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: sc,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _insightBody(l10n),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.appTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, AppLocalizations l10n) {
    final totalGain = widget.totalGain;
    final weeklyRate = widget.weeklyRate;

    final gainStr = totalGain != null
        ? '${totalGain >= 0 ? '+' : ''}${totalGain.toStringAsFixed(1)} ${widget.unitSuffix}'
        : '-- ${widget.unitSuffix}';

    final rateStr = weeklyRate != null
        ? '${weeklyRate >= 0 ? '+' : ''}${weeklyRate.toStringAsFixed(1)} ${widget.unitSuffix}'
        : '--';

    final hasBmi = widget.bmi != null;

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _buildStatCell(
              context,
              icon: Icons.trending_up_rounded,
              label: l10n.health_weight_gain,
              value: gainStr,
              color: AppTheme.trimester2Primary,
            ),
          ),
          _vDivider(context),
          Expanded(
            child: _buildStatCell(
              context,
              icon: Icons.show_chart_rounded,
              label: l10n.health_weekly_progress,
              value: rateStr,
              color: AppTheme.primaryColor,
            ),
          ),
          if (hasBmi) ...[
            _vDivider(context),
            Expanded(
              child: _buildStatCell(
                context,
                icon: Icons.monitor_weight_outlined,
                label: l10n.health_weight_bmi,
                value: widget.bmi!.toStringAsFixed(1),
                color: AppTheme.trimester3Primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vDivider(BuildContext context) => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(vertical: 4),
    color: context.appDividerColor.withValues(alpha: 0.3),
  );

  Widget _buildStatCell(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isCompact) ...[
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: widget.isCompact ? 14 : 15,
            fontWeight: FontWeight.w900,
            color: context.appTextPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: context.appTextSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Gain Progress Bar ────────────────────────────────────────────────────────

  Widget _buildGainProgressBar(BuildContext context, AppLocalizations l10n) {
    final totalGain = widget.totalGain!;
    final minGain = widget.gainRange![0];
    final maxGain = widget.gainRange![1];
    final displayMax = max(maxGain * 1.5, totalGain.abs() + 1.0);
    final clampedGain = totalGain.clamp(0.0, displayMax);
    final progress = clampedGain / displayMax;
    final minNorm = (minGain / displayMax).clamp(0.0, 1.0);
    final maxNorm = (maxGain / displayMax).clamp(0.0, 1.0);

    final dotColor = totalGain < minGain
        ? Colors.orange
        : totalGain > maxGain
        ? AppTheme.errorColor
        : AppTheme.successColor;

    final barH = widget.isCompact ? 6.0 : 8.0;
    final dotSize = widget.isCompact ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.health_weight_target_range,
              style: GoogleFonts.nunito(
                fontSize: widget.isCompact ? 11 : 12,
                color: context.appTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${minGain.toStringAsFixed(1)} – ${maxGain.toStringAsFixed(1)} ${widget.unitSuffix}',
              style: GoogleFonts.nunito(
                fontSize: widget.isCompact ? 11 : 12,
                color: AppTheme.successColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Background track
                Container(
                  height: barH,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: context.appBorderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Progress fill
                Container(
                  height: barH,
                  width: (progress * barWidth).clamp(0.0, barWidth),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        dotColor.withValues(alpha: 0.5),
                        dotColor.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Green target zone
                Positioned(
                  left: minNorm * barWidth,
                  child: Container(
                    height: barH,
                    width: ((maxNorm - minNorm) * barWidth).clamp(
                      0.0,
                      barWidth,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Dot indicator
                Positioned(
                  left: (progress * barWidth - dotSize / 2).clamp(
                    0.0,
                    barWidth - dotSize,
                  ),
                  top: -(dotSize - barH) / 2,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: widget.isCompact ? 2.0 : 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Chart ────────────────────────────────────────────────────────────────────

  Widget _buildChart(BuildContext context, AppLocalizations l10n) {
    final chartH = widget.isCompact ? 110.0 : 185.0;
    final step = _niceYInterval(widget.chartMinY, widget.chartMaxY);
    final xRange = widget.chartMaxX - widget.chartMinX;

    return SizedBox(
      height: chartH,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          0,
          widget.isCompact ? 6 : 10,
          widget.isCompact ? 4 : 4,
          widget.isCompact ? 4 : 4,
        ),
        child: LineChart(
          LineChartData(
            minX: widget.chartMinX,
            maxX: widget.chartMaxX,
            minY: widget.chartMinY,
            maxY: widget.chartMaxY,
            clipData: const FlClipData(
              top: false,
              bottom: false,
              left: false,
              right: false,
            ),
            lineTouchData: LineTouchData(
              enabled: !widget.isCompact,
              touchCallback: widget.isCompact
                  ? null
                  : (FlTouchEvent event, LineTouchResponse? response) {
                      if (!mounted) return;
                      setState(() {
                        if (event is FlTapUpEvent ||
                            event is FlPanEndEvent ||
                            event is FlLongPressEnd) {
                          _touchedSpotIndex = null;
                        } else if (response?.lineBarSpots != null) {
                          final weightSpots = response!.lineBarSpots!.where(
                            (s) => s.barIndex == 0,
                          );
                          _touchedSpotIndex = weightSpots.isEmpty
                              ? null
                              : weightSpots.first.spotIndex;
                        }
                      });
                    },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) {
                  final x = spot.x;
                  if (x < 91.0) {
                    return AppTheme.trimester1Primary.withValues(alpha: 0.92);
                  } else if (x < 196.0) {
                    return AppTheme.trimester2Primary.withValues(alpha: 0.92);
                  } else {
                    return AppTheme.trimester3Primary.withValues(alpha: 0.92);
                  }
                },
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    if (spot.barIndex != 0) return null;

                    final week = (spot.x / 7).round();

                    String? rangeLine;
                    if (widget.chartMinBand != null &&
                        widget.chartMaxBand != null) {
                      final minY = _interpolateY(spot.x, widget.chartMinBand!);
                      final maxY = _interpolateY(spot.x, widget.chartMaxBand!);
                      if (minY != null && maxY != null) {
                        rangeLine =
                            '${minY.toStringAsFixed(1)}–${maxY.toStringAsFixed(1)} ${widget.unitSuffix}';
                      }
                    }

                    return LineTooltipItem(
                      '${l10n.health_chart_week_short(week)}  '
                      '${spot.y.toStringAsFixed(1)} ${widget.unitSuffix}',
                      GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      children: [
                        if (rangeLine != null)
                          TextSpan(
                            text: '\n$rangeLine',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.72),
                              height: 1.5,
                            ),
                          ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: step,
              getDrawingHorizontalLine: (_) => FlLine(
                color: context.appDividerColor.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),

            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: context.appBorderColor.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: step,
                  reservedSize: widget.isCompact ? 26 : 30,
                  getTitlesWidget: (value, meta) {
                    // Skip ticks that are too close to minY or maxY to avoid
                    // crowding at the extremes of the axis.
                    if ((value - widget.chartMinY).abs() < step * 0.6 ||
                        (value - widget.chartMaxY).abs() < step * 0.6) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      step < 1.0
                          ? value.toStringAsFixed(1)
                          : value.toInt().toString(),
                      style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: !widget.isCompact,
                  interval: 7.0, // Evaluate every week
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    final week = (value / 7).round();

                    // Show odd weeks (1, 3, 5...). For longer charts, space them
                    // out to every 4th week starting on an odd week (1, 5, 9...).
                    final step = xRange <= 168 ? 2 : 4;
                    if (week % step != 1) return const SizedBox.shrink();

                    // Hide negative/0 ticks or ticks too close to the right edge.
                    if (week <= 0 || (widget.chartMaxX - value) < 3.5) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        l10n.health_chart_week_short(week),
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              // Main weight line
              LineChartBarData(
                spots: widget.chartSpots!,
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppTheme.primaryColor,
                barWidth: widget.isCompact ? 2.0 : 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final isLatest = index == widget.chartSpots!.length - 1;
                    final isTouched = index == _touchedSpotIndex;
                    return FlDotCirclePainter(
                      radius: isTouched
                          ? 6.0
                          : isLatest
                          ? (widget.isCompact ? 3.5 : 4.5)
                          : (widget.isCompact ? 2.0 : 2.5),
                      color: Colors.white,
                      strokeWidth: isTouched
                          ? 3.0
                          : isLatest
                          ? 2.5
                          : 2.0,
                      strokeColor: AppTheme.primaryColor,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                      AppTheme.primaryColor.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Upper recommended band
              if (widget.chartMaxBand != null &&
                  widget.chartMaxBand!.isNotEmpty)
                LineChartBarData(
                  spots: widget.chartMaxBand!,
                  isCurved: true,
                  color: AppTheme.successColor.withValues(alpha: 0.35),
                  barWidth: 1.5,
                  dotData: const FlDotData(show: false),
                  dashArray: [5, 5],
                ),
              // Lower recommended band
              if (widget.chartMinBand != null &&
                  widget.chartMinBand!.isNotEmpty)
                LineChartBarData(
                  spots: widget.chartMinBand!,
                  isCurved: true,
                  color: AppTheme.successColor.withValues(alpha: 0.35),
                  barWidth: 1.5,
                  dotData: const FlDotData(show: false),
                  dashArray: [5, 5],
                ),
            ],
            betweenBarsData: [
              if (widget.chartMaxBand != null &&
                  widget.chartMinBand != null &&
                  widget.chartMaxBand!.isNotEmpty &&
                  widget.chartMinBand!.isNotEmpty)
                BetweenBarsData(
                  fromIndex: 1,
                  toIndex: 2,
                  color: AppTheme.successColor.withValues(alpha: 0.07),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chart Legend ─────────────────────────────────────────────────────────────

  Widget _buildChartLegend(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        _legendItem(
          context,
          color: AppTheme.primaryColor,
          isDashed: false,
          label: l10n.health_weight_actual,
        ),
        const SizedBox(width: 16),
        if (widget.chartMaxBand != null)
          _legendItem(
            context,
            color: AppTheme.successColor,
            isDashed: true,
            label: l10n.health_weight_zone_label,
          ),
      ],
    );
  }

  Widget _legendItem(
    BuildContext context, {
    required Color color,
    required bool isDashed,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 4, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 4, height: 2, color: color),
            ],
          )
        else
          Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: context.appTextSecondary,
          ),
        ),
      ],
    );
  }
}
