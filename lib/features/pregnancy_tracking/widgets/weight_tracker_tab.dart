import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/premium_guard.dart';
import '../../../core/constants/route_constants.dart';
import '../services/weight_gain_calculator.dart';
import '../widgets/weight_log_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/pregnancy_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'action_link.dart';
import '../../../core/widgets/section_header.dart';
import 'pregnancy_weight_dashboard_card.dart';
import '../../../core/widgets/ambient_bottom_scrim.dart';

class WeightTrackerTab extends StatelessWidget {
  const WeightTrackerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authPrefs = context.watch<AuthProvider>().userProfile?.preferences;
    final unitSuffix = (authPrefs?.weightUnit ?? WeightUnit.kg).name
        .toLowerCase();

    return PremiumGuard(
      featureName: 'weight_tracker',
      message: l10n.health_weight,
      child: Consumer<PregnancyProvider>(
        builder: (context, provider, _) {
          final weights = provider.weights; // newest-first
          final pregnancy = provider.pregnancy;

          // ── Empty state ────────────────────────────────────────────────────
          if (weights.isEmpty) {
            return EmptyStateWidget(
              icon: AppTheme.weightIcon,
              title: l10n.health_weight,
              message: l10n.health_empty_weight,
              color: AppTheme.trimester3Primary,
              action: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.health_weight_add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.trimester3Primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, RouteConstants.addWeight),
              ),
            );
          }

          // ── Derived values ─────────────────────────────────────────────────
          final currentWeight = weights.first.weightValue;
          final initialWeight = pregnancy?.initialWeight;
          final totalGain = initialWeight != null
              ? currentWeight - initialWeight
              : null;

          String? status;
          List<double>? gainRange;
          double? bmi;
          if (totalGain != null && authPrefs != null && pregnancy != null) {
            final days = DateTime.now()
                .difference(pregnancy.lastPeriodDate)
                .inDays;
            gainRange = WeightGainCalculator.getRecommendedWeightGainRange(
              gestationalDays: days,
              initialWeight: initialWeight,
              height: pregnancy.height,
              preferences: authPrefs,
            );
            status = WeightGainCalculator.getStatusLabel(totalGain, gainRange);
            bmi = WeightGainCalculator.calculateBMI(
              initialWeight: initialWeight,
              height: pregnancy.height,
              preferences: authPrefs,
            );
          }

          double? weeklyRate;
          if (weights.length >= 2) {
            final diff = weights[0].weightValue - weights[1].weightValue;
            final days = weights[0].date.difference(weights[1].date).inDays;
            if (days > 0) weeklyRate = (diff / days) * 7;
          }

          // ── Build chart data ───────────────────────────────────────────────
          List<FlSpot> chartSpots = [];
          List<FlSpot> chartMinBand = [];
          List<FlSpot> chartMaxBand = [];
          double chartMinX = 0, chartMaxX = 0, chartMinY = 0, chartMaxY = 0;

          if (weights.length >= 2 && pregnancy != null) {
            final Map<int, List<double>> byDay = {};
            if (initialWeight != null) byDay[0] = [initialWeight];
            for (final w in weights) {
              final day = w.date.difference(pregnancy.lastPeriodDate).inDays;
              byDay.putIfAbsent(day, () => []).add(w.weightValue);
            }
            final sortedDays = byDay.keys.toList()..sort();
            for (final day in sortedDays) {
              final ws = byDay[day]!;
              chartSpots.add(
                FlSpot(day.toDouble(), ws.reduce((a, b) => a + b) / ws.length),
              );
            }

            // Compute chart X range before generating bands
            if (chartSpots.length >= 2) {
              chartMinX = (chartSpots.first.x / 7).floor() * 7.0;
              chartMaxX = (chartSpots.last.x / 7).ceil() * 7.0;
              if (chartMaxX - chartMinX < 14) chartMaxX = chartMinX + 14;
            }

            if (chartSpots.length >= 2 &&
                authPrefs != null &&
                initialWeight != null &&
                pregnancy.height != null) {
              for (int day = 0; day <= chartMaxX.toInt(); day += 7) {
                final gr = WeightGainCalculator.getRecommendedWeightGainRange(
                  gestationalDays: day,
                  initialWeight: initialWeight,
                  height: pregnancy.height,
                  preferences: authPrefs,
                );
                chartMinBand.add(FlSpot(day.toDouble(), initialWeight + gr[0]));
                chartMaxBand.add(FlSpot(day.toDouble(), initialWeight + gr[1]));
              }
            }

            if (chartSpots.length >= 2) {
              chartMinY = chartSpots.map((e) => e.y).reduce(min);
              chartMaxY = chartSpots.map((e) => e.y).reduce(max);
              if (chartMinBand.isNotEmpty) {
                chartMinY = min(
                  chartMinY,
                  chartMinBand.map((e) => e.y).reduce(min),
                );
                chartMaxY = max(
                  chartMaxY,
                  chartMaxBand.map((e) => e.y).reduce(max),
                );
              }
              final buf = max((chartMaxY - chartMinY) * 0.15, 1.5);
              chartMinY -= buf;
              chartMaxY += buf;
            }
          }

          // ── Layout ─────────────────────────────────────────────────────────
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PregnancyWeightDashboardCard(
                      currentWeight: currentWeight,
                      totalGain: totalGain,
                      status: status,
                      gainRange: gainRange,
                      weeklyRate: weeklyRate,
                      unitSuffix: unitSuffix,
                      bmi: bmi,
                      isCompact: false,
                      chartSpots: chartSpots.length >= 2 ? chartSpots : null,
                      chartMinBand: chartMinBand.isNotEmpty
                          ? chartMinBand
                          : null,
                      chartMaxBand: chartMaxBand.isNotEmpty
                          ? chartMaxBand
                          : null,
                      chartMinX: chartMinX,
                      chartMaxX: chartMaxX,
                      chartMinY: chartMinY,
                      chartMaxY: chartMaxY,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SectionHeader(
                          title: l10n.health_weight,
                          color: AppTheme.trimester3Primary,
                        ),
                        ActionLink(
                          icon: Icons.add_rounded,
                          label: l10n.health_weight_add,
                          color: AppTheme.trimester3Primary,
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteConstants.addWeight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 60.0),
                  itemCount: weights.length,
                  itemBuilder: (context, index) {
                    final entry = weights[index];
                    final prevWeight = (index + 1 < weights.length)
                        ? weights[index + 1].weightValue
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Dismissible(
                          key: ValueKey(entry.id),
                          direction: DismissDirection.endToStart,
                          background: _buildSwipeBackground(context, l10n),
                          confirmDismiss: (_) async {
                            bool confirmed = false;
                            await PlatformUI.showDeleteDialog(
                              context,
                              itemType: l10n.common_item_weight_log,
                              onDelete: () => confirmed = true,
                            );
                            return confirmed;
                          },
                          onDismissed: (_) =>
                              _deleteEntry(context, entry.id, l10n),
                          child: WeightLogCard(
                            entry: entry,
                            previousWeight: prevWeight,
                            unitSuffix: unitSuffix,
                            onLongPress: () =>
                                _confirmDelete(context, entry.id),
                            gestationalWeek: pregnancy != null
                                ? (entry.date
                                          .difference(pregnancy.lastPeriodDate)
                                          .inDays ~/
                                      7)
                                : null,
                          ),
                        ),
                      ),
                    );
                    },
                  ),
                  const AmbientBottomScrim(),
                ],
              ),
            ),
          ],
        );
        },
      ),
    );
  }

  // ─── Swipe-to-delete ────────────────────────────────────────────────────────

  Widget _buildSwipeBackground(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                ? CupertinoIcons.delete_solid
                : Icons.delete_forever_rounded,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.common_delete,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) async {
    try {
      await context.read<PregnancyProvider>().deleteWeight(id);
      if (context.mounted) {
        PlatformUI.showMessage(
          context,
          message: l10n.health_weight_delete_success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        PlatformUI.showMessage(
          context,
          message: l10n.common_error_deleting(e.toString()),
          isError: true,
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    PlatformUI.showDeleteDialog(
      context,
      itemType: l10n.common_item_weight_log,
      onDelete: () async {
        try {
          await context.read<PregnancyProvider>().deleteWeight(id);
          if (context.mounted) {
            PlatformUI.showMessage(
              context,
              message: l10n.health_weight_delete_success,
            );
          }
        } catch (e) {
          if (context.mounted) {
            PlatformUI.showMessage(
              context,
              message: l10n.common_error_deleting(e.toString()),
              isError: true,
            );
          }
        }
      },
    );
  }
}
