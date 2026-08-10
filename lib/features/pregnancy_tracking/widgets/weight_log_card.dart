import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

import '../models/weight_entry_model.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class WeightLogCard extends StatelessWidget {
  final WeightEntry entry;
  final double? previousWeight;
  final String unitSuffix;
  final VoidCallback onLongPress;
  final int? gestationalWeek;

  const WeightLogCard({
    super.key,
    required this.entry,
    this.previousWeight,
    required this.unitSuffix,
    required this.onLongPress,
    this.gestationalWeek,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weightDiff = previousWeight != null
        ? entry.weightValue - previousWeight!
        : null;

    const accentColor = AppTheme.trimester3Primary;

    final dateStr = DateFormat.yMMMd(l10n.localeName).format(entry.date);
    final timeStr = DateFormat.jm(l10n.localeName).format(entry.date);

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon badge with optional week pill
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.08),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          AppTheme.weightIcon,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                    ),
                    if (gestationalWeek != null)
                      Positioned(
                        bottom: -5,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.health_chart_week_short(gestationalWeek!),
                              style: GoogleFonts.nunito(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Info column
                Expanded(
                  child: Padding(
                    padding: gestationalWeek != null
                        ? const EdgeInsets.only(top: 4)
                        : EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary: weight value
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              entry.weightValue.toStringAsFixed(1),
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.appTextPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              unitSuffix,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Secondary: date + time
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: context.appTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$dateStr · $timeStr',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),

                        // Note (if present)
                        if (entry.note != null && entry.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notes_rounded,
                                  size: 13,
                                  color: context.appTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    entry.note!,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: context.appTextSecondary,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Diff chip
                if (weightDiff != null && weightDiff.abs() >= 0.05)
                  _buildDiffChip(weightDiff),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiffChip(double diff) {
    final isIncrease = diff > 0;
    final color = isIncrease
        ? AppTheme.trimester2Primary
        : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isIncrease
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            diff.abs().toStringAsFixed(1),
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
