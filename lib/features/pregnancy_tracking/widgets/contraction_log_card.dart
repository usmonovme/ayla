import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/platform_wrapper.dart';
import '../models/contraction_model.dart';
import '../../../l10n/app_localizations.dart';
import 'package:ayla_tracker/core/theme/theme_extension.dart';

class ContractionLogCard extends StatelessWidget {
  final ContractionEntry contraction;
  final ContractionEntry? prevContraction;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const ContractionLogCard({
    super.key,
    required this.contraction,
    this.prevContraction,
    this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMMMd(
      l10n.localeName,
    ).format(contraction.startTime);
    final timeStr = DateFormat.jm(
      l10n.localeName,
    ).format(contraction.startTime);
    final fullDateTimeStr = '$dateStr · $timeStr';
    final durationMinutes = contraction.duration.inMinutes;
    final durationSeconds = contraction.duration.inSeconds % 60;
    final durationStr = contraction.endTime != null
        ? (durationMinutes > 0
              ? (durationSeconds > 0
                    ? l10n.contraction_timer_duration_text(
                        durationMinutes,
                        durationSeconds,
                      )
                    : l10n
                          .contraction_timer_duration_text(durationMinutes, 0)
                          .replaceAll(RegExp(r'\s+0\S*$'), ''))
              : l10n.contraction_timer_seconds_text(durationSeconds))
        : l10n.common_ongoing;

    Color intensityColor = context.appTextSecondary;
    String intensityLabel = '';

    if (contraction.intensity != null) {
      switch (contraction.intensity!) {
        case ContractionIntensity.mild:
          intensityColor = Colors.green;
          intensityLabel = l10n.contraction_timer_mild;
          break;
        case ContractionIntensity.moderate:
          intensityColor = Colors.orange;
          intensityLabel = l10n.contraction_timer_moderate;
          break;
        case ContractionIntensity.strong:
          intensityColor = Colors.red;
          intensityLabel = l10n.contraction_timer_strong;
          break;
      }
    }

    Widget card = GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Duration Circular Badge
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: intensityColor.withValues(alpha: 0.08),
              border: Border.all(
                color: intensityColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.waves_rounded,
                color: intensityColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary: intensity label (or generic fallback)
                Text(
                  intensityLabel.isNotEmpty
                      ? intensityLabel
                      : l10n.contraction_timer_title,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                    height: 1.1,
                  ),
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
                      fullDateTimeStr,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Secondary: duration + interval
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 13,
                      color: context.appTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      durationStr,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appTextSecondary,
                      ),
                    ),
                    if (prevContraction != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: context.appTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatInterval(
                          contraction.startTime,
                          prevContraction!.startTime,
                          l10n,
                        ),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onLongPress != null || onDelete != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(24),
          child: card,
        ),
      );
    }

    if (onDelete != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Dismissible(
          key: ValueKey(contraction.id),
          direction: DismissDirection.endToStart,
          background: Container(
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.12),
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
          ),
          confirmDismiss: (_) async {
            bool confirmed = false;
            await PlatformUI.showDeleteDialog(
              context,
              itemType: l10n.common_item_contraction,
              onDelete: () => confirmed = true,
            );
            return confirmed;
          },
          onDismissed: (_) => onDelete?.call(),
          child: card,
        ),
      );
    }

    return card;
  }

  String _formatInterval(
    DateTime current,
    DateTime prev,
    AppLocalizations l10n,
  ) {
    final diff = current.difference(prev).abs();

    if (diff > AppConstants.contractionSessionThreshold) {
      return '--';
    }

    final m = diff.inMinutes;
    final s = diff.inSeconds % 60;
    if (m > 0 && s > 0) return l10n.contraction_timer_duration_text(m, s);
    if (m > 0) {
      return l10n
          .contraction_timer_duration_text(m, 0)
          .replaceAll(RegExp(r'\s+0\S*$'), '');
    }
    return l10n.contraction_timer_seconds_text(s);
  }
}
